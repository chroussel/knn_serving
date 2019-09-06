macro(build_gflags)
    message(STATUS "Building gflags from source")
    set(GFLAGS_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/gflags_ep-prefix/src/gflags_ep")
    set(GFLAGS_INCLUDE_DIR "${GFLAGS_PREFIX}/include")
    if(MSVC)
        set(GFLAGS_STATIC_LIB "${GFLAGS_PREFIX}/lib/gflags_static.lib")
    else()
        set(GFLAGS_STATIC_LIB "${GFLAGS_PREFIX}/lib/libgflags.a")
    endif()
    set(GFLAGS_CMAKE_ARGS
            ${EP_COMMON_CMAKE_ARGS}
            "-DCMAKE_INSTALL_PREFIX=${GFLAGS_PREFIX}"
            -DBUILD_SHARED_LIBS=OFF
            -DBUILD_STATIC_LIBS=ON
            -DBUILD_PACKAGING=OFF
            -DBUILD_TESTING=OFF
            -DBUILD_CONFIG_TESTS=OFF
            -DINSTALL_HEADERS=ON)

    file(MAKE_DIRECTORY "${GFLAGS_INCLUDE_DIR}")
    externalproject_add(gflags_ep
            URL ${GFLAGS_SOURCE_URL} ${EP_LOG_OPTIONS}
            BUILD_IN_SOURCE 1
            BUILD_BYPRODUCTS "${GFLAGS_STATIC_LIB}"
            CMAKE_ARGS ${GFLAGS_CMAKE_ARGS})

    add_library(gflags STATIC IMPORTED)
    set_target_properties(gflags PROPERTIES IMPORTED_LOCATION "${GFLAGS_STATIC_LIB}" INTERFACE_INCLUDE_DIRECTORIES "${GFLAGS_INCLUDE_DIR}")

    add_dependencies(toolchain gflags_ep)
    add_dependencies(gflags gflags_ep)
endmacro()