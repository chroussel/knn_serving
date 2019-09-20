project(KNN_SERVICE)

cmake_minimum_required(VERSION 3.2)
message(STATUS "Building using CMake version: ${CMAKE_VERSION}")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
set(knn_SOURCE_DIR ${PROJECT_SOURCE_DIR})

include(DefineOptions)
#find_package(benchmark REQUIRED)
include(ExternalProject)
include(thirdparty)


add_custom_target(knn_dependencies)

set(KNN_SERVICE 1.0.0)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m64 -march=x86-64 -Wall -pedantic -mavx -msse4 -fvisibility=hidden -pthread")
set(CMAKE_CXX_FLAGS_DEBUG "-g3")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -g")

add_dependencies(knn_dependencies toolchain)

list(APPEND KNN_LINK_LIBS protobuf::libprotobuf)
list(APPEND KNN_STATIC_LINK_LIBS protobuf::libprotobuf)
list(APPEND KNN_STATIC_INSTALL_INTERFACE_LIBS protobuf::libprotobuf)

include_directories(include)

message("Installing to ${CMAKE_INSTALL_PREFIX}")
install(DIRECTORY DESTINATION "${CMAKE_INSTALL_PREFIX}")

add_subdirectory(src/proto)
add_subdirectory(src/cpp)