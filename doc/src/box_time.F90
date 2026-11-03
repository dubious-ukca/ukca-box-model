module box_time_mod

  !! Module for managing the time in the UKCA box model.

  use umprintmgr, only: umMessage, umPrint
  use ereport_mod, only: ereport
  use ukca_api_mod, only: ukca_maxlen_procname, ukca_maxlen_message
  use box_err_codes_mod, only: box_errcode_invalid_time

  implicit none

  private

  ! public procedures
  public :: box_time_initialise
  public :: box_time_advance
  public :: print_date_time
  public :: day_time_list_format
  public :: get_time_midpoint

  !> Module name for error reporting
  character(len=*), parameter :: mod_name = "box_time_mod"

  !> Array of month names
  character(len=9), parameter :: month_strs(12) = [ &
                                 "January  ", &
                                 "February ", &
                                 "March    ", &
                                 "April    ", &
                                 "May      ", &
                                 "June     ", &
                                 "July     ", &
                                 "August   ", &
                                 "September", &
                                 "October  ", &
                                 "November ", &
                                 "December "]

  !> Model duration (seconds)
  integer, public, protected :: model_duration
  !> Total number of time steps
  integer, public, protected :: n_steps
  !> The duration of a time step in seconds of the model
  integer, public, protected :: time_step
  !> Index of the current time step (starts at 1)
  integer, public, protected :: current_step
  !> Elapsed model time (seconds)
  integer, public, protected :: current_time
  !> Logical to determine if the model is using a 360-day calendar
  logical, public, protected :: l_cal360

  !> Type for storing date and time information
  type, public :: box_date_time
    !> Year
    integer :: year
    !> Month
    integer :: month
    !> Day
    integer :: day
    !> Hour
    integer :: hour
    !> Minute
    integer :: minute
    !> Seconds
    integer :: second
  endtype box_date_time

  !> Model initial date and time
  type(box_date_time), public, protected :: initial_date_time
  !> Model current date and time
  type(box_date_time), public, protected :: current_date_time
  !> Previous date and time
  type(box_date_time), public, protected :: previous_date_time

