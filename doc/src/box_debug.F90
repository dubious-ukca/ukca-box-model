module box_debug_mod

  !! A module for managing the debug level of the box model, allowing the user
  !! to set and query the debug level.
  !!
  !! The debug level is an integer value that controls the verbosity of the
  !! output. Current debug levels:
  !!
  !! - 0 = gives no debug output,
  !! - 1 = basic debug output,
  !! - 2 = detailed debug output,
  !! - 3 = maximum verbosity.

  use ereport_mod, only: ereport
  use ukca_api_mod, only: ukca_maxlen_message, ukca_maxlen_procname, &
                          ukca_errcode_value_invalid

  implicit none

  private

  public :: set_debug_level
  public :: get_debug_level
  public :: is_debug_level

  !> The current debug level for the box model. Default is 0 (no debug output).
  integer :: debug_level = 0
  !> module name
  character(len=*), parameter :: mod_name = "box_debug_mod"
  !> The maximum debug level allowed.
  integer, parameter :: max_debug_level = 3

contains

  subroutine set_debug_level(level)
    !! Set the debug level for the box model. Higher levels may produce more
    !! verbose output. level 0 is not debug output.

    !> The debug level to set for the box model. Must be between 0 and
    !> max_debug_level.
    integer, intent(in) :: level
    !> the error code for the error message
    integer :: err_code
    !> the error message to be printed
    character(len=ukca_maxlen_message) :: error_message
    !> the routine name for the error message
    character(len=ukca_maxlen_procname) :: error_routine

    error_routine = mod_name//":set_debug_level"

    !> error code directly from ukca api
    err_code = ukca_errcode_value_invalid

    if(level < 0) then
      write(error_message, '(A,I0)') "Debug level cannot be less "// &
        "than 0: ", level
      call ereport(error_routine, err_code, error_message)
    endif

    if(level > max_debug_level) then
      write(error_message, '(A,I0,A,I0)') "Debug level cannot "// &
        "be greater than ", max_debug_level, ": ", level
      call ereport(error_routine, err_code, error_message)
    endif

    debug_level = level

  endsubroutine set_debug_level

  function get_debug_level() result(level)
    !! Get the current debug level of the box model.

    !> The current debug level of the box model.
    integer :: level

    level = debug_level

  endfunction get_debug_level

  function is_debug_level(min_level) result(is_active)
    !! Function to check if the current debug level is at least the specified
    !! minimum level.

    !> The minimum debug level to check against.
    integer, intent(in) :: min_level
    !> A logical value indicating whether the current debug level is at least
    !> the minimum level.
    logical :: is_active

    is_active = (debug_level >= min_level)

  endfunction is_debug_level

endmodule box_debug_mod
