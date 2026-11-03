module box_dump_mod

  !! Write every value passed into, or returned from, the UKCA library to a
  !! plain-text dump file, one value per line, so that two box models can be
  !! compared with `diff`.
  !!
  !! Each line is fully keyed and self-contained:
  !!
  !!     <step> <section> <name> <index> <value>
  !!
  !! e.g.
  !!
  !!     0 ukca_setup:in i_ukca_chem - 51
  !!     3 ukca_step:out tracers (1,1,1,2) 9.90333269774813254E-008 3E7A9C...
  !!
  !! so dumps can also be compared after `sort` if the two models make calls
  !! in a different order. A real value is written twice: with 17 significant
  !! digits, which round-trips a double exactly, and as the 16 hex digits of
  !! its bits. The hex makes the comparison bit-for-bit without relying on how
  !! the compiler converts reals to decimal, and shows how many bits differ.
  !!
  !! This module only depends on Fortran intrinsics and ereport_mod (which
  !! both the old and new box models have), so the same file can be compiled
  !! into the old (UM/FCM) box model unchanged.
  !!
  !! Usage:
  !!
  !!     call dump_open("ukca_dump.txt")
  !!     call dump_section("ukca_setup:in", 0)
  !!     call dump("i_ukca_chem", i_ukca_chem)
  !!     call dump("tracers", tracer_ukca)
  !!     call dump_close()
  !!
  !! All dump calls are no-ops while no dump file is open. Instead of calling
  !! dump_open directly, a driver (or wrapper) can call dump_open_from_env,
  !! which opens the file named by the environment variable UKCA_DUMP_FILE,
  !! if set, so dumping can be switched on without changing driver code.
  !!
  !! Optional arguments that are not present, and allocatable arguments that
  !! are not allocated, are recorded with dump_marker as "<absent>" and
  !! "<unallocated>" so that differences in what is passed are also visible.

  use, intrinsic :: iso_fortran_env, only: int64
  use ereport_mod, only: ereport

  implicit none

  private

  public :: dump_open
  public :: dump_open_from_env
  public :: dump_marker
  public :: dump_close
  public :: dump_is_open
  public :: dump_section
  public :: dump

  !> Write one variable (any supported type and rank) to the dump file
  interface dump
    procedure dump_real_0d, dump_real_1d, dump_real_2d, &
      dump_real_3d, dump_real_4d
    procedure dump_int_0d, dump_int_1d, dump_int_2d, dump_int_3d
    procedure dump_logical_0d, dump_logical_1d, dump_logical_2d, &
      dump_logical_3d
    procedure dump_char_0d, dump_char_1d
  endinterface dump

  !> Module name for error reporting
  character(len=*), parameter :: mod_name = "box_dump_mod"
  !> Error code for failing to open the dump file. A literal, as the old box
  !> model has no box_err_codes_mod.
  integer, parameter :: errcode_dump_open = 1

  !> Minimum width the variable name is padded to, for readability only
  integer, parameter :: name_width = 32
  !> Format for real values: 17 significant digits round-trips a double
  character(len=*), parameter :: real_fmt = "(ES25.17E3)"

  !> Environment variable naming the dump file, see dump_open_from_env
  character(len=*), parameter :: dump_env_var = "UKCA_DUMP_FILE"

  !> Unit of the open dump file, or -1 when no dump file is open
  integer :: dump_unit = -1
  !> Whether dump_open_from_env has already checked the environment variable
  logical :: env_checked = .false.
  !> Time step written at the start of each line, set by dump_section
  integer :: current_step = 0
  !> Section label written on each line, set by dump_section
  character(len=64) :: current_section = "unset"

