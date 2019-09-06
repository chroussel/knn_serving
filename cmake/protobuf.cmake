macro(build_protobuf)
    message("Building Protocol Buffers from source")
    set(PROTOBUF_PREFIX "${THIRDPARTY_DIR}/protobuf_ep-install")
    set(PROTOBUF_INCLUDE_DIR "${PROTOBUF_PREFIX}/include")
    set(PROTOBUF_STATIC_LIB "${PROTOBUF_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}protobuf${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(PROTOC_STATIC_LIB "${PROTOBUF_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}protoc${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(PROTOBUF_COMPILER "${PROTOBUF_PREFIX}/bin/protoc")
    set(PROTOBUF_CONFIGURE_ARGS
            "AR=${CMAKE_AR}"
            "RANLIB=${CMAKE_RANLIB}"
            "CC=${CMAKE_C_COMPILER}"
            "CXX=${CMAKE_CXX_COMPILER}"
            "--disable-shared"
            "--prefix=${PROTOBUF_PREFIX}"
            "CFLAGS=${EP_C_FLAGS}"
            "CXXFLAGS=${EP_CXX_FLAGS}")

    externalproject_add(protobuf_ep
            CONFIGURE_COMMAND "./configure" ${PROTOBUF_CONFIGURE_ARGS}
            BUILD_COMMAND ${MAKE} ${MAKE_BUILD_ARGS}
            BUILD_IN_SOURCE 1
            URL ${PROTOBUF_SOURCE_URL}
            BUILD_BYPRODUCTS "${PROTOBUF_STATIC_LIB}" "${PROTOBUF_COMPILER}"
            ${EP_LOG_OPTIONS})

    file(MAKE_DIRECTORY "${PROTOBUF_INCLUDE_DIR}")

    add_library(protobuf::libprotobuf STATIC IMPORTED)
    set_target_properties(protobuf::libprotobuf PROPERTIES IMPORTED_LOCATION "${PROTOBUF_STATIC_LIB}" INTERFACE_INCLUDE_DIRECTORIES "${PROTOBUF_INCLUDE_DIR}")
    add_library(protobuf::libprotoc STATIC IMPORTED)
    set_target_properties(protobuf::libprotoc PROPERTIES IMPORTED_LOCATION "${PROTOC_STATIC_LIB}" INTERFACE_INCLUDE_DIRECTORIES "${PROTOBUF_INCLUDE_DIR}")
    add_executable(protobuf::protoc IMPORTED)
    set_target_properties(protobuf::protoc PROPERTIES IMPORTED_LOCATION "${PROTOBUF_COMPILER}")
    add_dependencies(toolchain protobuf_ep)
    add_dependencies(protobuf::libprotobuf protobuf_ep)
endmacro()


macro(resolve_proto)
    # TODO: Don't use global includes but rather target_include_directories
    include_directories(SYSTEM ${PROTOBUF_INCLUDE_DIR})

    # Old CMake versions don't define the targets
    if(NOT TARGET protobuf::libprotobuf)
        add_library(protobuf::libprotobuf UNKNOWN IMPORTED)
        set_target_properties(protobuf::libprotobuf
                PROPERTIES IMPORTED_LOCATION "${PROTOBUF_LIBRARY}"
                INTERFACE_INCLUDE_DIRECTORIES
                "${PROTOBUF_INCLUDE_DIR}")
    endif()
    if(NOT TARGET protobuf::libprotoc)
        if(PROTOBUF_PROTOC_LIBRARY AND NOT Protobuf_PROTOC_LIBRARY)
            # Old CMake versions have a different casing.
            set(Protobuf_PROTOC_LIBRARY ${PROTOBUF_PROTOC_LIBRARY})
        endif()
        if(NOT Protobuf_PROTOC_LIBRARY)
            message(FATAL_ERROR "libprotoc was set to ${Protobuf_PROTOC_LIBRARY}")
        endif()
        add_library(protobuf::libprotoc UNKNOWN IMPORTED)
        set_target_properties(protobuf::libprotoc
                PROPERTIES IMPORTED_LOCATION "${Protobuf_PROTOC_LIBRARY}"
                INTERFACE_INCLUDE_DIRECTORIES
                "${PROTOBUF_INCLUDE_DIR}")
    endif()
    if(NOT TARGET protobuf::protoc)
        add_executable(protobuf::protoc IMPORTED)
        set_target_properties(protobuf::protoc
                PROPERTIES IMPORTED_LOCATION "${PROTOBUF_PROTOC_EXECUTABLE}")
    endif()

    # Log protobuf paths as we often see issues with mixed sources for
    # the libraries and protoc.
    get_target_property(PROTOBUF_PROTOC_EXECUTABLE protobuf::protoc IMPORTED_LOCATION)
    message(STATUS "Found protoc: ${PROTOBUF_PROTOC_EXECUTABLE}")
    # Protobuf_PROTOC_LIBRARY is set by all versions of FindProtobuf.cmake
    message(STATUS "Found libprotoc: ${Protobuf_PROTOC_LIBRARY}")
    get_target_property(PROTOBUF_LIBRARY protobuf::libprotobuf IMPORTED_LOCATION)
    message(STATUS "Found libprotobuf: ${PROTOBUF_LIBRARY}")
    message(STATUS "Found protobuf headers: ${PROTOBUF_INCLUDE_DIR}")
endmacro()