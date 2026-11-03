module box_ntp_mod

  !! Module for handling non-transported prognostic variables (NTPs) in the
  !! UKCA box model.

  use ukca_api_mod, only: ukca_get_ntp_varlist, ukca_maxlen_fieldname, &
                          ukca_maxlen_procname, ukca_maxlen_message
  use ereport_mod, only: ereport
  use umprintmgr, only: umMessage, umPrint
  use box_debug_mod, only: is_debug_level

  implicit none

  !> Pointer to an array containing the names of the NTP variable names
  character(len=ukca_maxlen_fieldname), pointer :: ntp_varnames(:)
  !> Allocatable array to hold the values of the NTP variables. The dimensions
  !> are (row_length, rows, model_levels, num_ntps).
  real, allocatable, public :: ntp_ukca(:, :, :, :)
  !> The module name for error reporting.
  character(len=*), parameter :: mod_name = "box_ntp_mod"
  !> The number of non-transported prognostic variables.
  integer, public :: num_ntps

  private

  public :: get_ntp_varnames, create_initial_ntp

contains

  subroutine get_ntp_varnames()

    !! Retrieve the list of non-transported prognostic variable names from
    !! the UKCA API and store them in the ntp_varnames pointer.

    !> The error code returned by the UKCA API call.
    integer :: err_code
    !> Loop index
    integer :: i
    !> The error message for error reporting returned from
    !> ukca_get_ntp_varlist.
    character(len=ukca_maxlen_message) :: err_msg
    !> The routine name for error reporting returned from
    !> ukca_get_ntp_varlist.
    character(len=ukca_maxlen_procname) :: err_routine

    ! Initialise list pointer for safety
    nullify(ntp_varnames)

    ! Fetch ntp variable names from UKCA API
    call ukca_get_ntp_varlist(ntp_varnames, err_code, &
                              error_message=err_msg, error_routine=err_routine)

    if(err_code /= 0) then
      call ereport(err_routine, err_code, err_msg)
    endif

    ! public variable
    num_ntps = size(ntp_varnames)

    if(is_debug_level(1)) then
      ! print out each available non-transported prognostic variable
      do i = 1, size(ntp_varnames)
        write(umMessage,("(3A)")) "Available non-transported prognostic ", &
          "variable name: ", ntp_varnames(i)
        call umPrint(umMessage, src=mod_name)
      enddo
    endif

  endsubroutine get_ntp_varnames

  subroutine create_initial_ntp(ntp_file)

    !! Create the initial values for the non-transported prognostic (ntp)
    !! array from a provided file.
    !!
    !! The file should contain lines of the form: <var_name> <var_value>
    !!
    !! Where <var_name> is the name of the non-transported prognostic variable
    !! and <var_value> is the initial value to set for that variable. If the
    !! variable name is "DEFAULT", then <var_value> will be used as the default
    !! value for any non-transported prognostic variable not explicitly set in
    !! the file. If no "DEFAULT" line is provided, the default value will be
    !! set to 1.0e-14.

    use box_const_mod, only: row_length, rows, model_levels
    use box_err_codes_mod, only: box_errcode_io_ntp, box_errcode_ntp

    !> The name of the file containing the values for initial non-transported
    !> prognostic (ntp) array
    character(len=*), intent(in) :: ntp_file
    !> A logical value indicating whether the file exists
    logical :: file_exists
    !> A logical value indicating whether the variable was found
    logical :: found
    !> The unit number for the file
    integer :: unit
    !> The I/O status for reading the file
    integer :: iostat_read
    !> The I/O status for opening the file
    integer :: iostat_open
    !> The I/O status for parsing the file
    integer :: iostat_parse
    !> The error message for error reporting
    character(len=ukca_maxlen_message) :: err_msg
    !> Error code for error reporting
    integer :: err_code
    !> NTP generic default
    real, parameter :: generic_default_value = 1.0e-14
    !> The routine name for error reporting
    character(len=ukca_maxlen_procname) :: routine_name
    !> A line read from the file
    character(len=256) :: line
    !> The name of the variable read from the file
    character(len=256) :: var_name
    !> A logical array indicating which ntps have been provided in the file
    logical :: ntp_provided(num_ntps)
    !> The value of the variable read from the file
    real :: var_value
    !> The default value for any ntp not provided in the file
    real :: default_value
    !> The index of the ntp variable in the ntp_varnames array
    integer :: ntp_index
    !> Loop index
    integer :: i

    ! for error reporting
    routine_name = mod_name//":create_initial_ntp"

    if(allocated(ntp_ukca)) then
      deallocate(ntp_ukca)
    endif

    allocate(ntp_ukca(row_length, rows, model_levels, num_ntps))

    default_value = generic_default_value
    ntp_index = 0
    ntp_provided = .false.
    iostat_read = 0
    iostat_open = 0
    iostat_parse = 0

    if(num_ntps == 0) then
      write(err_msg, "(2A)") "No non-transported prognostic variables ", &
        "required to initialise. Check UKCA configuration."
      err_code = box_errcode_ntp * (-1)
      call ereport(routine_name, err_code, err_msg)
      return
    endif

    inquire(file=ntp_file, exist=file_exists)
    if(.not. file_exists) then
      write(err_msg, "(3A)") "Non-transported prognostic variable file '", &
        trim(ntp_file), "' does not exist."
      err_code = box_errcode_io_ntp
      call ereport(routine_name, err_code, err_msg)
    endif

    ! TODO - because this is so similar to the tracer initialisation, we
    ! could likely combine these into a single routine with some additional
    ! arguments

    open(newunit=unit, file=ntp_file, status='old', action='read', &
         iostat=iostat_open)

    if(iostat_open /= 0) then
      write(err_msg, "(4A)") "Error opening non-transported prognostic ", &
        "variable file '", trim(ntp_file), "'."
      err_code = box_errcode_io_ntp
      call ereport(routine_name, err_code, err_msg)
    endif

    do
      read(unit, '(A)', iostat=iostat_read) line
      if(iostat_read /= 0) exit

      ! Skip blank lines or comments.
      if(len_trim(line) == 0 .or. line(1:1) == '#') cycle

      ! Read whitespace-separated tokens: <var_name> <var_value>
      read(line, *, iostat=iostat_parse) var_name, var_value
      if(iostat_parse /= 0) then
        write(err_msg, "(3A)") "WARNING: Could not parse ntp line: '", &
          trim(line), "'."
        err_code = box_errcode_io_ntp * (-1)
        call ereport(routine_name, err_code, err_msg)
        cycle
      endif

      if(var_name == "DEFAULT") then
        default_value = var_value
        cycle
      endif

      ! from the list of ntp variable names, find the index of the variable
      call find_ntp_index(var_name, ntp_index, found)

      if(found) then
        ntp_ukca(:, :, :, ntp_index) = var_value
        ntp_provided(ntp_index) = .true.

        write(umMessage, "(3A,E12.3,A)") "Set initial value of ntp '", &
          trim(var_name), "' to ", var_value, "."
        call umPrint(umMessage, src=routine_name)

      else
        write(err_msg, "(3A)") "WARNING: Variable '", trim(var_name), &
          "' in ntp file not found in needed ntp variable list."
        err_code = box_errcode_io_ntp * (-1)
        call ereport(routine_name, err_code, err_msg)
      endif

    enddo

    close(unit)

    ! now use default value for unset ntps and provide warning for any
    ! ntps not actively being set
    do i = 1, num_ntps
      if(.not. ntp_provided(i)) then
        ntp_ukca(:, :, :, i) = default_value
        write(err_msg, &
              "(3A,E12.3,A)") "WARNING: No value provided for ntp '", &
          trim(ntp_varnames(i)), &
          "' in ntp file. Setting to default value of ", default_value, "."
        err_code = box_errcode_io_ntp * (-1)
        call ereport(routine_name, err_code, err_msg)
      endif
    enddo

  endsubroutine create_initial_ntp

  subroutine find_ntp_index(var_name, ntp_index, found)

    !! Find the index of a non-transported prognostic variable in the
    !! ntp_varnames array.

    use box_err_codes_mod, only: box_errcode_duplicate_ntp

    !> The name of the non-transported prognostic variable to find.
    character(len=*), intent(in) :: var_name
    !> The index of the non-transported prognostic variable in the
    !> ntp_varnames array.
    integer, intent(out) :: ntp_index
    !> A logical value indicating whether the variable was found in the
    !> ntp_varnames array.
    logical, intent(out) :: found
    !> The error code for error reporting.
    integer :: err_code
    !> The error message for error reporting.
    character(len=ukca_maxlen_message) :: err_msg
    !> The name of the routine for error reporting.
    character(len=ukca_maxlen_procname) :: routine_name

    !> Loop index
    integer :: i

    found = .false.
    ntp_index = -1
    routine_name = mod_name//":find_ntp_index"

    do i = 1, num_ntps
      if(ntp_varnames(i) == var_name) then

        if(found) then
          write(err_msg, "(3A)") "Duplicate variable name found in ", &
            "ntp_varnames: ", trim(var_name)
          err_code = box_errcode_duplicate_ntp
          call ereport(routine_name, err_code, err_msg)
          return
        endif

        found = .true.
        ntp_index = i

      endif
    enddo

  endsubroutine find_ntp_index

endmodule box_ntp_mod
