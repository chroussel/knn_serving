macro(set_option_category name)
    set(ARROW_OPTION_CATEGORY ${name})
    list(APPEND "ARROW_OPTION_CATEGORIES" ${name})
endmacro()

macro(define_option name description default)
    option(${name} ${description} ${default})
    list(APPEND "ARROW_${ARROW_OPTION_CATEGORY}_OPTION_NAMES" ${name})
    set("${name}_OPTION_DESCRIPTION" ${description})
    set("${name}_OPTION_DEFAULT" ${default})
    set("${name}_OPTION_TYPE" "bool")
endmacro()


if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
    set_option_category("Thirdparty toolchain")
    define_option(KNN_VERBOSE_THIRDPARTY_BUILD "Show output from ExternalProjects rather than just logging to files" OFF)

endif()