add_custom_target(knn)

get_target_property(PROTO_INCLUDE_DIRS protogen INCLUDE_DIRS)
get_target_property(PROTO_SOURCE_FILES protogen SOURCE_FILES)
set_source_files_properties(${PROTO_SOURCE_FILES} PROPERTIES GENERATED TRUE)

message(PROTO_SOURCE_FILES: "${PROTO_SOURCE_FILES}")
message(PROTO_INCLUDE_DIRS: "${PROTO_INCLUDE_DIRS}")
set(KNN_SRCS main.cc)
set(KNN_SERVICE_STATIC_LINK_LIBS
        protobuf::libprotobuf
        gRPC::grpc++
        gRPC::grpc
        gRPC::gpr
        c-ares::cares
        ZLIB::ZLIB
        gRPC::address_sorting)

add_executable(knn_service ${KNN_SRCS} ${PROTO_SOURCE_FILES})
add_dependencies(knn_service knn_dependencies)
add_dependencies(knn_service protogen)
target_include_directories(knn_service PUBLIC ${PROTO_INCLUDE_DIRS})
target_link_libraries(knn_service ${KNN_SERVICE_STATIC_LINK_LIBS})
