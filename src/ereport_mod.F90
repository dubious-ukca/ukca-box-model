module ereport_mod

  !! Module for error reporting in the UKCA box model. Used preferentially
  !! over the legacy `ereport_mod.F90` module, so that it stops the model with
  !! a non-zero exit code if an error has occurred.

  implicit none

  private

  !> Public subroutine for error reporting.
  public ereport

contains

  subroutine ereport(routine_name, error_status, message)

    !! Report errors, warnings, and info messages in the UKCA box model.

    use, intrinsic :: iso_fortran_env, only: error_unit

    !> The name of the routine where the error occurred.
    character(len=*), intent(in) :: routine_name
    !> The error status code. Positive for errors, negative for warnings, and
    !> zero for info messages. This will be reset to zero after reporting.
    integer, intent(in out) :: error_status
    !> The message to be reported.
    character(len=*), intent(in) :: message

    ! Take action depending on UM error status convention
    if(error_status > 0) then
      write(error_unit, '(A,A,A,A)') 'UKCA ERROR in ', trim(routine_name), &
        ': ', trim(message)
      flush(error_unit)
      ! If an error has occurred lets stop with a non-zero exit code.
      error stop 1
    else if(error_status < 0) then
      write(error_unit, '(A,A,A,A)') 'UKCA WARNING in ', trim(routine_name), &
        ': ', trim(message)
    else
      write(error_unit, '(A,A,A,A)') 'UKCA INFO in ', trim(routine_name), &
        ': ', trim(message)
    endif

    ! Reset `error_status` for warnings and info only.
    error_status = 0

  endsubroutine ereport

endmodule ereport_mod
