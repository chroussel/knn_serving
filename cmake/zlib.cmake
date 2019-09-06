macro(build_zlib)
    message(STATUS "Building ZLIB from source")
    set(ZLIB_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/zlib_ep/src/zlib_ep-install")
    if(MSVC)
        if(${UPPERCASE_BUILD_TYPE} STREQUAL "DEBUG")
            set(ZLIB_STATIC_LIB_NAME zlibstaticd.lib)
        else()
            set(ZLIB_STATIC_LIB_NAME zlibstatic.lib)
        endif()
    else()
        set(ZLIB_STATIC_LIB_NAME libz.a)
    endif()
    set(ZLIB_STATIC_LIB "${ZLIB_PREFIX}/lib/${ZLIB_STATIC_LIB_NAME}")
    set(ZLIB_CMAKE_ARGS ${EP_COMMON_CMAKE_ARGS} "-DCMAKE_INSTALL_PREFIX=${ZLIB_PREFIX}"
            -DBUILD_SHARED_LIBS=OFF)

    externalproject_add(zlib_ep
            URL ${ZLIB_SOURCE_URL} ${EP_LOG_OPTIONS}
            BUILD_BYPRODUCTS "${ZLIB_STATIC_LIB}"
            CMAKE_ARGS ${ZLIB_CMAKE_ARGS})

    file(MAKE_DIRECTORY "${ZLIB_PREFIX}/include")

    add_library(ZLIB::ZLIB STATIC IMPORTED)
    set_target_properties(ZLIB::ZLIB
            PROPERTIES IMPORTED_LOCATION "${ZLIB_STATIC_LIB}"
            INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_PREFIX}/include")

    add_dependencies(toolchain zlib_ep)
    add_dependencies(ZLIB::ZLIB zlib_ep)
endmacro()