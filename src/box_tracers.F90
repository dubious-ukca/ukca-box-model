module box_tracer_mod

  !! Module for handling tracer variables in the UKCA box model.

  use ukca_api_mod, only: ukca_maxlen_fieldname, ukca_get_tracer_varlist, &
                          ukca_maxlen_procname, ukca_maxlen_message
  use ereport_mod, only: ereport
  use umprintmgr, only: umMessage, umPrint
  use box_debug_mod, only: is_debug_level

  implicit none

  private

  public :: get_tracer_varnames, &
            create_initial_tracers, print_tracer_output, &
            initialise_output_tracers, &
            cleanup_tracers, add_tracers_to_output, &
            return_tracer, find_species_index

  !> Pointer to an array containing the names of the tracer variables.
  character(len=ukca_maxlen_fieldname), pointer, public, protected :: &
    tracer_varnames(:)
  !> Allocatable array to hold the values of the tracer variables. The
  !> dimensions are (row_length, rows, model_levels, num_tracers).
  real, allocatable, public :: tracer_ukca(:, :, :, :)
  !> Allocatable array to hold the output values of the tracer variables. The
  !> dimensions are (num_tracers, num_timesteps).
  real, allocatable, public, protected :: output_tracers(:, :)
  !> The module name for error reporting.
  character(len=*), parameter :: mod_name = "box_tracer_mod"
  !> The number of tracer variables.
  integer, public, protected :: num_tracers

