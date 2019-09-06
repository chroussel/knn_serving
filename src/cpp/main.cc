#include <iostream>
#include <grpcpp/grpcpp.h>
#include <grpc/support/log.h>
#include "knn.grpc.pb.h"
#include "knnservice.h"

using grpc::Server;
using grpc::ServerAsyncResponseWriter;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::ServerCompletionQueue;
using grpc::Status;
using knn::api::KnnRequest;
using knn::api::KnnResponse;
using knn::api::Knn;

class KnnController final : public Knn::Service {

public:
    KnnController() : knnService_(Euclidean, 100, 50) {

    }

    Status Search(ServerContext* context, const KnnRequest* request, KnnResponse* response) override {
        auto requestSize = request->user_events().size();
        std::vector<int32_t> index_ids;
        index_ids.reserve(requestSize);
        std::vector<size_t> queryLabels;
        queryLabels.reserve(requestSize);
        std::vector<int64_t > timestamps;
        timestamps.reserve(requestSize);
        std::vector<int32_t > eventTypes;
        eventTypes.reserve(requestSize);

        for (auto &event: request->user_events()) {
            index_ids.push_back(event.partner_id());
            queryLabels.push_back(event.product_id());
            timestamps.push_back(event.timestamp());
            eventTypes.push_back(event.event_type());
        }

        UserData userData(index_ids, queryLabels, timestamps, eventTypes);
        ModelData modelData(Model::TimeDecay, 2, 2);
        auto result = knnService_.get_closest_items(userData, modelData, request->index_id(), request->result_count());

        for(auto &r: result.items) {
            auto product = response->add_products();
            product->set_score(r.first);
            product->set_product_id(r.second);
        }
        return Status::OK;
    }

private:
    KnnService knnService_;
};

class KnnServer final {
public:
    KnnServer() {

    }

    void loadDataFromHDFS() {
    }

    void Run() {
        std::string server_address("0.0.0.0:8888");

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

int main(int argc, char** argv) {
    KnnServer server;
    server.loadDataFromHDFS();
    server.Run();
    return 0;
}
