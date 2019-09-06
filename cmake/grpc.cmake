macro(build_grpc)
    message(STATUS "Building gRPC from source")
    set(GRPC_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/grpc_ep-prefix/src/grpc_ep-build")
    set(GRPC_PREFIX "${THIRDPARTY_DIR}/grpc_ep-install")
    set(GRPC_HOME "${GRPC_PREFIX}")
    set(GRPC_INCLUDE_DIR "${GRPC_PREFIX}/include")
    set(GRPC_CMAKE_ARGS ${EP_COMMON_CMAKE_ARGS} "-DCMAKE_INSTALL_PREFIX=${GRPC_PREFIX}"
            -DBUILD_SHARED_LIBS=OFF)

    set(GRPC_STATIC_LIBRARY_GPR "${GRPC_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gpr${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(GRPC_STATIC_LIBRARY_GRPC "${GRPC_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}grpc${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(GRPC_STATIC_LIBRARY_GRPCPP "${GRPC_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}grpc++${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(GRPC_STATIC_LIBRARY_ADDRESS_SORTING "${GRPC_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}address_sorting${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(GRPC_CPP_PLUGIN "${GRPC_PREFIX}/bin/grpc_cpp_plugin")

    set(GRPC_CMAKE_PREFIX)

    add_custom_target(grpc_dependencies)

    add_dependencies(grpc_dependencies cares_ep)
    add_dependencies(grpc_dependencies gflags_ep)
    add_dependencies(grpc_dependencies protobuf::libprotobuf c-ares::cares)

    get_target_property(GRPC_PROTOBUF_INCLUDE_DIR protobuf::libprotobuf INTERFACE_INCLUDE_DIRECTORIES)
    get_filename_component(GRPC_PB_ROOT "${GRPC_PROTOBUF_INCLUDE_DIR}" DIRECTORY)
    get_target_property(GRPC_Protobuf_PROTOC_LIBRARY protobuf::libprotoc IMPORTED_LOCATION)
    get_target_property(GRPC_CARES_INCLUDE_DIR c-ares::cares INTERFACE_INCLUDE_DIRECTORIES)
    get_filename_component(GRPC_CARES_ROOT "${GRPC_CARES_INCLUDE_DIR}" DIRECTORY)
    get_target_property(GRPC_GFLAGS_INCLUDE_DIR gflags INTERFACE_INCLUDE_DIRECTORIES)
    get_filename_component(GRPC_GFLAGS_ROOT "${GRPC_GFLAGS_INCLUDE_DIR}" DIRECTORY)
    get_target_property(GRPC_ZLIB_INCLUDE_DIR ZLIB::ZLIB INTERFACE_INCLUDE_DIRECTORIES)
    get_filename_component(GRPC_ZLIB_ROOT "${GRPC_ZLIB_INCLUDE_DIR}" DIRECTORY)

    set(GRPC_CMAKE_PREFIX "${GRPC_CMAKE_PREFIX};${GRPC_PB_ROOT}")
    set(GRPC_CMAKE_PREFIX "${GRPC_CMAKE_PREFIX};${GRPC_GFLAGS_ROOT}")
    set(GRPC_CMAKE_PREFIX "${GRPC_CMAKE_PREFIX};${GRPC_CARES_ROOT}")
    set(GRPC_CMAKE_PREFIX "${GRPC_CMAKE_PREFIX};${GRPC_ZLIB_ROOT}")

    add_dependencies(grpc_dependencies rapidjson_ep)

    # Yuck, see https://stackoverflow.com/a/45433229/776560
    string(REPLACE ";" "|" GRPC_PREFIX_PATH_ALT_SEP "${GRPC_CMAKE_PREFIX}")
    message("Prefix path: ${GRPC_PREFIX_PATH_ALT_SEP}")
    set(GRPC_CMAKE_ARGS
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_PREFIX_PATH='${GRPC_PREFIX_PATH_ALT_SEP}'
            -DgRPC_CARES_PROVIDER=package
            -DgRPC_GFLAGS_PROVIDER=package
            -DgRPC_PROTOBUF_PROVIDER=package
            -DgRPC_SSL_PROVIDER=package
            -DgRPC_ZLIB_PROVIDER=package
            -DCMAKE_CXX_FLAGS=${EP_CXX_FLAGS}
            -DCMAKE_C_FLAGS=${EP_C_FLAGS}
            -DCMAKE_INSTALL_PREFIX=${GRPC_PREFIX}
            -DCMAKE_INSTALL_LIBDIR=lib
            "-DProtobuf_PROTOC_LIBRARY=${GRPC_Protobuf_PROTOC_LIBRARY}"
            "-DProtobuf_DIR=${GRPC_PB_ROOT}"
            -DBUILD_SHARED_LIBS=OFF)
    if(OPENSSL_ROOT_DIR)
        list(APPEND GRPC_CMAKE_ARGS -DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR})
    endif()

    # XXX the gRPC git checkout is huge and takes a long time
    # Ideally, we should be able to use the tarballs, but they don't contain
    # vendored dependencies such as c-ares...
    externalproject_add(grpc_ep
            URL ${GRPC_SOURCE_URL}
            LIST_SEPARATOR |
            BUILD_BYPRODUCTS ${GRPC_STATIC_LIBRARY_GPR}
            ${GRPC_STATIC_LIBRARY_GRPC}
            ${GRPC_STATIC_LIBRARY_GRPCPP}
            ${GRPC_STATIC_LIBRARY_ADDRESS_SORTING}
            ${GRPC_CPP_PLUGIN}
            CMAKE_ARGS ${GRPC_CMAKE_ARGS} ${EP_LOG_OPTIONS}
            DEPENDS ${grpc_dependencies})

    # Work around https://gitlab.kitware.com/cmake/cmake/issues/15052
    file(MAKE_DIRECTORY ${GRPC_INCLUDE_DIR})

    add_library(gRPC::gpr STATIC IMPORTED)
    set_target_properties(gRPC::gpr
            PROPERTIES IMPORTED_LOCATION "${GRPC_STATIC_LIBRARY_GPR}"
            INTERFACE_INCLUDE_DIRECTORIES "${GRPC_INCLUDE_DIR}")

    add_library(gRPC::grpc STATIC IMPORTED)
    set_target_properties(gRPC::grpc
            PROPERTIES IMPORTED_LOCATION "${GRPC_STATIC_LIBRARY_GRPC}"
            INTERFACE_INCLUDE_DIRECTORIES "${GRPC_INCLUDE_DIR}")

    add_library(gRPC::grpc++ STATIC IMPORTED)
    set_target_properties(gRPC::grpc++
            PROPERTIES IMPORTED_LOCATION "${GRPC_STATIC_LIBRARY_GRPCPP}"
            INTERFACE_INCLUDE_DIRECTORIES "${GRPC_INCLUDE_DIR}")

    add_library(gRPC::address_sorting STATIC IMPORTED)
    set_target_properties(gRPC::address_sorting
            PROPERTIES IMPORTED_LOCATION
            "${GRPC_STATIC_LIBRARY_ADDRESS_SORTING}"
            INTERFACE_INCLUDE_DIRECTORIES "${GRPC_INCLUDE_DIR}")

    add_executable(gRPC::grpc_cpp_plugin IMPORTED)
    set_target_properties(gRPC::grpc_cpp_plugin PROPERTIES IMPORTED_LOCATION ${GRPC_CPP_PLUGIN})

    add_dependencies(grpc_ep grpc_dependencies)
    add_dependencies(toolchain grpc_ep)
    add_dependencies(gRPC::gpr grpc_ep)
    add_dependencies(gRPC::grpc grpc_ep)
    add_dependencies(gRPC::grpc++ grpc_ep)
    add_dependencies(gRPC::address_sorting grpc_ep)
endmacro()