contains

  subroutine get_tracer_varnames()

    !! Retrieve the list of tracer variable names from the UKCA API and store
    !! them in the tracer_varnames pointer.

    !> The error code returned by the UKCA API call.
    integer :: err_code
    !> Loop index
    integer :: i
    !> The error message for error reporting returned from
    !> ukca_get_tracer_varlist.
    character(len=ukca_maxlen_message) :: err_msg
    !> The routine name for error reporting returned from
    !> ukca_get_tracer_varlist.
    character(len=ukca_maxlen_procname) :: err_routine

    ! Initialise list pointer for safety
    nullify(tracer_varnames)

    ! Fetch tracer variable names from UKCA API
    call ukca_get_tracer_varlist(tracer_varnames, &
                                 err_code, &
                                 error_message=err_msg, &
                                 error_routine=err_routine)

    if(err_code /= 0) then
      call ereport(err_routine, err_code, err_msg)
    endif

    ! public variable
    num_tracers = size(tracer_varnames)

    if(is_debug_level(1)) then
      ! print out each available tracer
      do i = 1, size(tracer_varnames)
        write(umMessage, "(2A)") "Available tracer variable name: ", &
          tracer_varnames(i)
        call umPrint(umMessage, src=mod_name)
      enddo
    endif

  endsubroutine get_tracer_varnames

  subroutine create_initial_tracers(tracer_file)

    !! Create the initial tracer array from a provided tracer file.
    !!
    !! The tracer file should contain lines of the form: <var_name> <var_value>
    !!
    !! Where <var_name> is the name of the tracer variable and <var_value>
    !! is the initial value to set for that tracer. If a line with the
    !! variable name is "DEFAULT", then <var_value> will be used as the default
    !! value for any tracer variable not explicitly set in the file. If no
    !! "DEFAULT" line is provided, the default value will be set to 1.0e-10.

    use box_const_mod, only: row_length, rows, model_levels
    use box_err_codes_mod, only: box_errcode_io_tracer

    !> The name of the tracer file to read initial values from.
    character(len=*), intent(in) :: tracer_file
    !> Logical array to track which tracers have been provided in the tracer
    !> file.
    logical :: tracer_provided(num_tracers)
    !> The unit number for the file
    integer :: unit
    !> The I/O status for reading the file
    integer :: iostat_read
    !> The I/O status for opening the file
    integer :: iostat_open
    !> The I/O status for parsing the file
    integer :: iostat_parse
    !> A logical value indicating whether the file exists
    logical :: file_exists
    !> A logical value indicating whether the variable was found
    logical :: found
    !> The error message for error reporting
    character(len=ukca_maxlen_message) :: err_msg
    !> A line read from the file
    character(len=256) :: line
    !> The name of the variable read from the file
    character(len=256) :: var_name
    !> The value of the variable read from the file
    real :: var_value
    !> Tracer generic default
    real, parameter :: generic_default_value = 1.0e-10
    !> The default value to use for tracers not provided in the file.
    real :: default_value
    !> The index of the tracer variable in the tracer_varnames array
    integer :: species_index
    !> The routine name for error reporting
    character(len=ukca_maxlen_procname) :: routine_name
    !> The error code for error reporting
    integer :: err_code
    !> Loop index
    integer :: i

    routine_name = mod_name//":create_initial_tracers"

    default_value = generic_default_value
    species_index = 0
    iostat_read = 0
    iostat_open = 0
    iostat_parse = 0
    tracer_provided = .false.

    ! deallocate tracer array if already allocated
    if(allocated(tracer_ukca)) then
      deallocate(tracer_ukca)
    endif

    allocate(tracer_ukca(row_length, rows, model_levels, num_tracers))

    inquire(file=tracer_file, exist=file_exists)
    if(.not. file_exists) then
      write(err_msg, "(3A)") "Tracer file '", trim(tracer_file), &
        "' not found. Check box model configuration."
      err_code = box_errcode_io_tracer
      call ereport(routine_name, err_code, err_msg)
    endif

    open(newunit=unit, file=tracer_file, status='old', action='read', &
         iostat=iostat_open)

    if(iostat_open /= 0) then
      write(err_msg, "(3A)") "Error opening tracer file '", &
        trim(tracer_file), "'. Check box model configuration."
      err_code = box_errcode_io_tracer
      call ereport(routine_name, err_code, err_msg)
    endif

    ! read line by line of tracer file
    do
      read(unit, '(A)', iostat=iostat_read) line
      if(is_iostat_end(iostat_read)) then
        exit
      elseif(iostat_read /= 0) then
        write(err_msg, "(3A)") "Error reading tracer file '", &
          trim(tracer_file), "'."
        err_code = box_errcode_io_tracer
        call ereport(routine_name, err_code, err_msg)
      endif

      ! Skip blank lines or comments.
      if(len_trim(line) == 0 .or. line(1:1) == '#') cycle

      ! Read whitespace-separated tokens: <var_name> <var_value>
      read(line, *, iostat=iostat_parse) var_name, var_value
      if(iostat_parse /= 0) then
        write(err_msg, "(3A)") "Could not parse tracer line: '", trim(line), &
          "'."
        err_code = -box_errcode_io_tracer
        call ereport(routine_name, err_code, err_msg)
        cycle
      endif

      if(var_name == "DEFAULT") then
        default_value = var_value
        cycle
      endif

      ! Find the index of the tracer variable in the tracer_varnames array
      call find_species_index(var_name, species_index, found)

      if(found) then
        tracer_ukca(:, :, :, species_index) = var_value
        tracer_provided(species_index) = .true.

        write(umMessage, "(3A,E12.3E3,A)") "Set initial value of tracer '", &
          trim(var_name), "' to ", var_value, "."
        call umPrint(umMessage, src=mod_name)

      else
        write(err_msg, "(3A)") "Tracer variable '", trim(var_name), &
          "' in tracer file not found in needed tracer variable list."
        err_code = -box_errcode_io_tracer
        call ereport(routine_name, err_code, err_msg)
      endif
    enddo
    close(unit)

    ! now use default value for unset tracers and provide warning for any
    ! tracers not actively being set
    do i = 1, num_tracers
      if(.not. tracer_provided(i)) then
        tracer_ukca(:, :, :, i) = default_value
        write(err_msg, "(3A,(E12.3E3),A)") &
          "No value provided for tracer '", &
          trim(tracer_varnames(i)), "'. Setting to default value of ", &
          default_value, "."
        err_code = -box_errcode_io_tracer
        call ereport(routine_name, err_code, err_msg)
      endif
    enddo

  endsubroutine create_initial_tracers

  subroutine print_tracer_output()

    !! Subroutine to print the current tracer values to the log.

    !> Loop index
    integer :: i

    do i = 1, num_tracers
      write(umMessage, "(2A,E15.6E3)") trim(tracer_varnames(i)), ": ", &
        tracer_ukca(1, 1, 1, i)
      call umPrint(umMessage, src=mod_name)
    enddo

  endsubroutine print_tracer_output

  subroutine find_species_index(species_name, species_index, found)

    !! Subroutine to find the index of a species in the tracer variable name
    !! array. Returns the index and a logical indicating if the species was
    !! found. If multiple matches are found, an error is reported.

    use box_err_codes_mod, only: box_errcode_duplicate_species

    !> The name of the species to find.
    character(len=*), intent(in) :: species_name
    !> The index of the species in the tracer variable name array, if found. If
    !> not found, this will be set to -1.
    integer, intent(out) :: species_index
    !> Logical indicating if the species was found in the tracer variable name
    !> array.
    logical, intent(out) :: found
    !> Error code for error reporting
    integer :: err_code
    !> Error message for error reporting
    character(len=ukca_maxlen_message) :: err_msg
    !> Routine name for error reporting
    character(len=*), parameter :: routine_name = &
                                   mod_name//":find_species_index"
    !> Loop index
    integer :: i

    found = .false.
    species_index = -1

    do i = 1, num_tracers

      if(tracer_varnames(i) == species_name) then

        if(found) then
          write(err_msg, '(3A)') "Duplicate species '", trim(species_name), &
            "' found in tracer list."
          err_code = box_errcode_duplicate_species
          call ereport(routine_name, err_code, err_msg)
        endif

        species_index = i
        found = .true.

      endif
    enddo

  endsubroutine find_species_index

  subroutine initialise_output_tracers(num_timesteps)

    !! Subroutine to allocate the output tracer array based on the number of
    !! tracers and the number of timesteps in the model run.

    !> The number of timesteps in the model run.
    integer, intent(in) :: num_timesteps
    !> First time step
    integer, parameter :: first_timestep = 0

    if(allocated(output_tracers)) then
      deallocate(output_tracers)
    endif

    ! output tracers starts from timestep 0 to capture initial conditions
    allocate(output_tracers(num_tracers, 0:num_timesteps))

    ! set initial conditions at timestep 0
    call add_tracers_to_output(first_timestep)

  endsubroutine initialise_output_tracers

  subroutine add_tracers_to_output(timestep)

    !! Subroutine to add the current tracer values to the output array for a
    !! given timestep.

    use box_err_codes_mod, only: box_errcode_tracer_allocation

    !> The timestep for which to add the tracer values to the output array.
    integer, intent(in) :: timestep
    !> Error message for error reporting
    character(len=ukca_maxlen_message) :: err_msg
    !> Routine name for error reporting
    character(len=*), parameter :: routine_name = &
                                   mod_name//":add_tracers_to_output"
    !> Error code for error reporting
    integer :: err_code

    if(.not. allocated(output_tracers)) then
      write(err_msg, "(A)") "Output tracer array not allocated. Call "// &
        "initialise_output_tracers first."
      err_code = box_errcode_tracer_allocation
      call ereport(routine_name, err_code, err_msg)
    endif

    output_tracers(:, timestep) = tracer_ukca(1, 1, 1, :)

  endsubroutine add_tracers_to_output

  subroutine cleanup_tracers()

    !! Subroutine to deallocate the tracer arrays and nullify var name pointer.

    if(allocated(tracer_ukca)) then
      deallocate(tracer_ukca)
    endif

    if(allocated(output_tracers)) then
      deallocate(output_tracers)
    endif

    nullify(tracer_varnames)

  endsubroutine cleanup_tracers

  subroutine return_tracer(tracer_name, tracer)

    !! Subroutine to return the value of a tracer variable given its name.
    !! If not found the routine will error.

    use box_err_codes_mod, only: box_errcode_tracer_not_found

    !> The name of the tracer variable to return.
    character(len=*), intent(in) :: tracer_name
    !> The value of the tracer variable.
    real, intent(out) :: tracer
    !> Error code for error reporting
    integer :: err_code
    !> Species index in the tracer variable name array
    integer :: species_index
    !> Logical indicating if the species was found in the available tracers
    logical :: found
    !> Error message for error reporting
    character(len=ukca_maxlen_message) :: err_msg
    !> Routine name for error reporting
    character(len=*), parameter :: routine_name = &
                                   mod_name//":return_tracer"

    call find_species_index(tracer_name, species_index, found)

    if(found) then
      tracer = tracer_ukca(1, 1, 1, species_index)
    else
      write(err_msg, "(3A)") "Tracer '", trim(tracer_name), &
        "' not found in tracer variable list."
      err_code = box_errcode_tracer_not_found
      call ereport(routine_name, err_code, err_msg)
    endif

  endsubroutine return_tracer

endmodule box_tracer_mod
