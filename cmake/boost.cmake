macro(build_boost)
    set(BOOST_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/boost_ep-prefix/src/boost_ep")
    set(BOOST_ROOT ${BOOST_PREFIX})
    set(BOOST_LIB_DIR "${BOOST_PREFIX}/stage/lib")
    set(BOOST_BUILD_LINK "static")
    set(BOOST_STATIC_SYSTEM_LIBRARY "${BOOST_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}boost_system${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(BOOST_STATIC_FILESYSTEM_LIBRARY "${BOOST_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}boost_filesystem${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(BOOST_STATIC_REGEX_LIBRARY "${BOOST_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}boost_regex${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(BOOST_STATIC_PROGRAM_OPTIONS_LIBRARY "${BOOST_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}boost_program_options${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set(BOOST_SYSTEM_LIBRARY boost_system_static)
    set(BOOST_FILESYSTEM_LIBRARY boost_filesystem_static)
    set(BOOST_REGEX_LIBRARY boost_regex_static)
    set(BOOST_BUILD_PRODUCTS ${BOOST_STATIC_SYSTEM_LIBRARY}
            ${BOOST_STATIC_FILESYSTEM_LIBRARY}
            ${BOOST_STATIC_REGEX_LIBRARY})
    set(BOOST_CONFIGURE_COMMAND "./bootstrap.sh" "--prefix=${BOOST_PREFIX}"
            "--with-libraries=filesystem,regex,system,program_options")
    if("${CMAKE_BUILD_TYPE}" STREQUAL "DEBUG")
        set(BOOST_BUILD_VARIANT "debug")
    else()
        set(BOOST_BUILD_VARIANT "release")
    endif()
    set(BOOST_BUILD_COMMAND "./b2" "link=${BOOST_BUILD_LINK}"
            "variant=${BOOST_BUILD_VARIANT}" "cxxflags=-fPIC")

    add_library(boost::boost_system STATIC IMPORTED)
    set_target_properties(boost::boost_system PROPERTIES IMPORTED_LOCATION "${BOOST_STATIC_SYSTEM_LIBRARY}" INTERFACE_INCLUDE_DIRECTORIES "${BOOST_INCLUDE_DIR}")
    add_library(boost::boost_filesystem STATIC IMPORTED)
    set_target_properties(boost::boost_filesystem PROPERTIES IMPORTED_LOCATION "${BOOST_STATIC_FILESYSTEM_LIBRARY}" INTERFACE_INCLUDE_DIRECTORIES "${BOOST_INCLUDE_DIR}")
    add_library(boost::boost_regex STATIC IMPORTED)
    set_target_properties(boost::boost_regex PROPERTIES IMPORTED_LOCATION "${BOOST_STATIC_REGEX_LIBRARY}" INTERFACE_INCLUDE_DIRECTORIES "${BOOST_INCLUDE_DIR}")
    add_library(boost::boost_program_options STATIC IMPORTED)
    set_target_properties(boost::boost_program_options PROPERTIES IMPORTED_LOCATION "${BOOST_STATIC_PROGRAM_OPTIONS_LIBRARY}" INTERFACE_INCLUDE_DIRECTORIES "${BOOST_INCLUDE_DIR}")

    externalproject_add(boost_ep
            URL ${BOOST_SOURCE_URL}
            BUILD_BYPRODUCTS ${BOOST_BUILD_PRODUCTS}
            BUILD_IN_SOURCE 1
            CONFIGURE_COMMAND ${BOOST_CONFIGURE_COMMAND}
            BUILD_COMMAND ${BOOST_BUILD_COMMAND}
            INSTALL_COMMAND "" ${EP_LOG_OPTIONS})
    set(Boost_INCLUDE_DIR "${BOOST_PREFIX}")
    set(Boost_INCLUDE_DIRS "${BOOST_INCLUDE_DIR}")
    add_dependencies(toolchain boost_ep)
    add_dependencies(boost::boost_system boost_ep)
    add_dependencies(boost::boost_filesystem boost_ep)
    add_dependencies(boost::boost_regex boost_ep)
    add_dependencies(boost::boost_program_options boost_ep)
endmacro()