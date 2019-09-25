#include <iostream>
#include <grpcpp/grpcpp.h>
#include <grpc/support/log.h>

#include "knn.grpc.pb.h"
#include "knnservice.h"
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include <boost/algorithm/string.hpp>

namespace po = boost::program_options;
using grpc::Server;
using grpc::ServerAsyncResponseWriter;
using grpc::ServerBuilder;
using grpc::ServerCompletionQueue;
using grpc::ServerContext;
using grpc::Status;
using grpc::experimental::ServerInterceptorFactoryInterface;
using grpc::experimental::Interceptor;
using knn::api::Knn;
using knn::api::KnnRequest;
using knn::api::KnnResponse;
using namespace boost::filesystem;

class KnnServiceLoader final {
public:
    static void load_embeddings(KnnService *knnService, std::string embeddings_path) {
        auto path = absolute(embeddings_path);
        recursive_directory_iterator itr(path);
        for (; itr != recursive_directory_iterator(); ++itr) {
            if (itr->path().extension() == ".bin") {
                std::cout << "Parsing " << itr->path().string() << std::endl;
                ifstream embedding_file(itr->path(), std::ios::binary);
                while (!embedding_file.eof()) {
                    int64_t product_id;
                    int32_t partner_id;
                    int32_t embedding_length;
                    embedding_file.read(reinterpret_cast<char *>(&product_id), sizeof(int64_t));
                    embedding_file.read(reinterpret_cast<char *>(&partner_id), sizeof(int32_t));
                    embedding_file.read(reinterpret_cast<char *>(&embedding_length), sizeof(int32_t));
                    std::vector<float> embedding;
                    embedding.reserve(embedding_length);
                    embedding_file.read(reinterpret_cast<char *>(embedding.data()), embedding_length * sizeof(float));
                    knnService->addExtraItem(partner_id, product_id, embedding);
                }
            }
        }
    }

    static void load_indices(KnnService *knnService, std::string indices_path) {
        auto path = absolute(indices_path);
        recursive_directory_iterator itr(path);
        for (; itr != recursive_directory_iterator(); ++itr) {
            if (itr->path().extension() == ".bin") {
                std::cout << "Parsing " << itr->path().string() << std::endl;
                std::vector<std::string> results;
                boost::split(results, itr->path().filename().string(), [](char c) { return c == '-'; });

                int32_t index_id = std::stoi(results[1]);
                auto *index = knnService->loadIndex(index_id, itr->path().string());
                knnService->addIndices({index_id}, {index});
            }
        }
    }
};

class KnnByCountry final {
public:
    KnnByCountry(const std::string &indexPath, const std::string &embeddingPath, Distance distance, int32_t dimension, int32_t efSearch) : distance_(distance),
                                                                                                                                           dimension_(
                                                                                                                                                   dimension),
                                                                                                                                           efSearch_(efSearch) {

    }

    KnnService *getService(const std::string &country) {
        auto res = countryMap_.find(country);
        if (res == countryMap_.end()) {
            return nullptr;
        } else {
            return res->second;
        }
    }

    void loadServiceForCountry(const std::string &country) {
        if (countryMap_.find(country) == countryMap_.end()) {
            auto *knnService = new KnnService(distance_, dimension_, efSearch_);
            KnnServiceLoader::load_embeddings(knnService, getEmbeddingCountryPath(country));
            KnnServiceLoader::load_indices(knnService, getIndexCountryPath(country));
            countryMap_.emplace(country, knnService);
        }
    }

private:
    std::string getIndexCountryPath(const std::string &country) {
        return indexPath_.append("country=" + country);
    }

    std::string getEmbeddingCountryPath(const std::string &country) {
        return embeddingPath_.append("country=" + country);
    }

    Distance distance_;
    int32_t dimension_;
    int32_t efSearch_;
    std::string indexPath_;
    std::string embeddingPath_;
    std::unordered_map<std::string, KnnService *> countryMap_;
};

class KnnController final : public Knn::Service {

public:
    KnnController(std::string indexPath, std::string embeddingPath) : knnByCountry_(indexPath, embeddingPath, Euclidean, 101, 50) {
    }

    void init() {
        std::vector<std::string> countryList = {"DE", "FR", "GB", "IT", "PL", "RU", "TR"};
        for (auto &c: countryList) {
            knnByCountry_.loadServiceForCountry(c);
        }
    }

    Status Search(ServerContext *context, const KnnRequest *request, KnnResponse *response) override {
        auto *service = knnByCountry_.getService(request->country());
        if (service == nullptr) {
            return Status::OK;
        }
        auto requestSize = request->user_events().size();
        std::vector<int32_t> index_ids;
        index_ids.reserve(requestSize);
        std::vector<size_t> queryLabels;
        queryLabels.reserve(requestSize);
        std::vector<int64_t> timestamps;
        timestamps.reserve(requestSize);
        std::vector<int32_t> eventTypes;
        eventTypes.reserve(requestSize);

        for (auto &event : request->user_events()) {
            index_ids.push_back(event.partner_id());
            queryLabels.push_back(event.product_id());
            timestamps.push_back(event.timestamp());
            eventTypes.push_back(event.event_type());
        }

        UserData userData(index_ids, queryLabels, timestamps, eventTypes);
        ModelData modelData(Model::TimeDecay, 2, 2);
        auto result = service->get_closest_items(userData, modelData, request->index_id(), request->result_count());

        for (auto &r : result.items) {
            auto product = response->add_products();
            product->set_score(r.first);
            product->set_product_id(r.second);
        }
        return Status::OK;
    }

private:
    KnnByCountry knnByCountry_;
};

class KnnServer final {
public:
    KnnServer(std::string embeddings_path, std::string indices_path): service_(indices_path, embeddings_path) {
    }

    void init() {
        service_.init();
    }

    void run(int server_port) {
        std::string server_address("0.0.0.0:" + std::to_string(server_port));

        ServerBuilder builder;
        builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
        builder.RegisterService(&service_);
        std::unique_ptr<Server> server(builder.BuildAndStart());
        std::cout << "Server listening on " << server_address << std::endl;
        server->Wait();
    }

private:
    KnnController service_;
};

int main(int argc, char **argv) {
    int server_port;
    po::options_description server_config_desc("Allowed options");
    server_config_desc.add_options()("help", "")("p,port", po::value<int>(&server_port)->default_value(8888), "port to listen to")("embeddings_path",
                                                                                                                                   po::value<std::string>(),
                                                                                                                                   "path to embeddings to load")(
            "indices_path", po::value<std::string>(), "path to indices to load");

    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, server_config_desc), vm);
    po::notify(vm);

    if (vm.count("help")) {
        std::cout << server_config_desc << std::endl;
        return 1;
    }

    if (vm.count("embeddings_path") == 0) {
        std::cout << "embeddings_path is missing" << std::endl;
        return 1;
    }

    if (vm.count("indices_path") == 0) {
        std::cout << "indices_path is missing" << std::endl;
        return 1;
    }

    KnnServer server {vm["embeddings_path"].as<std::string>(), vm["indices_path"].as<std::string>()};
    server.init();
    server.run(server_port);
    return 0;
}
