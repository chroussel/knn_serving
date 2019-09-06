add_custom_target(protogen)

set(PROTOGEN_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/generated_protos)
macro(generateProto PROTO_FILE)
    get_filename_component(file_proto ${PROTO_FILE} ABSOLUTE)
    get_filename_component(file_proto_path "${file_proto}" PATH)
    get_filename_component(file_proto_name "${PROTO_FILE}" NAME_WE)

    set(file_proto_srcs "${PROTOGEN_DIRECTORY}/${file_proto_name}.pb.cc")
    set(file_proto_hdrs "${PROTOGEN_DIRECTORY}/${file_proto_name}.pb.h")
    set(file_grpc_srcs "${PROTOGEN_DIRECTORY}/${file_proto_name}.grpc.pb.cc")
    set(file_grpc_hdrs "${PROTOGEN_DIRECTORY}/${file_proto_name}.grpc.pb.h")
    add_custom_command(
            OUTPUT "${file_proto_srcs}" "${file_proto_hdrs}" "${file_grpc_srcs}" "${file_grpc_hdrs}"
            COMMAND ${PROTOBUF_PROTOC_EXECUTABLE}
            ARGS --grpc_out "${PROTOGEN_DIRECTORY}"
            --cpp_out "${PROTOGEN_DIRECTORY}"
            -I "${file_proto_path}"
            --plugin=protoc-gen-grpc="${GRPC_CPP_PLUGIN_EXECUTABLE}"
            "${file_proto}"
            DEPENDS "${file_proto}")
    add_custom_target(gen_${file_proto_name} DEPENDS "${file_proto_srcs}" "${file_proto_hdrs}" "${file_grpc_srcs}" "${file_grpc_hdrs}")
    add_dependencies(gen_${file_proto_name} toolchain)
    add_dependencies(protogen gen_${file_proto_name})
    list(APPEND PROTO_CC_FILES ${file_proto_srcs} ${file_grpc_srcs})
endmacro()

set(PROTO_CC_FILES)
add_dependencies(protogen toolchain)

get_target_property(PROTOBUF_PROTOC_EXECUTABLE protobuf::protoc IMPORTED_LOCATION)
get_target_property(GRPC_CPP_PLUGIN_EXECUTABLE gRPC::grpc_cpp_plugin IMPORTED_LOCATION)
message("protogen: use protoc: ${PROTOBUF_PROTOC_EXECUTABLE}")
message("protogen: use protoc grpc cpp plugin: ${GRPC_CPP_PLUGIN_EXECUTABLE}")
file(MAKE_DIRECTORY ${PROTOGEN_DIRECTORY})
generateProto("knn.proto")

message("Find proto cc files: ${PROTO_CC_FILES}")
set_target_properties(protogen PROPERTIES INCLUDE_DIRS "${PROTOGEN_DIRECTORY}")
set_target_properties(protogen PROPERTIES SOURCE_FILES "${PROTO_CC_FILES}")
