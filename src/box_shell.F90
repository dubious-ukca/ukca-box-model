module box_shell_mod

  !! Module holding the box model driver: it reads the box config and inputs,
  !! sets up UKCA, then runs UKCA for each time step and writes the output.

  use umprintmgr, only: umMessage, umPrint
  use ereport_mod, only: ereport

  implicit none

  private

  public :: box_shell

  !> Module name for logging and error reporting
  character(len=*), parameter :: mod_name = "box_shell_mod"

contains

  subroutine box_shell(namelist_path)

    !! Run the box model: read the box config namelist and the input files it
    !! names, set up UKCA and photolysis, then step UKCA through the model
    !! duration and write the tracer output.

    use box_config_mod, only: read_box_config, box_config_type, &
                              print_box_config, output_file_path
    use box_jules_mod, only: setup_jules

    use box_internal_ukca_config_mod, only: setup_internal_ukca_config, &
                                            read_internal_ukca_config

    use box_environment_mod, &
      only: box_environment_type, &
            read_box_environment_nml, &
            print_box_environment, set_box_environment, &
            derive_env_variables, print_ukca_environment, &
            update_env_from_tracers, update_tracer_from_env

    use box_tracer_mod, only: create_initial_tracers, &
                              get_tracer_varnames, &
                              tracer_ukca, print_tracer_output, &
                              initialise_output_tracers, &
                              cleanup_tracers, add_tracers_to_output

    use box_ntp_mod, only: get_ntp_varnames, ntp_ukca, create_initial_ntp

    use box_time_mod, only: box_time_initialise, &
                            box_time_advance, n_steps, &
                            day_time_list_format, &
                            current_date_time, &
                            previous_date_time

    use ukca_api_mod, only: ukca_step, &
                            ukca_maxlen_message, ukca_maxlen_procname

    use box_io_mod, only: write_tracer_output

    use box_photol_mod, only: box_photol_setup, photol_get_rates, &
                              update_solar_pos, get_photol_reaction_data

    use box_debug_mod, only: is_debug_level

    use box_config_validator_mod, only: validate_config

    use ukca_internal_dump_mod, only: ukca_dump_on, &
                                      dump_ukca_internal_config, &
                                      dump_ukca_step_in, dump_ukca_step_out

    !> Path to the box config namelist, which names the other input files
    character(len=*), intent(in) :: namelist_path

    !> Error message returned by ukca_step
    character(len=ukca_maxlen_message) :: error_message
    !> Routine reporting the error, returned by ukca_step
    character(len=ukca_maxlen_procname) :: error_routine
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: err_msg

    !> The box model configuration, read from the box config namelist
    type(box_config_type) :: cfg
    !> The box model environment, read from the environment namelist
    type(box_environment_type) :: env

    !> Error code returned by ukca_step
    integer :: err_code
    !> Time step index
    integer :: t
    !> Current model date and time, as the 7-element list UKCA expects
    integer :: current_date_time_list(7)
    !> Previous model date and time, as the 7-element list UKCA expects
    integer :: previous_date_time_list(7)

    ! initialise variables
    err_code = 0
    current_date_time_list = -1
    previous_date_time_list = -1

    call umPrint("Starting UKCA shell", src=mod_name)

    call read_box_config(namelist_path, cfg)

    call umPrint("Successfully read box config namelist", src=mod_name)

    ! perform checks on input configuration
    call validate_config(cfg)

    call print_box_config(cfg)

    ! call jules setup to initialise land surface type indices
    call setup_jules(cfg%ntype)

    ! setup photolysis
    call box_photol_setup(cfg)

    ! set up UKCA's internal configuration from the box config
    call setup_internal_ukca_config(cfg)

    if(ukca_dump_on()) call dump_ukca_internal_config()

    ! set options from ukca internal configuration
    call read_internal_ukca_config()

    ! get photolysis
    call get_photol_reaction_data()

    ! TODO - need to write a checker of internal ukca config vs the namelist
    ! config - check specific values match

    ! Read in the environment
    write(umMessage, "(2A)") "Reading environment from: ", &
      trim(cfg%environment_data_file)
    call umPrint(umMessage, src=mod_name)
    call read_box_environment_nml(trim(cfg%environment_data_file), env)

    ! derive the environment variables from the namelist values, e.g. calculate
    ! the solar declination and equation of time from the date and time
    call derive_env_variables(env)

    ! print the environment out - there will be NaN values for unset env
    ! variables
    if(is_debug_level(1)) then
      call print_box_environment(env)
    endif

    ! generate the tracer variable list based upon the model configuration
    call get_tracer_varnames()

    ! create initial tracer array from input file
    write(umMessage, "(2A)") "Reading initial tracers from: ", &
      trim(cfg%initial_tracer_file)
    call umPrint(umMessage, src=mod_name)
    call create_initial_tracers(trim(cfg%initial_tracer_file))

    ! generate the non-transported prognostic variable list based upon the
    ! model configuration
    call get_ntp_varnames()

    ! create initial non-transported prognostic variable array from input file
    write(umMessage, "(2A)") "Reading initial ntp from: ", &
      trim(cfg%initial_ntp_file)
    call umPrint(umMessage, src=mod_name)
    call create_initial_ntp(trim(cfg%initial_ntp_file))

    ! need to set up time here
    call box_time_initialise(cfg%chem_timestep, &
                             cfg%model_duration, &
                             cfg%start_year, cfg%start_month, &
                             cfg%start_day, cfg%start_hour, &
                             cfg%start_minute, cfg%start_second, &
                             cfg%l_cal360)

    call initialise_output_tracers(n_steps)

    ! Print the initial tracer output, which will be the initial conditions
    call print_tracer_output()

    do t = 1, n_steps
      call box_time_advance(t)

      ! env sin_declination and equation_of_time recalculated here
      call update_solar_pos(env)

      ! get photolysis rates either from file (offline) or by running scheme
      call photol_get_rates(cfg, env)

      ! a call to set the internal ukca environment from the box environment
      call set_box_environment(env)

      ! the environment's q is the master copy of water vapour, as in the UM:
      ! UKCA's H2O tracer (if it has one) is reset from q before every step.
      ! With l_ukca_h2o_feedback, q is updated from H2O after the step.
      call update_tracer_from_env(tracer_ukca, env%q, "H2O")

      ! print out the internal ukca environment
      if(is_debug_level(1)) then
        call print_ukca_environment()
      endif

      current_date_time_list = day_time_list_format(current_date_time)
      previous_date_time_list = day_time_list_format(previous_date_time)

      if(ukca_dump_on()) then
        call dump_ukca_step_in(t, &
                               current_date_time_list, tracer_ukca, &
                               ntp_ukca, env%r_theta_levels, &
                               env%r_rho_levels, &
                               previous_time=previous_date_time_list, &
                               eta_theta_levels=env%eta_theta_levels)
      endif
      call ukca_step(t, current_date_time_list, tracer_ukca, ntp_ukca, &
                     env%r_theta_levels, env%r_rho_levels, err_code, &
                     previous_time=previous_date_time_list, &
                     eta_theta_levels=env%eta_theta_levels, &
                     error_message=error_message, error_routine=error_routine)

      if(ukca_dump_on()) call dump_ukca_step_out(tracer_ukca, ntp_ukca)

      if(err_code /= 0) then
        write(err_msg, "(A, I0, 2A)") "Error in ukca_step at time step ", t, &
          ": ", trim(error_message)
        call ereport(trim(error_routine), err_code, err_msg)
      endif

      if(cfg%l_ukca_h2o_feedback) then
        ! update the box environment with the ukca effect on h2o
        call update_env_from_tracers(env%q, tracer_ukca, "H2O")
      endif

      ! after ukca_step need to retrieve the tracers and ntp from master arrays
      ! and return them to the box_tracer and box_ntp modules

      ! print out the tracer output for this time step
      call print_tracer_output()

      ! add tracers to io output array
      call add_tracers_to_output(t)

    enddo

    ! write the tracer output to file
    call write_tracer_output(trim(output_file_path(cfg, "tracer_output.csv")))

    ! clean-up tracers
    call cleanup_tracers()

    call umPrint("Ending UKCA shell", src=mod_name)

  endsubroutine box_shell

endmodule box_shell_mod

