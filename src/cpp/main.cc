#include <iostream>
#include <grpcpp/grpcpp.h>
#include <grpc/support/log.h>
#include "knn.grpc.pb.h"

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
    Status Search(ServerContext* context, const KnnRequest* request, KnnResponse* response) override {
        auto product = response->add_products();
        product->set_product_id(5);
        product->set_score(0);
        return Status::OK;
    }
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
