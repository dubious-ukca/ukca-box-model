module box_err_codes_mod

  !! Module for storing error codes for the UKCA box model. These are used
  !! for error reporting and handling within the box model.

  implicit none

  public

  ! Error codes for IO issues
  !> Error code for IO issues with writing tracer file
  integer, parameter :: box_errcode_io_tracer = 101
  !> Error code for IO issues with reading NTP file
  integer, parameter :: box_errcode_io_ntp = 102
  !> Error code for IO issues with the offline photolysis rates file.
  integer, parameter :: box_errcode_io_photol_offline = 103
  !> Error code for issues related to the environment namelist
  integer, parameter :: box_errcode_env_namelist = 104
  !> Error code for issues related to the box config namelist
  integer, parameter :: box_errcode_config_namelist = 105

  ! Error codes for issues with box model arrays
  !> Error code for generic issues with the NTP array
  integer, parameter :: box_errcode_ntp = 201
  !> Error code for duplicate species in the tracers array
  integer, parameter :: box_errcode_duplicate_species = 202
  !> Error code for tracer output not allocated
  integer, parameter :: box_errcode_tracer_allocation = 203
  !> Error code for tracer not found in array
  integer, parameter :: box_errcode_tracer_not_found = 204
  !> Error code for duplicate ntp variable name in ntp array
  integer, parameter :: box_errcode_duplicate_ntp = 205

  ! Error codes for configuration issues
  !> Error code for configuration values out of range
  integer, parameter :: box_errcode_config_range = 301
  !> Error code for not implemented
  integer, parameter :: box_errcode_not_implemented = 302
  !> Error code for invalid command line arguments
  integer, parameter :: box_errcode_command_line = 303

  ! Error codes for internal box model issues
  !> Error code for generic internal box model issues
  integer, parameter :: box_errcode_internal = 401
  !> Error code for invalid time
  integer, parameter :: box_errcode_invalid_time = 402
  !> Error code for environment field number mismatch
  integer, parameter :: box_errcode_env_count = 403
  !> Error code for environment field type
  integer, parameter :: box_errcode_env_type = 404
  !> Error code for environment field not associated
  integer, parameter :: box_errcode_env_not_assoc = 405
  !> Error code for non-physical calculation
  integer, parameter :: box_errcode_non_phys_calc = 406

endmodule box_err_codes_mod
