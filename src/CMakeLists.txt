# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(blurhash_ffi_library VERSION 0.0.1 LANGUAGES C)

add_library(blurhash_ffi SHARED
  "blurhash_ffi.c"
)

set_target_properties(blurhash_ffi PROPERTIES
  PUBLIC_HEADER blurhash_ffi.h
  OUTPUT_NAME "blurhash_ffi"
)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")

target_compile_definitions(blurhash_ffi PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(blurhash_ffi PRIVATE "-Wl,-z,max-page-size=16384")
endif()