contains

  subroutine dump_open(filename)

    !! Open (replacing) the dump file. Dumping is active until dump_close.

    !> Path to the dump file
    character(len=*), intent(in) :: filename
    !> I/O status from opening the file
    integer :: iostat
    !> I/O message from opening the file
    character(len=256) :: iomsg
    !> Error code for error reporting
    integer :: err_code
    !> Message for error reporting
    character(len=512) :: err_msg

    if(dump_unit /= -1) call dump_close()

    open(newunit=dump_unit, file=filename, status="replace", &
         action="write", iostat=iostat, iomsg=iomsg)
    if(iostat /= 0) then
      write(err_msg, "(4A)") "Cannot open dump file '", trim(filename), &
        "': ", trim(iomsg)
      err_code = errcode_dump_open
      call ereport(mod_name//":dump_open", err_code, err_msg)
    endif

    write(dump_unit, "(A)") "# step section name index value [hex]"

  endsubroutine dump_open

  subroutine dump_open_from_env()

    !! Open the dump file named by the environment variable UKCA_DUMP_FILE,
    !! if it is set and non-empty. Only the first call has any effect, so it
    !! is cheap to call at the start of every wrapped API routine.

    !> Length of the environment variable's value
    integer :: length
    !> Status from reading the environment variable
    integer :: status
    !> Path to the dump file, from the environment variable
    character(len=:), allocatable :: filename

    if(env_checked) return
    env_checked = .true.

    call get_environment_variable(dump_env_var, length=length, status=status)
    if(status /= 0 .or. length == 0) return

    allocate(character(len=length) :: filename)
    call get_environment_variable(dump_env_var, value=filename)
    call dump_open(filename)

  endsubroutine dump_open_from_env

  subroutine dump_close()

    !! Close the dump file, if open.

    if(dump_unit == -1) return
    close(dump_unit)
    dump_unit = -1

  endsubroutine dump_close

  function dump_is_open() result(is_open)

    !! True if a dump file is open, i.e. dump calls will write output.

    !> Whether a dump file is open
    logical :: is_open

    is_open = (dump_unit /= -1)

  endfunction dump_is_open

  subroutine dump_section(section, step)

    !! Set the section label (e.g. "ukca_step:in") and timestep used to key
    !! subsequent lines. Flushes the file so a crash leaves a usable dump.

    !> Section label, e.g. "ukca_step:in"
    character(len=*), intent(in) :: section
    !> Time step
    integer, intent(in) :: step

    current_section = section
    current_step = step
    if(dump_unit /= -1) flush(dump_unit)

  endsubroutine dump_section

  subroutine dump_marker(name, marker)

    !! Write a marker in place of a value, e.g. "<absent>" for an optional
    !! argument that was not passed.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> Marker to write in place of the value
    character(len=*), intent(in) :: marker

    if(dump_unit == -1) return
    call write_line(name, "-", marker)

  endsubroutine dump_marker

  subroutine write_line(name, idx, value)

    !! Write one dump line: step, section, name, index and value.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> Index of the element, e.g. "(1,1,2)", or "-" for a scalar
    character(len=*), intent(in) :: idx
    !> The value as text
    character(len=*), intent(in) :: value
    !> The step as text
    character(len=24) :: step_str

    write(step_str, "(I0)") current_step
    write(dump_unit, "(A)") trim(step_str)//" "// &
      trim(current_section)//" "//pad(name)//" "//idx//" "// &
      trim(adjustl(value))

  endsubroutine write_line

  function pad(name) result(padded)

    !! Pad a variable name to at least name_width characters.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The padded name
    character(len=max(name_width, len(name))) :: padded

    padded = name

  endfunction pad

  function real_str(value) result(str)

    !! Full-precision text for a real: the value to 17 significant digits,
    !! then the 16 hex digits of its bits. A NaN is written as "NaN:" and its
    !! bits, detected from the bit pattern (comparisons on a signalling NaN
    !! would trip -ffpe-trap=invalid).

    !> The value to convert
    real, intent(in) :: value
    !> The value as text
    character(len=48) :: str
    !> The bits of the value
    integer(int64) :: bits
    !> Mask for the exponent bits of a double
    integer(int64), parameter :: exp_mask = int(z"7FF0000000000000", int64)
    !> Mask for the mantissa bits of a double
    integer(int64), parameter :: man_mask = int(z"000FFFFFFFFFFFFF", int64)

    if(storage_size(value) /= 64) then
      ! hex is only written for a double; the decimal is exact for any real
      write(str, real_fmt) value
      return
    endif

    bits = transfer(value, bits)
    if(iand(bits, exp_mask) == exp_mask .and. &
       iand(bits, man_mask) /= 0_int64) then
      write(str, "(A, Z16.16)") "NaN:", bits
    else
      write(str, "("//real_fmt(2:len(real_fmt) - 1)//", 1X, Z16.16)") &
        value, bits
    endif

  endfunction real_str

  function int_str(value) result(str)

    !! Text for an integer.

    !> The value to convert
    integer, intent(in) :: value
    !> The value as text
    character(len=24) :: str

    write(str, "(I0)") value

  endfunction int_str

  function logical_str(value) result(str)

    !! Text for a logical: "T" or "F".

    !> The value to convert
    logical, intent(in) :: value
    !> The value as text
    character(len=1) :: str

    str = merge("T", "F", value)

  endfunction logical_str

  function idx1(i) result(str)

    !! Text for a 1D index, e.g. "(3)".

    !> First index
    integer, intent(in) :: i
    !> The index as text
    character(len=64) :: str

    str = "("//trim(int_str(i))//")"

  endfunction idx1

  function idx2(i, j) result(str)

    !! Text for a 2D index, e.g. "(1,3)".

    !> First index
    integer, intent(in) :: i
    !> Second index
    integer, intent(in) :: j
    !> The index as text
    character(len=64) :: str

    str = "("//trim(int_str(i))//","//trim(int_str(j))//")"

  endfunction idx2

  function idx3(i, j, k) result(str)

    !! Text for a 3D index, e.g. "(1,1,3)".

    !> First index
    integer, intent(in) :: i
    !> Second index
    integer, intent(in) :: j
    !> Third index
    integer, intent(in) :: k
    !> The index as text
    character(len=64) :: str

    str = "("//trim(int_str(i))//","//trim(int_str(j))//","// &
          trim(int_str(k))//")"

  endfunction idx3

  function idx4(i, j, k, l) result(str)

    !! Text for a 4D index, e.g. "(1,1,1,3)".

    !> First index
    integer, intent(in) :: i
    !> Second index
    integer, intent(in) :: j
    !> Third index
    integer, intent(in) :: k
    !> Fourth index
    integer, intent(in) :: l
    !> The index as text
    character(len=100) :: str

    str = "("//trim(int_str(i))//","//trim(int_str(j))//","// &
          trim(int_str(k))//","//trim(int_str(l))//")"

  endfunction idx4

  ! Specific procedures for the generic dump interface. Array elements are
  ! written in Fortran (column-major) order with 1-based indices.

  subroutine dump_real_0d(name, value)

    !! Dump a real scalar.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The value to dump
    real, intent(in) :: value

    if(dump_unit == -1) return
    call write_line(name, "-", real_str(value))

  endsubroutine dump_real_0d

  subroutine dump_real_1d(name, value)

    !! Dump a 1D real array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    real, intent(in) :: value(:)
    !> Loop index
    integer :: i

    if(dump_unit == -1) return
    do i = 1, size(value, 1)
      call write_line(name, trim(idx1(i)), real_str(value(i)))
    enddo

  endsubroutine dump_real_1d

  subroutine dump_real_2d(name, value)

    !! Dump a 2D real array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    real, intent(in) :: value(:, :)
    !> Loop index, first dimension
    integer :: i
    !> Loop index, second dimension
    integer :: j

    if(dump_unit == -1) return
    do j = 1, size(value, 2)
      do i = 1, size(value, 1)
        call write_line(name, trim(idx2(i, j)), real_str(value(i, j)))
      enddo
    enddo

  endsubroutine dump_real_2d

  subroutine dump_real_3d(name, value)

    !! Dump a 3D real array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    real, intent(in) :: value(:, :, :)
    !> Loop index, first dimension
    integer :: i
    !> Loop index, second dimension
    integer :: j
    !> Loop index, third dimension
    integer :: k

    if(dump_unit == -1) return
    do k = 1, size(value, 3)
      do j = 1, size(value, 2)
        do i = 1, size(value, 1)
          call write_line(name, trim(idx3(i, j, k)), &
                          real_str(value(i, j, k)))
        enddo
      enddo
    enddo

  endsubroutine dump_real_3d

  subroutine dump_real_4d(name, value)

    !! Dump a 4D real array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    real, intent(in) :: value(:, :, :, :)
    !> Loop index, first dimension
    integer :: i
    !> Loop index, second dimension
    integer :: j
    !> Loop index, third dimension
    integer :: k
    !> Loop index, fourth dimension
    integer :: l

    if(dump_unit == -1) return
    do l = 1, size(value, 4)
      do k = 1, size(value, 3)
        do j = 1, size(value, 2)
          do i = 1, size(value, 1)
            call write_line(name, trim(idx4(i, j, k, l)), &
                            real_str(value(i, j, k, l)))
          enddo
        enddo
      enddo
    enddo

  endsubroutine dump_real_4d

  subroutine dump_int_0d(name, value)

    !! Dump an integer scalar.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The value to dump
    integer, intent(in) :: value

    if(dump_unit == -1) return
    call write_line(name, "-", int_str(value))

  endsubroutine dump_int_0d

  subroutine dump_int_1d(name, value)

    !! Dump a 1D integer array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    integer, intent(in) :: value(:)
    !> Loop index
    integer :: i

    if(dump_unit == -1) return
    do i = 1, size(value, 1)
      call write_line(name, trim(idx1(i)), int_str(value(i)))
    enddo

  endsubroutine dump_int_1d

  subroutine dump_int_2d(name, value)

    !! Dump a 2D integer array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    integer, intent(in) :: value(:, :)
    !> Loop index, first dimension
    integer :: i
    !> Loop index, second dimension
    integer :: j

    if(dump_unit == -1) return
    do j = 1, size(value, 2)
      do i = 1, size(value, 1)
        call write_line(name, trim(idx2(i, j)), int_str(value(i, j)))
      enddo
    enddo

  endsubroutine dump_int_2d

  subroutine dump_int_3d(name, value)

    !! Dump a 3D integer array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    integer, intent(in) :: value(:, :, :)
    !> Loop index, first dimension
    integer :: i
    !> Loop index, second dimension
    integer :: j
    !> Loop index, third dimension
    integer :: k

    if(dump_unit == -1) return
    do k = 1, size(value, 3)
      do j = 1, size(value, 2)
        do i = 1, size(value, 1)
          call write_line(name, trim(idx3(i, j, k)), &
                          int_str(value(i, j, k)))
        enddo
      enddo
    enddo

  endsubroutine dump_int_3d

  subroutine dump_logical_0d(name, value)

    !! Dump a logical scalar.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The value to dump
    logical, intent(in) :: value

    if(dump_unit == -1) return
    call write_line(name, "-", logical_str(value))

  endsubroutine dump_logical_0d

  subroutine dump_logical_1d(name, value)

    !! Dump a 1D logical array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    logical, intent(in) :: value(:)
    !> Loop index
    integer :: i

    if(dump_unit == -1) return
    do i = 1, size(value, 1)
      call write_line(name, trim(idx1(i)), logical_str(value(i)))
    enddo

  endsubroutine dump_logical_1d

  subroutine dump_logical_2d(name, value)

    !! Dump a 2D logical array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    logical, intent(in) :: value(:, :)
    !> Loop index, first dimension
    integer :: i
    !> Loop index, second dimension
    integer :: j

    if(dump_unit == -1) return
    do j = 1, size(value, 2)
      do i = 1, size(value, 1)
        call write_line(name, trim(idx2(i, j)), logical_str(value(i, j)))
      enddo
    enddo

  endsubroutine dump_logical_2d

  subroutine dump_logical_3d(name, value)

    !! Dump a 3D logical array.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    logical, intent(in) :: value(:, :, :)
    !> Loop index, first dimension
    integer :: i
    !> Loop index, second dimension
    integer :: j
    !> Loop index, third dimension
    integer :: k

    if(dump_unit == -1) return
    do k = 1, size(value, 3)
      do j = 1, size(value, 2)
        do i = 1, size(value, 1)
          call write_line(name, trim(idx3(i, j, k)), &
                          logical_str(value(i, j, k)))
        enddo
      enddo
    enddo

  endsubroutine dump_logical_3d

  subroutine dump_char_0d(name, value)

    !! Dump a character scalar, in double quotes.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The value to dump
    character(len=*), intent(in) :: value

    if(dump_unit == -1) return
    call write_line(name, "-", '"'//trim(value)//'"')

  endsubroutine dump_char_0d

  subroutine dump_char_1d(name, value)

    !! Dump a 1D character array, each value in double quotes.

    !> Name of the variable
    character(len=*), intent(in) :: name
    !> The values to dump
    character(len=*), intent(in) :: value(:)
    !> Loop index
    integer :: i

    if(dump_unit == -1) return
    do i = 1, size(value, 1)
      call write_line(name, trim(idx1(i)), '"'//trim(value(i))//'"')
    enddo

  endsubroutine dump_char_1d

endmodule box_dump_mod