contains

  subroutine box_time_initialise(time_step_nml, &
                                 model_duration_nml, &
                                 start_year, start_month, start_day, &
                                 start_hour, start_minute, &
                                 start_second, l_360)

    !! Initialize the time manager with the time step, model duration and the
    !! model start date and time from the configuration namelist. Current time
    !! and step are set to 0.

    !> Time step from configuration namelist (seconds)
    integer, intent(in) :: time_step_nml
    !> Model duration from configuration namelist (seconds)
    integer, intent(in) :: model_duration_nml
    !> Model start year
    integer, intent(in) :: start_year
    !> Model start month
    integer, intent(in) :: start_month
    !> Model start day
    integer, intent(in) :: start_day
    !> Model start hour
    integer, intent(in) :: start_hour
    !> Model start minute
    integer, intent(in) :: start_minute
    !> Model start second
    integer, intent(in) :: start_second
    !> Logical indicating if the model is using a 360-day calendar
    logical, intent(in) :: l_360

    !> Error code for error reporting
    integer :: err_code
    !> Final model time step
    integer :: final_model_time
    !> Name of routine for error reporting
    character(len=*), parameter :: routine_name = mod_name// &
                                   ":box_time_initialise"
    !> Error message for error reporting
    character(len=ukca_maxlen_message) :: err_msg

    ! Set the module level logical based upon the input logical for 360 day
    l_cal360 = l_360

    ! prevent negative time step or model duration
    if(time_step_nml <= 0) then
      write(err_msg, "(A,I0,A)") "Invalid time step: ", time_step_nml, &
        ". Must be a positive integer."
      err_code = box_errcode_invalid_time
      call ereport(routine_name=routine_name, error_status=err_code, &
                   message=err_msg)
    endif

    if(model_duration_nml <= 0) then
      write(err_msg, "(A,I0,A)") "Invalid model duration: ", &
        model_duration_nml, ". Must be a positive integer."
      err_code = box_errcode_invalid_time
      call ereport(routine_name=routine_name, error_status=err_code, &
                   message=err_msg)
    endif

    time_step = time_step_nml
    model_duration = model_duration_nml

    ! Calculate the number of required  time steps and calculate the final
    ! model time which may be different to the requested model duration if the
    ! requested model duration is not an exact multiple of the time step
    n_steps = model_duration / time_step_nml
    final_model_time = n_steps * time_step

    ! print to user number of time steps
    write(umMessage, "(A,I0,A)") "Model duration: ", model_duration, &
      " seconds."
    call umPrint(umMessage, src=routine_name)
    write(umMessage, "(A,I0,A)") "Time step: ", time_step, " seconds."
    call umPrint(umMessage, src=routine_name)
    write(umMessage, "(A,I0)") "Number of time steps: ", n_steps
    call umPrint(umMessage, src=routine_name)

    if(final_model_time /= model_duration) then
      write(umMessage, "(A,A,I0,A)") "Requested model duration is not an ", &
        "exact multiple of the time step. Final simulated time will be ", &
        final_model_time, " seconds."
      call umPrint(umMessage, src=routine_name)
    endif

    ! do checks on input start parameters
    if(start_month < 1 .or. start_month > 12) then
      write(err_msg, "(A,I0,A)") "Invalid start month: ", start_month, &
        ". Must be between 1 and 12."
      err_code = box_errcode_invalid_time
      call ereport(routine_name=routine_name, error_status=err_code, &
                   message=err_msg)
    endif

    if(start_day < 1 .or. start_day > &
       days_in_month(start_year, start_month)) then
      write(err_msg, "(A,I0,A,I0,3A,I0,A)") &
        "Invalid start day: ", &
        start_day, &
        ". Must be between 1 and ", &
        days_in_month(start_year, start_month), &
        " for the month of ", &
        trim(month_strs(start_month)), &
        " in year ", &
        start_year, &
        "."
      err_code = box_errcode_invalid_time
      call ereport(routine_name=routine_name, error_status=err_code, &
                   message=err_msg)
    endif

    if(start_hour < 0 .or. start_hour > 23) then
      write(err_msg, "(A,I0,A)") "Invalid start hour: ", start_hour, &
        ". Must be between 0 and 23."
      err_code = box_errcode_invalid_time
      call ereport(routine_name=routine_name, error_status=err_code, &
                   message=err_msg)
    endif

    if(start_minute < 0 .or. start_minute > 59) then
      write(err_msg, "(A,I0,A)") "Invalid start minute: ", start_minute, &
        ". Must be between 0 and 59."
      err_code = box_errcode_invalid_time
      call ereport(routine_name=routine_name, error_status=err_code, &
                   message=err_msg)
    endif

    if(start_second < 0 .or. start_second > 59) then
      write(err_msg, "(A,I0,A)") "Invalid start second: ", start_second, &
        ". Must be between 0 and 59."
      err_code = box_errcode_invalid_time
      call ereport(routine_name=routine_name, error_status=err_code, &
                   message=err_msg)
    endif

    ! initialise current step and time
    initial_date_time%year = start_year
    initial_date_time%month = start_month
    initial_date_time%day = start_day
    initial_date_time%hour = start_hour
    initial_date_time%minute = start_minute
    initial_date_time%second = start_second

    ! model start so current time == initial time
    current_date_time = initial_date_time
    previous_date_time = initial_date_time

    current_step = 0
    current_time = 0

    ! print initial date and time
    call print_date_time(current_date_time)

  endsubroutine box_time_initialise

  subroutine print_date_time(date_time)

    !! Print the current model date and time in a human-readable format.

    !> Date and time info to print
    type(box_date_time), intent(in) :: date_time
    !> Str representation of the date and time for printing
    character(len=30) :: date_time_str
    !> Routine name for printing
    character(len=ukca_maxlen_procname), parameter :: &
      routine_name = mod_name//":print_date_time"

    write(date_time_str, "(I4.4,'-', A,'-',I2.2,' ',I2.2,':',I2.2,':',I2.2)") &
      date_time%year, trim(month_strs(date_time%month)), date_time%day, &
      date_time%hour, date_time%minute, date_time%second

    write(umMessage, "(2A)") "Current model date and time: ", &
      trim(date_time_str)
    call umPrint(umMessage, src=routine_name)

  endsubroutine print_date_time

  subroutine box_time_advance(step_num)

    !! Advance the model time by the current time step and increment the index.
    !! If all time steps have been completed, an error is reported as this
    !! should not occur.

    use box_err_codes_mod, only: box_errcode_internal

    !> The step number to advance to (should be current_step + 1)
    integer, intent(in) :: step_num

    !> Routine name for printing
    character(len=ukca_maxlen_procname), parameter :: &
      routine_name = mod_name//":box_time_advance"
    !> Error code for reporting
    integer :: err_code
    !> Error message for reporting
    character(len=ukca_maxlen_message) :: err_msg

    if(step_num /= current_step + 1) then
      write(err_msg, "(A,I0,A,I0)") "Time step ", step_num, &
        " is not the next time step. Current time step is ", current_step
      err_code = box_errcode_internal
      call ereport(routine_name, err_code, err_msg)
    endif

    ! Advance the model time by an increment.
    current_step = step_num

    if(current_step > n_steps) then
      write(err_msg, "(A,I0,A,I0)") "Time step ", current_step, &
        " is outside the run: 1 to ", n_steps
      err_code = box_errcode_internal
      call ereport(routine_name, err_code, err_msg)

    endif

    ! hold the previous timestep - needed for input to ukca
    previous_date_time = current_date_time

    current_time = current_step * time_step

    ! add the current time which is total seconds since start to the initial
    ! date and time to get the current date and time
    current_date_time = add_seconds(initial_date_time, current_time)

    ! print out the current time for the user
    call print_date_time(current_date_time)

  endsubroutine box_time_advance

  function add_seconds(date_time, seconds) result(new_date_time)

    !! Add a non-negative number of seconds to a date and time to produce a
    !! new date_time object. Will account for leap years and 360 day calendar
    !! if l_cal360 (module variable) is true

    !> The input date and time object
    type(box_date_time), intent(in) :: date_time
    !> The number of seconds to add
    integer, intent(in) :: seconds
    !> The resultant date and time object
    type(box_date_time) :: new_date_time
    !> The number of seconds in a day
    integer, parameter :: sec_in_day = 86400
    !> The number of seconds in an hour
    integer, parameter :: sec_in_hour = 3600
    !> The number of seconds in a minute
    integer, parameter :: sec_in_minute = 60
    !> The total number of seconds in the input date and time plus the seconds
    integer :: total

    ! the output datetime
    new_date_time = date_time

    total = date_time%hour * sec_in_hour + date_time%minute * sec_in_minute &
            + date_time%second + seconds

    ! update the hour, minute and second based on the total number of seconds
    ! note values are integers so the division will be integer division
    new_date_time%hour = mod(total, sec_in_day) / sec_in_hour
    new_date_time%minute = mod(total, sec_in_hour) / sec_in_minute
    new_date_time%second = mod(total, sec_in_minute)
    new_date_time%day = date_time%day + total / sec_in_day

    ! update the month and year based on the new day value
    do while(new_date_time%day > &
             days_in_month(new_date_time%year, new_date_time%month))

      new_date_time%day = &
        new_date_time%day - &
        days_in_month(new_date_time%year, new_date_time%month)

      ! advance a month
      new_date_time%month = new_date_time%month + 1
      ! advance a year if the month exceeds 12
      if(new_date_time%month > 12) then
        new_date_time%month = 1
        new_date_time%year = new_date_time%year + 1
      endif
    enddo
  endfunction add_seconds

  subroutine get_time_midpoint(time, timestep, midpoint)

    !! Get the midpoint between two time steps.

    ! TODO - ask Luke why photolysis goes to the previous midpoint rather than
    ! the current midpoint

    !> The input date and time object
    type(box_date_time), intent(in) :: time
    !> The time step size (seconds)
    integer, intent(in) :: timestep
    !> The output midpoint date and time object
    type(box_date_time), intent(out) :: midpoint

    midpoint = add_seconds(time, timestep / 2)

  endsubroutine get_time_midpoint

  function days_in_month(year, month) result(days)

    !! Return the number of days in a given month, taking into account leap
    !! years. Will account for 360 day calendar if l_cal360 (module variable)
    !! is true.

    !> The input year
    integer, intent(in) :: year
    !> The input month
    integer, intent(in) :: month
    !> The number of days in the year and month
    integer :: days
    !> The number of days in each month for a normal year
    integer, parameter :: normal_days_in_month(12) = [31, 28, 31, 30, 31, 30, &
                                                      31, 31, 30, 31, 30, 31]
    if(l_cal360) then
      days = 30
    else
      if(month /= 2) then
        days = normal_days_in_month(month)
      else
        days = 28
        if(mod(year, 4) == 0 .and. (mod(year, 100) /= 0 .or. &
                                    mod(year, 400) == 0)) then
          days = 29
        endif
      endif
    endif

  endfunction days_in_month

  function calc_day_of_year(year, month, day) result(day_of_year)

    !! Calculate the day number of the year for a given year, month and day.
    !! Will account for 360 day calendar if l_cal360 (module variable) is true.

    !> The input year
    integer, intent(in) :: year
    !> The input month
    integer, intent(in) :: month
    !> The input day
    integer, intent(in) :: day
    !> The calculated day number of the year
    integer :: day_of_year
    !> Month index
    integer :: m

    day_of_year = 0
    do m = 1, month - 1
      day_of_year = day_of_year + days_in_month(year, m)
    enddo
    day_of_year = day_of_year + day

  endfunction calc_day_of_year

  function day_time_list_format(date_time) result(day_time_list)

    !! Format a box_date_time object into a list of integers representing:
    !! - [year, month, day, hour, minute, second and day of year]

    !> The input date and time object
    type(box_date_time), intent(in) :: date_time
    !> The output list of integers
    integer :: day_time_list(7)

    day_time_list(1) = date_time%year
    day_time_list(2) = date_time%month
    day_time_list(3) = date_time%day
    day_time_list(4) = date_time%hour
    day_time_list(5) = date_time%minute
    day_time_list(6) = date_time%second
    ! will account of 360 day calendar if l_cal360 (module variable) is true
    day_time_list(7) = calc_day_of_year(date_time%year, date_time%month, &
                                        date_time%day)

  endfunction day_time_list_format

endmodule box_time_mod
