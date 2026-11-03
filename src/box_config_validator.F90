module box_config_validator_mod

  !! Module for validating the configuration of the UKCA box model.

  ! TODO - big task to expand this to cover all configuration options

  use ukca_api_mod, only: ukca_maxlen_message
  use ereport_mod, only: ereport
  use box_err_codes_mod, only: box_errcode_config_range

  implicit none

  private

  public :: validate_config

  !> Module name for error reporting
  character(len=*), parameter :: mod_name = "box_config_validator_mod"

contains

  subroutine validate_config(cfg)

    !! Validate the inputted configuration

    use box_config_mod, only: box_config_type

    !> The configuration to validate
    type(box_config_type), intent(in) :: cfg

    ! Validate i_mode_nucscav
    call check_int_in_range(cfg%i_mode_nucscav, "i_mode_nucscav", 1, 3)

  endsubroutine validate_config

  subroutine check_int_in_range(value, value_name, min_val, max_val)

    !! Check if an integer value is within a specified range. If the value is
    !! out of range, an error is reported.

    !> The integer value to check
    integer, intent(in) :: value
    !> The name of the value for error reporting
    character(len=*), intent(in) :: value_name
    !> The minimum valid value
    integer, intent(in) :: min_val
    !> The maximum valid value
    integer, intent(in) :: max_val
    !> Logical indicating if the value is valid
    logical :: is_valid
    !> Error code for error reporting
    integer :: err_code
    !> Error message for error reporting
    character(len=ukca_maxlen_message) :: err_message
    !> Name of the routine for error reporting
    character(len=*), parameter :: routine_name = &
                                   mod_name//":check_int_in_range"

    is_valid = (value >= min_val .and. value <= max_val)

    if(.not. is_valid) then
      write(err_message, "(3A,I0,A,I0,3A,I0)") "Value of ", &
        trim(value_name), " (", value, ") is out of range: ", min_val, &
        " <= ", trim(value_name), " <= ", max_val
      err_code = box_errcode_config_range
      call ereport(routine_name, err_code, err_message)
    endif

  endsubroutine check_int_in_range

endmodule box_config_validator_mod
