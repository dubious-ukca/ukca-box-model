module box_photol_mod

  !! Module for handling photolysis within the box model.

  use box_config_mod, only: box_config_type
  use errormessagelength_mod, only: errormessagelength
  use ereport_mod, only: ereport
  use ukca_error_mod, only: maxlen_message, maxlen_procname
  use ukca_api_mod, only: ukca_photol_varname_len
  use umprintmgr, only: umMessage, umPrint
  use box_debug_mod, only: is_debug_level

  implicit none

  private

  ! public procedures
  public :: box_photol_setup
  public :: photol_get_rates
  public :: update_solar_pos
  public :: get_photol_reaction_data

  !> Module name for error reporting
  character(len=*), parameter :: mod_name = "box_photol_mod"
  !> An array of offline photolysis rates for each grid point, level and
  !> reaction
  real, allocatable :: photol_rates_offline(:, :, :, :)
  !> An array of photolysis rates for each grid point, level and reaction
  real, allocatable :: photol_rates(:, :, :, :)
  !> A array of J rate values for each reaction and level
  character(len=10), pointer :: ratj_data(:, :)
  !> An array of photolysis variable names for each reaction
  character(len=ukca_photol_varname_len), pointer, public :: ratj_varnames(:)

contains

  subroutine box_photol_setup(cfg)

    !! Setup up the photolysis module for the box model. This includes setting
    !! up the photolysis rates array, reading in the photolysis reaction data
    !! and setting up the photolysis scheme.

    use photol_setup_mod, only: photol_setup
    use box_const_mod, only: row_length, &
                             model_levels, n_cca_lev, &
                             l_enable_diag_um, l_environ_jo2, &
                             l_environ_jo2b, l_3d_cca, &
                             l_environ_z_top, const_pi, earth_radius

    use box_socrates_mod, only: ip_aerosol_param_moist, ip_accum_sulphate, &
                                ip_aitken_sulphate

    use ukca_constants, only: c_o3

    !> Box model configuration
    type(box_config_type), intent(in) :: cfg
    !> Error code for error reporting
    integer :: err_code
    !> Error message for error reporting
    character(len=errormessagelength) :: err_msg
    !> Routine name for error reporting ukca errors
    character(len=maxlen_procname) :: ukca_routine_name

    call photol_setup( &
      i_photol_scheme=cfg%i_photol_scheme, &
      error_code=err_code, &
      chem_timestep=cfg%chem_timestep, &
      fastjx_mode=cfg%fastjx_mode, &
      fastjx_numwl=cfg%fastjx_numwl, &
      global_row_length=row_length, &
      i_solcylc_type=cfg%i_solcylc_type, &
      ip_aerosol_param_moist=ip_aerosol_param_moist, &
      ip_accum_sulphate=ip_accum_sulphate, &
      ip_aitken_sulphate=ip_aitken_sulphate, &
      model_levels=model_levels, &
      n_cca_lev=n_cca_lev, &
      solcylc_start_year=cfg%solcylc_start_year, &
      i_error_method=cfg%i_error_method, &
      l_cal360=cfg%l_cal360, &
      l_cloud_pc2=cfg%l_cloud_pc2, &
      l_3d_cca=l_3d_cca, &
      l_enable_diag_um=l_enable_diag_um, &
      l_environ_jo2=l_environ_jo2, &
      l_environ_jo2b=l_environ_jo2b, &
      l_environ_ztop=l_environ_z_top, &
      l_strat_chem=cfg%l_strat_chem, &
      fastjx_prescutoff=cfg%fastjx_prescutoff, &
      timestep=cfg%timestep, &
      pi=const_pi, &
      o3_mmr_vmr=c_o3, &
      planet_radius=earth_radius, &
      error_message=err_msg, &
      error_routine=ukca_routine_name)

    if(err_code /= 0) then
      call ereport(ukca_routine_name, err_code, err_msg)
    endif

  endsubroutine box_photol_setup

  subroutine get_photol_reaction_data()

    !! Get the photolysis reaction data by calling the UKCA API to retrieve
    !! the photolysis reaction data and variable names. Print the output if
    !! debug level is on.

    use ukca_api_mod, only: ukca_get_photol_reaction_data

    !> Loop index
    integer :: i
    !> Routine name for printing out
    character(len=*), parameter :: routine_name = mod_name// &
                                   ":get_photol_reaction_data"
    !> Minimum debug level for printing
    integer, parameter :: minimum_debug_level = 1

    call ukca_get_photol_reaction_data(ratj_data, ratj_varnames)

    if(is_debug_level(minimum_debug_level)) then
      ! print out the photolysis variable names when debug is on
      do i = 1, size(ratj_varnames)
        write(umMessage, "(2A)") "Photolysis variable name: ", &
          trim(ratj_varnames(i))
        call umPrint(umMessage, src=routine_name)
      enddo
    endif

  endsubroutine get_photol_reaction_data

  subroutine setup_photol_rates()

    !! Setup the photolysis rates array for the box model.

    use box_const_mod, only: row_length, rows, model_levels
    use box_internal_ukca_config_mod, only: jppj

    if(.not. allocated(photol_rates)) then
      allocate(photol_rates(row_length, rows, model_levels, jppj))
    endif

    photol_rates = 0.0

  endsubroutine setup_photol_rates

  subroutine update_solar_pos(env)

    !! Update the solar position in the box model environment based upon the
    !! current time and date.

    use box_time_mod, only: previous_date_time, &
                            day_time_list_format, l_cal360
    use box_environment_mod, only: box_environment_type

    !> The box model environment to update with the new solar position
    type(box_environment_type), intent(inout) :: env
    !> An array containing the day of year and time of day for the previous
    !> time step
    integer :: previous_day_time_list(7)
    !> Sin(solar declination) in radians
    real :: sindec
    !> The seconds since midnight for the previous time step
    real :: sec_since_mid
    !> True anomaly, equation 87 in Smart on p. 120 (UMDP23 Eq 73)
    real :: true_anomaly
    !> Eccentricity of the orbit
    real :: eccentricity
    !> Supplement of the longitude of perihelion
    real :: gamph
    !> Obliquity of the orbit
    real :: oblq
    !> Mean anomaly at 12Z
    real :: mean_anomaly
    !> Solar constant scaling factor
    real :: scs
    !> The equation of time, specified as an hour angle in radians.
    real :: eqt

    !> Derived orbital parameter - e1
    real :: e1
    !> Derived orbital parameter - e2
    real :: e2
    !> Derived orbital parameter - e3
    real :: e3
    !> Derived orbital parameter - e4
    real :: e4
    !> Intermediate variable
    real :: y1
    !> Minimum debug level
    integer, parameter :: min_debug_level = 1
    !> The routine name for logging and error reporting
    character(len=*), parameter :: routine_name = mod_name// &
                                   ":update_solar_pos"

    if(is_debug_level(min_debug_level)) then
      write(umMessage, "(A,I2.2,A,I2.2,A,I2.2)") &
        "Updating solar position - using previous time: ", &
        previous_date_time%hour, ":", previous_date_time%minute, ":", &
        previous_date_time%second
      call umprint(umMessage, src=routine_name)
    endif

    sec_since_mid = real(previous_date_time%hour * 3600 + &
                         previous_date_time%minute * 60 + &
                         previous_date_time%second)

    if(is_debug_level(min_debug_level)) then
      write(umMessage, "(A,I0)") "Seconds since midnight = ", &
        int(sec_since_mid)
      call umprint(umMessage, src=routine_name)
    endif

    ! index 7 = day of year
    previous_day_time_list = day_time_list_format(previous_date_time)

    if(is_debug_level(min_debug_level)) then
      write(umMessage, "(A,I0)") "Day of year = ", previous_day_time_list(7)
      call umprint(umMessage, src=routine_name)
      write(umMessage, "(A,I0)") "Year = ", previous_date_time%year
      call umprint(umMessage, src=routine_name)
    endif

    ! Determine the orbital parameters for the Earth
    call orbprm(previous_day_time_list(7), &
                l_cal360, eccentricity, gamph, oblq, mean_anomaly)

    if(is_debug_level(min_debug_level)) then
      write(umMessage, "(A,E12.3,A,E12.3,A,E12.3,A,E12.3)") &
        "Orbital parameters: e=", eccentricity, &
        " gamph=", gamph, &
        " oblq=", oblq, &
        " mean_anomaly=", mean_anomaly
      call umprint(umMessage, src=routine_name)
    endif

    ! Calculate the coefficients in the equation of the centre and
    ! thence derive the true anomaly.
    e1 = eccentricity * (2.0 - .25 * eccentricity * eccentricity)
    e2 = 1.25 * eccentricity * eccentricity
    e3 = eccentricity * eccentricity * eccentricity * 13.0 / 12.0

    ! True anomaly, equation 87 in Smart on p. 120 (UMDP23 Eq 73)
    true_anomaly = mean_anomaly + e1 * sin(mean_anomaly) + &
                   e2 * sin(2.0 * mean_anomaly) + &
                   e3 * sin(3.0 * mean_anomaly)

    ! Solar constant scaling factor (UMDP23 Eqs 75 and 76)
    e4 = (1.0 / (1.0 - eccentricity * eccentricity))**2
    ! not currently used but likely needed later
    scs = e4 * (1.0 + eccentricity * cos(true_anomaly))**2

    ! sin(solar declination) (UMDP23 Eq 77)
    ! The solar declination is related to
    !  the true longitude of the earth (lambda) by:
    !  sindec = sin(obliquity) * sin(lambda)
    ! Lambda is counted counter-clockwise from the vernal equinox
    !  and is related to v (the true anomaly) through
    !  lambda = v + (longitude of perihelion)
    sindec = sin(oblq) * sin(true_anomaly - gamph)

    ! TODO - we only allow for Equation 29 on page 149 of Smart (1944) in
    !   equation of time calculations - should added Mueller option

    ! Use equation (29)on page 149 of Smart (1944).
    ! (Recall the factor of 5/4 in the definition of e2).
    y1 = (tan(0.5 * oblq))**2
    eqt = y1 * sin(2.0 * (mean_anomaly - gamph)) &
          - 2.0 * eccentricity * sin(mean_anomaly) &
          + 4.0 * eccentricity * y1 * sin(mean_anomaly) &
          * cos(2.0 * (mean_anomaly - gamph)) &
          - 0.5 * y1 * y1 * sin(4.0 * (mean_anomaly - gamph)) &
          - e2 * sin(2.0 * mean_anomaly)

    ! now we've updated eqt and sindec we need to set the environment again
    env%sin_declination = sindec
    env%equation_of_time = eqt

  endsubroutine update_solar_pos

  subroutine orbprm(day_number, l_cal360, eccentricity, gamph, oblq, &
                    mean_anomaly)

    !! Calculate the orbital parameters

    ! TODO - we currently don't evolve orb parameters - model won't be suitable
    ! for paleo and long climate runs in current form

    use box_const_mod, only: const_pi

    !> Day-number in the year
    integer, intent(in) :: day_number
    !> Use a calendar of 360 days
    logical, intent(in) :: l_cal360

    !> Eccentricity of earth's orbit
    real, intent(out) :: eccentricity
    !> Supplement of the longitude of perihelion
    real, intent(out) :: gamph
    !> Obliquity of the orbit
    real, intent(out) :: oblq
    !> Mean anomaly at 12Z
    real, intent(out) :: mean_anomaly
    !> Length of the calendar year (in whole days)
    real :: diny
    !> Time of the perihelion passage in days
    real :: tau0
    !> Number of days in the tropical year
    real, parameter :: trop_year_length = 365.2424

    !> Eccentricity of the orbit
    real, parameter :: e_dflt = 1.6710222e-02
    !> Obliquity of the orbit - corresponds to 23.43929111 degrees
    real, parameter :: oblq_dflt = 0.409092804
    !> Longitude of the perihelion in radians
    real, parameter :: lph_dflt = 102.94719 * const_pi / 180.0
    !> Time of the perihelion passage in days
    real, parameter :: tau0_dflt = 2.667

    ! Set the orbital parameters to their defaults
    eccentricity = e_dflt
    oblq = oblq_dflt
    gamph = const_pi - lph_dflt
    tau0 = tau0_dflt

    ! Calculate the mean anomaly at 12Z on the current day.
    ! The 0.5 accounts for the time in days since mid-night.
    ! The references are to Smart 1944 (and UMDP23)
    ! Eq 67 p. 113 and n=2pi/orbital period     (Eq 3.1.1)
    if(l_cal360) then
      diny = 360.0
      tau0 = tau0 * (360.0 / trop_year_length) + 0.71
      mean_anomaly = ((2.0 * const_pi) / diny) * &
                     (real(day_number) - tau0 - 0.5)
    else
      mean_anomaly = ((2.0 * const_pi) / trop_year_length) * &
                     (real(day_number) - tau0 - 0.5)
    endif

  endsubroutine orbprm

  subroutine photol_get_rates(cfg, env)

    !! Process the photolysis rates, beginning with setup and moving onto
    !! either calculate the rates in an offline or online manner depending on
    !! cfg%l_offline_photol

    use box_config_mod, only: box_config_type
    use box_environment_mod, only: box_environment_type

    !> the input box model configuration
    type(box_config_type), intent(in) :: cfg
    !> the input box model environment, photolysis rates are stored in
    type(box_environment_type), intent(inout) :: env

    if(cfg%i_photol_scheme == 0) then
      ! not running photolysis - do nothing
      return
    endif

    call setup_photol_rates()

    if(cfg%l_offline_photol) then
      call photol_ctl_offline(cfg, env)
    else
      call photol_ctl_online(env)
    endif

  endsubroutine photol_get_rates

  subroutine photol_ctl_offline(cfg, env)

    !! A subroutine to handle box model configuration where photolysis rates
    !! are provided in an offline file

    use box_config_mod, only: box_config_type
    use box_environment_mod, only: box_environment_type
    use box_const_mod, only: row_length, rows, model_levels
    use box_internal_ukca_config_mod, only: jppj
    use box_time_mod, only: previous_date_time
    use ukca_solang_mod, only: ukca_solang

    !> The input box model configuration
    type(box_config_type), intent(in) :: cfg
    !> The input box model environment
    type(box_environment_type), intent(inout) :: env
    !> How many seconds since midnight
    real :: seconds_since_midnight
    !> The number of grid points in the model
    integer :: n_points
    !> The solar zenith angle array
    real :: cos_zenith_angle(row_length, rows)
    !> The day length array
    real :: daylen(row_length, rows)
    !> loop index
    integer :: i
    !> Loop index
    integer :: j
    !> Loop index
    integer :: k
    !> Loop index
    integer :: l
    !> Routine name for print outs
    character(len=maxlen_procname), parameter :: &
      routine_name = mod_name//":photol_ctl_offline"
    !> minimum debug level for printing
    integer, parameter :: minimum_debug = 1

    ! use previous time step for the input
    seconds_since_midnight = real(previous_date_time%hour * 3600 + &
                                  previous_date_time%minute * 60 + &
                                  previous_date_time%second)

    ! number of points
    n_points = row_length * rows

    if(.not. allocated(photol_rates_offline)) then
      call read_offline_photol_rates(cfg%offline_photol_rates_file)
    else
      if(is_debug_level(minimum_debug)) then
        write(umMessage, "(A,A)") "Photolysis rates already read from ", &
          "file - skipping re-read"
        call umPrint(umMessage, src=routine_name)
      endif
    endif

    call calc_local_day_length(env%tan_latitude, env%sin_declination, daylen)

    call ukca_solang(env%sin_declination, &
                     seconds_since_midnight, &
                     real(cfg%chem_timestep), &
                     env%equation_of_time, env%sin_latitude, &
                     env%cos_latitude, env%longitude, &
                     n_points, cos_zenith_angle)

    ! use the cosine of the solar zenith angle to scale the photolysis rates
    do k = 1, model_levels
      do j = 1, rows
        do i = 1, row_length
          if(cos_zenith_angle(i, j) > 0.0) then
            photol_rates(i, j, k, :) = photol_rates_offline(i, j, k, :) * &
                                       cos_zenith_angle(i, j)
          else
            photol_rates(i, j, k, :) = 0.0
          endif
        enddo
      enddo
    enddo

    if(is_debug_level(minimum_debug)) then
      write(umMessage, "(A)") "Photolysis rates:"
      call umPrint(umMessage, src=routine_name)
      do l = 1, jppj
        write(umMessage, "(A,A,A,E12.3)") "  Reaction ", &
          trim(ratj_varnames(l)), ": ", photol_rates(1, 1, 1, l)
        call umPrint(umMessage, src=routine_name)
      enddo
    endif

    ! these can then be set using ukca_set_environment
    env%photol_rates = photol_rates

  endsubroutine photol_ctl_offline

  subroutine calc_local_day_length(tan_latitude, sin_declination, daylen)

    !! Calculate the day length for a model's grid

    use box_const_mod, only: row_length, rows, &
                             const_pi, rhour_per_day_const

    !> An array of the tangent of latitude values for the grid
    real, intent(in) :: tan_latitude(row_length, rows)
    !> sin of solar declination
    real, intent(in) :: sin_declination
    !> An array of the day lengths for each grid cell
    real, intent(out) :: daylen(row_length, rows)
    !> Cosine hour angle
    real :: cs_hour_ang(row_length, rows)
    !> TAN(solar declination angle)
    real :: tan_declin

    ! solar declination from the box model's own solar position
    ! (`update_solar_pos`), so day length is consistent with
    ! `cos_zenith_angle`
    tan_declin = sin_declination / sqrt(1.0 - sin_declination**2)

    ! guard against tan_declin == 0 (an equinox)
    if(abs(tan_declin) < epsilon(tan_declin)) then
      cs_hour_ang = 0.0
    else
      cs_hour_ang = max(-1.0, min(1.0, -tan_latitude * tan_declin))
    endif

    daylen = (rhour_per_day_const / const_pi) * acos(cs_hour_ang)

  endsubroutine calc_local_day_length

  subroutine read_offline_photol_rates(photol_rates_file)

    !! Read photolysis rates from an offline file

    use box_internal_ukca_config_mod, only: jppj
    use box_const_mod, only: row_length, rows, model_levels
    use missing_data_mod, only: rmdi
    use ukca_chem_defs_mod, only: ratj_defs
    use box_err_codes_mod, only: box_errcode_io_photol_offline

    !> The path to the file containing the offline rates
    character(len=*), intent(in) :: photol_rates_file
    !> An array of quantum yield scaling factors
    real :: jfacta(jppj)
    !> the I/O status of read
    integer :: iostat_read
    !> the I/O status of open
    integer :: iostat_open
    !> the I/O status of parse
    integer :: iostat_parse
    !> Code for error reporting
    integer :: err_code
    !> Loop index
    integer :: i
    !> Array of reaction indexes in the photol array
    integer, allocatable :: indexes(:)
    !> the I/O unit for reading the offline photolysis file
    integer :: unit
    !> Logical for determining if the rate file exists.
    logical :: file_exists
    !> Logical for determining if a reaction rate was found
    logical :: found
    !> Message for error reporting
    character(len=errormessagelength) :: err_msg
    !> Routine name for error reporting
    character(len=maxlen_procname), parameter :: &
      routine_name = mod_name//":read_offline_photol_rates"
    !> The read line from the offline photol file
    character(len=256) :: line
    !> The read variable name from the rates file
    character(len=256) :: var_name
    !> The read variable value from the rates file
    real :: var_value
    !> The default value to apply to required rates not found in the file
    real :: default_value
    !> Array of logicals showing which rates have been provided.
    logical :: photol_provided(jppj)

    ! allocate photol_rates_offline
    if(.not. allocated(photol_rates_offline)) then
      allocate(photol_rates_offline(row_length, rows, model_levels, jppj))
      photol_rates_offline = rmdi
    endif

    default_value = 0.0
    err_code = 0
    photol_provided = .false.
    iostat_read = 0
    iostat_open = 0
    iostat_parse = 0

    inquire(file=photol_rates_file, exist=file_exists)
    if(.not. file_exists) then
      write(err_msg, "(3A)") "Photol rate file '", trim(photol_rates_file), &
        "' not found."
      err_code = box_errcode_io_photol_offline
      call ereport(routine_name, err_code, err_msg)
    endif

    ! TODO - move reading of rate file to a separate module due to duplication
    ! with tracer reading.
    open(newunit=unit, file=photol_rates_file, status='old', &
         action='read', iostat=iostat_open)

    if(iostat_open /= 0) then
      write(err_msg, "(2A)") "Error opening the offline photolysis file: ", &
        trim(photol_rates_file)
      err_code = box_errcode_io_photol_offline
      call ereport(routine_name, err_code, err_msg)
    endif

    do
      read(unit, '(A)', iostat=iostat_read) line
      if(is_iostat_end(iostat_read)) then
        exit
      elseif(iostat_read /= 0) then
        write(err_msg, "(3A)") "Error reading photol rates file '", &
          trim(photol_rates_file), "'."
        err_code = box_errcode_io_photol_offline
        call ereport(routine_name, err_code, err_msg)
      endif

      if(len_trim(line) == 0 .or. line(1:1) == "#") then
        cycle
      endif

      ! Read whitespace-separated tokens: <var_name> <var_value>
      read(line, *, iostat=iostat_parse) var_name, var_value

      if(iostat_parse /= 0) then
        write(err_msg, "(3A)") "Could not parse offline photol rate line: '", &
          trim(line), "'."
        err_code = -box_errcode_io_photol_offline
        call ereport(routine_name, err_code, err_msg)
        cycle
      endif

      if(var_name == "DEFAULT") then
        default_value = var_value
        cycle
      endif

      ! find index of var_name in ratj_varnames
      call find_photol_varname_index(var_name, indexes, found)

      if(found) then
        do i = 1, size(indexes)
          photol_rates_offline(:, :, :, indexes(i)) = var_value
          photol_provided(indexes(i)) = .true.
        enddo
      else
        write(err_msg, "(3A)") "Variable '", trim(var_name), &
          "' in photol rate file not found in model configuration."

        ! warning code
        err_code = -box_errcode_io_photol_offline
        call ereport(routine_name, err_code, err_msg)
      endif

    enddo
    close(unit)

    ! use default value to fill any missing photolysis rates
    do i = 1, jppj
      if(.not. photol_provided(i)) then
        photol_rates_offline(:, :, :, i) = default_value

        write(err_msg, "(4A,E12.3E3,A)") &
          "No value provided for photolysis rate '", &
          trim(ratj_varnames(i)), "' in photol rate file. ", &
          "Using default value of ", default_value, "."
        ! warning code
        err_code = -box_errcode_io_photol_offline
        call ereport(routine_name, err_code, err_msg)
      endif
    enddo

    ! final check that no photolysis rates are missing, e.g. negative
    do i = 1, jppj
      if(any(photol_rates_offline(:, :, :, i) < 0.0)) then
        write(err_msg, "(4A)") "Photolysis rate '", &
          trim(ratj_varnames(i)), &
          "' has negative value in photol rate file. ", &
          "Please check file and try again."

        err_code = box_errcode_io_photol_offline
        call ereport(routine_name, err_code, err_msg)
      endif
    enddo

    ! we have to apply "quantum yield" scaling here
    do i = 1, jppj
      jfacta(i) = ratj_defs(i)%jfacta / 100.0
      photol_rates_offline(:, :, :, i) = photol_rates_offline(:, :, :, i) * &
                                         jfacta(i)
    enddo

  endsubroutine read_offline_photol_rates

  subroutine find_photol_varname_index(var_name, indexes, found)

    !! Find the indexes of a j-value label in the ratj_varnames array based
    !! upon its name. Note that there can be multiple entries for a specific
    !! species in the ratj_varnames array.

    use box_internal_ukca_config_mod, only: jppj

    !> The variable name to find in the photolysis variable name array
    character(len=*), intent(in) :: var_name
    !> the indexes corresponding to the var_name
    integer, allocatable, intent(out) :: indexes(:)
    !> Logical indicating if one index was found
    logical, intent(out) :: found
    !> Loop index
    integer :: i

    allocate(indexes(0))
    found = .false.

    do i = 1, jppj
      if(trim(var_name) == trim(ratj_varnames(i))) then
        call append(indexes, i)
        found = .true.
      endif
    enddo

  contains

    subroutine append(list, value)
      !! Help routine for appending a value to a list

      !> The list to append the value to
      integer, allocatable, intent(inout) :: list(:)
      !> The value to append
      integer, intent(in) :: value
      !> Temporary copy of the list
      integer, allocatable :: temp(:)
      !> Length of the list
      integer :: n

      n = size(list)
      allocate(temp(n + 1))

      if(n > 0) temp(1:n) = list
      temp(n + 1) = value

      call move_alloc(temp, list)
    endsubroutine append

  endsubroutine find_photol_varname_index

  subroutine photol_ctl_online(env)

    !! Setup box model configuration where photolysis rates that are actively
    !! calculated based upon a provided column environment.

    use box_environment_mod, only: box_environment_type
    use box_time_mod, only: current_date_time, day_time_list_format
    use box_const_mod, only: row_length, rows, model_levels, rad_ctl_jo2, &
                             rad_ctl_jo2b
    use ukca_api_mod, only: ukca_photol_varname_len
    use photol_ctl_mod, only: photol_ctl
    use box_internal_ukca_config_mod, only: jppj
    use box_tracer_mod, only: return_tracer
    use box_err_codes_mod, only: box_errcode_not_implemented

    !> The box model environment
    type(box_environment_type), intent(inout) :: env
    !> The returned error code from photol_ctl
    integer, target :: error
    !> The point to error, passed into photol_ctl
    integer, pointer :: error_ptr
    !> The routine name for error reporting
    character(len=maxlen_procname), parameter :: routine_name = mod_name// &
                                                 ":photol_ctl_online"
    !> The internal UKCA routine that caused an error
    character(len=maxlen_procname) :: ukca_err_routine
    !> The message for error reporting
    character(len=errormessagelength) :: err_msg
    !> The error code for box model specific errors
    integer :: err_code
    !> The o3 mmr from the box model tracer
    real :: o3
    !> An array containing the o3 mmr, passed into photol_ctl
    real :: ozone_mmr(row_length, rows, model_levels)
    !> number of seconds since midnight
    real :: seconds_since_midnight
    !> Current time list in the form  [year, month, day, hour, minute, second
    !> and day of year]
    integer :: current_time(7)
    !> rate data array for the output from photol_ctl
    character(len=10), pointer :: rate_data(:, :)
    !> rate variable names array for the output from photol_ctl
    character(len=ukca_photol_varname_len), pointer ::rate_varnames(:)

    ! Error for now
    write(err_msg, "(A)") "Not implemented yet - on the to do list!"
    err_code = box_errcode_not_implemented
    call ereport(routine_name, err_code, err_msg)

    seconds_since_midnight = real(current_date_time%hour * 3600 + &
                                  current_date_time%minute * 60 + &
                                  current_date_time%second)

    current_time = day_time_list_format(current_date_time)

    ! fetch the O3 mixing ratio from the tracer array
    call return_tracer("O3", o3)
    ! set ozone mmr (3D) to the real value of o3
    ozone_mmr = o3

    error_ptr => error

    ! because we don't need the column with offline mode we can just pass the
    ! box environment in
    call photol_ctl( &
      error_code_ptr=error_ptr, &
      row_length=row_length, &
      rows=rows, &
      model_levels=model_levels, &
      jppj=jppj, &
      z_top_of_model=env%z_top_of_model, &
      seconds_since_midnight=seconds_since_midnight, &
      sin_declination=env%sin_declination, &
      equation_of_time=env%equation_of_time, &
      current_time=current_time, &
      ratj_data=rate_data, &
      ratj_varnames=rate_varnames, &
      conv_cloud_base=env%conv_cloud_base, &
      conv_cloud_top=env%conv_cloud_top, &
      land_fraction=env%fland, &
      surf_albedo=env%surf_albedo, &
      longitude=env%longitude, &
      sin_latitude=env%sin_latitude, &
      cos_latitude=env%cos_latitude, &
      tan_latitude=env%tan_latitude, &
      p_theta_levels=env%p_theta_levels, &
      p_layer_boundaries=env%p_layer_boundaries, &
      r_theta_levels=env%r_theta_levels, &
      r_rho_levels=env%r_rho_levels, &
      qcl=env%qcl, &
      qcf=env%qcf, &
      area_cloud_fraction=env%area_cloud_fraction, &
      conv_cloud_amount=env%conv_cloud_amount, &
      conv_cloud_lwp=env%conv_cloud_lwp, &
      ozone_mmr=ozone_mmr, &
      so4_aitken=env%so4_aitken, &
      so4_accum=env%so4_accum, &
      aod_sulph_aitk=env%aod_sulph_aitk, &
      aod_sulph_accum=env%aod_sulph_accum, &
      rad_ctl_jo2=rad_ctl_jo2, &
      rad_ctl_jo2b=rad_ctl_jo2b, &
      t_theta_levels=env%t_theta_levels, &
      photol_rates_2d=photol_rates_offline, &
      photol_rates=photol_rates, &
      error_message=err_msg, &
      error_routine=ukca_err_routine)

    if(error /= 0) then
      call ereport(ukca_err_routine, error, err_msg)
    endif

  endsubroutine photol_ctl_online

endmodule box_photol_mod
