cmake_minimum_required(VERSION 3.20)

project(ukca_box_model VERSION 0.1.0 LANGUAGES Fortran)

option(BUILD_UKCA_LIBRARY "Build the UKCA standalone library" ON)
option(BUILD_BOX_MODEL "Build the UKCA box model executable" ON)
option(UKCA_USE_EXTERNAL_LIBRARY
       "Link box model against an externally installed ukca_standalone library"
       OFF)

set(UKCA_EXTERNAL_MODULE_DIR ""
    CACHE PATH "Directory containing external UKCA Fortran .mod files")

# Because UKCA doesn't use a kind module we have to set precision via the
# compiler. note that -fdefault-double-8 must accompany -fdefault-real-8,
# otherwise DOUBLE PRECISION is promoted to 16 bytes.
set(UKCA_PRECISION "double"
    CACHE STRING "Default REAL precision for UKCA and the box model (double or single)")
set_property(CACHE UKCA_PRECISION PROPERTY STRINGS double single)

# Integers are always 8 bytes, as before
set(UKCA_PRECISION_FLAGS -fdefault-integer-8)
if(UKCA_PRECISION STREQUAL "double")
  list(APPEND UKCA_PRECISION_FLAGS -fdefault-real-8 -fdefault-double-8)
elseif(UKCA_PRECISION STREQUAL "single")
  # UKCA um13.9 does not currently compile at single precision, e.g.
  # ukca_aerod.F90 has REAL constants (1.0e50) beyond the 32-bit range.
  message(WARNING "Running UKCA box model in single precision")
  # note the default for gfortran is 4 bytes for REAL
  list(APPEND UKCA_PRECISION_FLAGS -fdefault-double-8)
else()
  message(
    FATAL_ERROR
    "UKCA_PRECISION must be 'double' or 'single', got '${UKCA_PRECISION}'")
endif()
message(STATUS "UKCA precision: ${UKCA_PRECISION} (${UKCA_PRECISION_FLAGS})")

if(UKCA_USE_EXTERNAL_LIBRARY)
  message(WARNING "The external ukca_standalone library must be built with "
                  "UKCA_PRECISION=${UKCA_PRECISION}, or argument kinds will "
                  "not match.")
endif()

set(CMAKE_Fortran_MODULE_DIRECTORY
    ${CMAKE_BINARY_DIR}/mod
)

add_subdirectory(src)