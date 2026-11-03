module box_io_mod

  !! Module for input/output operations in the UKCA box model.

  implicit none

  !> Module name for error reporting
  character(len=*), parameter :: mod_name = "box_io_mod"

  public :: write_tracer_output

  private

contains

  subroutine write_tracer_output(filename)

    !! Write the tracer output array to a csv file.

    use box_tracer_mod, only: output_tracers, num_tracers, tracer_varnames
    use box_time_mod, only: n_steps
    use ukca_api_mod, only: ukca_maxlen_message
    use box_err_codes_mod, only: box_errcode_io_tracer
    use umprintmgr, only: umMessage, umPrint
    use ereport_mod, only: ereport

    !> The name of the output file to write the tracer data to.
    character(len=*), intent(in) :: filename
    !> the I/O status code returned by the open statement
    integer :: iostat
    !> Loop index
    integer :: i
    !> Loop index
    integer :: j
    !> Error code for reporting I/O errors with the tracer output file
    integer :: err_code
    !> I/O unit number for the output file
    integer :: unit
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: error_message
    !> Routine name for error reporting
    character(len=*), parameter :: routine_name = "write_tracer_output"

    err_code = 0

    write(umMessage, '(A,A)') 'Writing tracer output to file: ', trim(filename)
    call umPrint(umMessage, src=mod_name//":"//routine_name)

    open(newunit=unit, file=filename, status='replace', action='write', &
         iostat=iostat)

    if(iostat /= 0) then
      write(error_message, '(A,A)') 'Error opening file: ', &
        trim(adjustl(filename))
      err_code = box_errcode_io_tracer
      ! Call error
      call ereport(mod_name//":"//routine_name, err_code, &
                   trim(error_message))
    endif

    ! Write header line with tracer variable names
    write(unit, '(A)', advance='no') 'TimeStep'
    do i = 1, num_tracers
      write(unit, '(2A)', advance='no') ',', trim(tracer_varnames(i))
    enddo
    write(unit, '(A)') ''

    ! Write tracer data for each time step
    do i = 0, n_steps
      ! Time step number
      write(unit, '(I0)', advance='no') i
      do j = 1, num_tracers
        write(unit, '(A,E15.6E3)', advance='no') ',', output_tracers(j, i)
      enddo
      write(unit, '(A)') ''
    enddo

    close(unit)

  endsubroutine write_tracer_output

endmodule box_io_mod
