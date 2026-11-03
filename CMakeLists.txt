cmake_minimum_required(VERSION 3.20)

project(ukca_box_model VERSION 0.1.0 LANGUAGES Fortran)

option(BUILD_UKCA_LIBRARY "Build the UKCA standalone library" ON)
option(BUILD_BOX_MODEL "Build the UKCA box model executable" ON)
option(UKCA_USE_EXTERNAL_LIBRARY
       "Link box model against an externally installed ukca_standalone library"
       OFF)

set(UKCA_EXTERNAL_MODULE_DIR ""
    CACHE PATH "Directory containing external UKCA Fortran .mod files")

set(CMAKE_Fortran_MODULE_DIRECTORY
    ${CMAKE_BINARY_DIR}/mod
)

add_subdirectory(src)