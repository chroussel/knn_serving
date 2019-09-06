macro(build_rapidjson)
    message(STATUS "Building rapidjson from source")
    set(RAPIDJSON_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/rapidjson_ep/src/rapidjson_ep-install")
    set(RAPIDJSON_INCLUDE_DIR "${RAPIDJSON_PREFIX}/include")
    set(RAPIDJSON_STATIC_LIB "${RAPIDJSON_PREFIX}/lib")

    set(RAPIDJSON_CMAKE_ARGS
            -DRAPIDJSON_BUILD_DOC=OFF
            -DRAPIDJSON_BUILD_EXAMPLES=OFF
            -DRAPIDJSON_BUILD_TESTS=OFF
            "-DCMAKE_INSTALL_PREFIX=${RAPIDJSON_PREFIX}")

    externalproject_add(rapidjson_ep
            ${EP_LOG_OPTIONS}
            PREFIX "${CMAKE_BINARY_DIR}"
            URL ${RAPIDJSON_SOURCE_URL}
            CMAKE_ARGS ${RAPIDJSON_CMAKE_ARGS})

    set(RAPIDJSON_INCLUDE_DIR "${RAPIDJSON_PREFIX}/include")
    add_library(rapidjson STATIC IMPORTED)
    set_target_properties(rapidjson PROPERTIES IMPORTED_LOCATION "${RAPIDJSON_STATIC_LIB}" INTERFACE_INCLUDE_DIRECTORIES "${RAPIDJSON_INCLUDE_DIR}")

    add_dependencies(toolchain rapidjson_ep)
    add_dependencies(rapidjson rapidjson_ep)
endmacro()