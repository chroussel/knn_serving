add_custom_target(knn)

get_target_property(PROTO_INCLUDE_DIRS protogen INCLUDE_DIRS)
get_target_property(PROTO_SOURCE_FILES protogen SOURCE_FILES)
set_source_files_properties(${PROTO_SOURCE_FILES} PROPERTIES GENERATED TRUE)

message(PROTO_SOURCE_FILES: "${PROTO_SOURCE_FILES}")
message(PROTO_INCLUDE_DIRS: "${PROTO_INCLUDE_DIRS}")
set(KNN_SRCS main.cc knnservice.cc)
set(KNN_SERVICE_STATIC_LINK_LIBS
        protobuf::libprotobuf
        gRPC::grpc++
        gRPC::grpc
        gRPC::gpr
        c-ares::cares
        ZLIB::ZLIB
        gRPC::address_sorting
        boost::boost_program_options
        boost::boost_filesystem
        boost::boost_system)

get_target_property(BOOST_INCLUDE_DIR boost::boost_system INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(GRPC_INCLUDE_DIR gRPC::grpc INTERFACE_INCLUDE_DIRECTORIES)


add_executable(knn_service ${KNN_SRCS} ${PROTO_SOURCE_FILES})
add_dependencies(knn_service knn_dependencies)
add_dependencies(knn_service protogen)
target_include_directories(knn_service PUBLIC ${PROTO_INCLUDE_DIRS} ${BOOST_INCLUDE_DIR} ${GRPC_INCLUDE_DIR})
target_link_libraries(knn_service ${KNN_SERVICE_STATIC_LINK_LIBS})
