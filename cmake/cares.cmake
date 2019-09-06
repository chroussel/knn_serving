macro(build_cares)
    message(STATUS "Building c-ares from source")
    set(CARES_PREFIX "${THIRDPARTY_DIR}/cares_ep-install")
    set(CARES_INCLUDE_DIR "${CARES_PREFIX}/include")

    set(CARES_STATIC_LIB "${CARES_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}cares${CMAKE_STATIC_LIBRARY_SUFFIX}")

    set(CARES_CMAKE_ARGS
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCARES_STATIC=ON
            -DCARES_SHARED=OFF
            "-DCMAKE_C_FLAGS=${EP_C_FLAGS}"
            "-DCMAKE_INSTALL_PREFIX=${CARES_PREFIX}")

    externalproject_add(cares_ep
            ${EP_LOG_OPTIONS}
            URL ${CARES_SOURCE_URL}
            CMAKE_ARGS ${CARES_CMAKE_ARGS}
            BUILD_BYPRODUCTS "${CARES_STATIC_LIB}")

    file(MAKE_DIRECTORY ${CARES_INCLUDE_DIR})

    add_library(c-ares::cares STATIC IMPORTED)
    set_target_properties(c-ares::cares PROPERTIES IMPORTED_LOCATION "${CARES_STATIC_LIB}" INTERFACE_INCLUDE_DIRECTORIES "${CARES_INCLUDE_DIR}")

    add_dependencies(toolchain cares_ep)
    add_dependencies(c-ares::cares cares_ep)
endmacro()