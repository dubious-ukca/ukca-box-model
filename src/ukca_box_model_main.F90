program ukca_box_model_main

  !! Run the UKCA box model. The only input on the command line is the box
  !! config namelist, which names the other input files:
  !!
  !!     ukca_box_model namelist.nml [--debug <level>]

  use box_shell_mod, only: box_shell
  use box_debug_mod, only: set_debug_level
  use box_err_codes_mod, only: box_errcode_command_line
  use ereport_mod, only: ereport
  use ukca_api_mod, only: ukca_maxlen_message
  use umprintmgr, only: umMessage, umPrint

  implicit none

  !> Program name for logging and error reporting
  character(len=*), parameter :: prog_name = "ukca_box_model_main"

  !> One command line argument
  character(len=256) :: arg
  !> Path to the box config namelist
  character(len=256) :: namelist_path
  !> Number of command line arguments
  integer :: num_args
  !> Index of the current command line argument
  integer :: i
  !> Debug level set by --debug
  integer :: debug_level
  !> I/O status from reading the debug level
  integer :: iostat
  !> Whether the namelist file exists
  logical :: exists
  !> Error code for error reporting
  integer :: err_code
  !> Message for error reporting
  character(len=ukca_maxlen_message) :: err_msg

  num_args = command_argument_count()

  namelist_path = ''
  debug_level = 0  ! default: no debug

  i = 1
  do while(i <= num_args)
    call get_command_argument(i, arg)

    select case(trim(arg))
    case('--help', '-h')
      call print_usage()
      stop 0

    case('--debug', '-d')
      call next_argument(i, arg)
      read(arg, *, iostat=iostat) debug_level
      if(iostat /= 0) then
        write(err_msg, "(2A)") "Invalid debug level: ", trim(arg)
        call report_usage_error(err_msg)
      endif

    case default
      if(arg(1:1) == '-') then
        write(err_msg, "(2A)") "Unknown option: ", trim(arg)
        call report_usage_error(err_msg)
      endif

      if(len_trim(namelist_path) > 0) then
        write(err_msg, "(3A)") "Only one namelist file can be given, got '", &
          trim(arg), "' as well"
        call report_usage_error(err_msg)
      endif
      namelist_path = arg
    endselect

    i = i + 1
  enddo

  if(len_trim(namelist_path) == 0) then
    write(err_msg, "(A)") "No namelist file given"
    call report_usage_error(err_msg)
  endif

  inquire(file=trim(namelist_path), exist=exists)
  if(.not. exists) then
    write(err_msg, "(2A)") "Namelist file not found: ", trim(namelist_path)
    call report_usage_error(err_msg)
  endif

  ! Set the global debug level
  call set_debug_level(debug_level)

  call umPrint("Starting UKCA BOX_MODEL", src=prog_name)
  write(umMessage, "(2A)") "Reading namelist from: ", trim(namelist_path)
  call umPrint(umMessage, src=prog_name)

  if(debug_level > 0) then
    write(umMessage, "(A, I0)") "Debug level set to: ", debug_level
    call umPrint(umMessage, src=prog_name)
  endif

  call box_shell(trim(namelist_path))

  call umPrint("Finished UKCA BOX_MODEL", src=prog_name)

contains

  subroutine next_argument(i, value)

    !! Advance past an option and read its value, stopping with an error if
    !! the option is the last argument.

    !> Index of the option; on return, the index of its value
    integer, intent(inout) :: i
    !> The option's value
    character(len=256), intent(out) :: value
    !> The option itself, for the error message
    character(len=256) :: option

    call get_command_argument(i, option)
    if(i == command_argument_count()) then
      write(err_msg, "(2A)") trim(option), " option requires a value"
      call report_usage_error(err_msg)
    endif

    i = i + 1
    call get_command_argument(i, value)

  endsubroutine next_argument

  subroutine report_usage_error(message)

    !! Print the command line usage, then stop with an error.

    !> The error message
    character(len=*), intent(in) :: message

    call print_usage()
    err_code = box_errcode_command_line
    call ereport(prog_name, err_code, message)

  endsubroutine report_usage_error

  subroutine print_usage()

    !! Print the command line usage.

    call umPrint("Usage: ukca_box_model <namelist_file> [--debug <level>]", &
                 src=prog_name)
    call umPrint("The namelist's IO section names the other input files; "// &
                 "relative paths are relative to the namelist's folder.", &
                 src=prog_name)
    call umPrint("Debug levels: 0=off, 1=info, 2=detailed, 3=verbose", &
                 src=prog_name)

  endsubroutine print_usage

endprogram ukca_box_model_main
