module box_config_mod

  !! Module for reading, validating and printing the box model configuration.
  !! Box model configurations are read from a user-provided namelist file and
  !! are stored in a box_config_type type, which is used to control the
  !! behaviour of the box model and UKCA.

  use umprintmgr, only: umMessage, umPrint
  use ereport_mod, only: ereport
  use ukca_api_mod, only: ukca_maxlen_message, ukca_maxlen_procname

  implicit none

  private

  public :: read_box_config
  public :: print_box_config
  public :: output_file_path

  !> Module name for logging and error reporting
  character(len=*), parameter :: mod_name = "box_config_mod"

  interface print_field
    procedure print_field_int
    procedure print_field_real
    procedure print_field_logical
    procedure print_field_char
  endinterface print_field

  !> All the box model configuration options, read from the box config
  !> namelist
  type, public :: box_config_type
    !> model duration (seconds)
    integer :: model_duration
    !> starting year of model
    integer :: start_year
    !> starting month of model
    integer :: start_month
    !> starting day of model
    integer :: start_day
    !> starting hour of model
    integer :: start_hour
    !> starting minute of model
    integer :: start_minute
    !> starting second of model
    integer :: start_second
    !> Chemistry scheme to use
    integer :: i_ukca_chem
    !> Chemical mechanism version identifier
    integer :: i_ukca_chem_version
    !> No. of N-R solver iterations before time step is halved
    integer :: nrsteps
    !> Chemical timestep in seconds for N-R and offline oxidant schemes
    integer :: chem_timestep
    !> Backward Euler timestep (seconds)
    integer :: dts0
    !> Method for controlling age reset to 0
    integer :: i_ageair_reset_method
    !> Max. level for reset (Method 1)
    integer :: max_ageair_reset_level
    !> Error handling method to use
    integer :: i_error_method
    !> Number of iterations for B-E Solver
    integer :: nit
    !> Iteration to start quasi-Newton step (2-50, 2 recommended)
    integer :: i_ukca_quasinewton_start
    !> Iteration to stop quasi-Newton step (2-50, 3 recommended)
    integer :: i_ukca_quasinewton_end
    !> Method of treating top boundary for certain species in stratospheric
    !> schemes
    integer :: i_ukca_topboundary
    !> 0 = default (5 reactions); 1 = JPL-15 recommended coeff. 2 = JPL-15 +
    !> bromine reactions
    integer :: i_ukca_hetconfig
    !> maximum INFERNO emission level
    integer :: i_inferno_emi
    !> Sea-air DMS exchange scheme to use
    integer :: i_ukca_dms_flux
    !> Choice for flash-freq parameterisation (1 = Price & Rind, 2 = Luhar et
    !> al., 3 = external lightning scheme)
    integer :: i_ukca_light_param
    !> Photolysis scheme: 0 = off, 1 = stratospheric only, 2 = offline/2-D,
    !> 3 = Fast-JX
    integer :: i_photol_scheme
    !> Timestep number at which environment summary diagnostics should be
    !> printed to log file
    integer :: env_log_step
    !> Options for tuning BC absorption via adjusting BC mass density and
    !> refractive index mixing approximations
    integer :: i_ukca_tune_bc
    !> Sea-salt emission options
    integer :: i_primss_method
    !> No. of substeps for nucleation/sedimentation
    integer :: i_mode_nzts
    !> MODE aerosol scheme to use
    integer :: i_mode_setup
    !> Parameterisation method for boundary layer nucleation 1=activation;
    !> 2=kinetic; 3=organic mediated (as per Metzger et al, PNAS, 2010) -
    !> required when 'l_mode_bhn_on' is true.
    integer :: i_mode_bln_param_method
    !> Choice of nucl. scavenging coefficients: 1=original, 2=ECHAM5-HAM,
    !> 3=as(1) but no scav of modes 6&7
    integer :: i_mode_nucscav
    !> Activation scheme to use
    integer:: i_ukca_activation_scheme
    !> Value of nwbins in Activate (1-20) See Rosalind West paper for details
    !> doi:10.5194/acp-14-6369-2014
    integer :: i_ukca_nwbins
    !> Number of surface types considered in interactive dry deposition
    integer :: ntype
    !> fast-jx photolysis mode above cutoff (1=lookup tables, 2=fast-jx +
    !> lookup tables, 3=fast-jx)
    integer :: fastjx_mode
    !> number of wavelengths to use in fast-jx. Options are 8, 12 or 18
    integer :: fastjx_numwl
    !> apply solar variability to photolysis (fast-jx only). 0 = no solar
    !> cycle, 1 = observed cycle, 2 = average cycle.
    integer :: i_solcylc_type
    !> 1st year for the solar cycle (used when i_solcylc_type = 1)
    integer :: solcylc_start_year

    !> Thickness of surface soil layer (m)
    real :: dzsoil_layer1
    !> Model timestep in seconds (an integer no of timesteps is expected in 1
    !> hour)
    real :: timestep
    !> Max. height (m) for reset (Method 2)
    real :: max_ageair_reset_height
    !> Maximum height at which to integrate chemistry with the explicit B-E
    !> Offline Oxidants scheme
    real :: max_z_for_offline_chem
    !> Cut-off Pressure for tabulated photolysis
    real :: fastjx_prescutoff
    !> Fraction of SO2 emissions as aerosol(%)
    real :: mode_parfrac
    !> Marine DMS emission scaling factor
    real :: seadms_ems_scaling
    !> Sea salt emission scaling factor
    real :: sea_salt_ems_scaling
    !> Marine POM emission scaling factor
    real :: marine_pom_ems_scaling
    !> Lightning NOx emissions scaling factor
    real :: lightnox_scale_fac
    !> Anthropogenic SO2 emissions scaling factor
    real :: anth_so2_ems_scaling
    !> Scaling factor for production of SOA from monoterpene
    real :: soa_yield_scaling_mt
    !> Scaling factor for production of SOA from isoprene
    real :: soa_yield_scaling_isop
    !> SO2 dry deposition velocity scaling factor
    real :: dry_depvel_so2_scaling
    !> Activation dry radius (nm)
    real :: mode_activation_dryr
    !> Scaling factor for the dry deposition velocity for the accumulation mode
    real :: dry_depvel_acc_scaling
    !> Scaling factor for scavenging parameters for the accumulation and coarse
    !> modes
    real :: acc_cor_scav_scaling
    !> Fraction of in-cloud oxidised SO2 removed by precipitation
    real :: mode_incld_so2_rfrac
    !> Biomass-burning emissions scaling
    real :: biom_aer_ems_scaling
    !> value for fitting coefficient a of the interactive cloud pH code
    real :: ph_fit_coeff_a
    !> value for fitting coefficient b of the interactive cloud pH code
    real :: ph_fit_coeff_b
    !> y-intercept value of the relationship for the interactive cloud pH code
    real :: ph_fit_intercept
    !> Lower limit for std. dev. of updraft velocity pdf used in Activate
    !> (default: 0.01 m/s).
    real :: sigwmin
    !> HNO3 uptake coefficient for nitrate
    real :: hno3_uptake_coeff
    !> Scaling factor for standard deviation of updraught velocities
    real:: sigma_updraught_scaling
    !> Configurable universal gas constant R (J/mol/K)
    real :: const_rmol
    !> Configurable temperature at which sea water freezes (K)
    real :: const_tfs
    !> Configurable density of pure water (kg/m3)
    real :: const_rho_water
    !> Configurable density of sea water (kg/m3)
    real :: const_rhosea
    !> Configurable latent heat of condensation of water at 0 degC (J/kg)
    real :: const_lc
    !> Configurable number of molecules in 1 mole (Avogadro constant)
    real :: const_avogadro
    !> Configurable Boltzmann constant (J K-1)
    real :: const_boltzmann
    !> Configurable density of SO4 particle (kg/m3)
    real :: const_rho_so4
    !> EW (x) grid spacing in radians
    real :: delta_lambda
    !> NS (y) grid spacing in radians
    real:: delta_phi

    !> True if UKCA is expected to use a 360-day calendar for applying a top
    !> boundary condition in stratospheric chemistry schemes and/or for
    !> validating external emissions. (Emissions registered with a day-of-week
    !> scaling requirement can't be used with a 360-day calendar).
    logical :: l_cal360
    !> True for aerosol precursor chemistry
    logical :: l_ukca_chem_aero
    !> True for GLOMAP-mode aerosol scheme
    logical :: l_ukca_mode
    !> True for age-of-air scheme
    logical :: l_ukca_ageair
    !> True to set all non-valid diagnostic field data to missing data value
    logical :: l_blankout_invalid_diags
    !> True to use a timer routine for timing sub-models
    logical :: l_timer
    !> True to turn on perturbed parameter ensemble (PPE) scaling parameters
    logical :: l_ukca_scale_ppe
    !> True to turn off dry deposition
    logical :: l_ukca_drydep_off
    !> True to turn off wet deposition
    logical :: l_ukca_wetdep_off
    !> Include additional print output specific to ASAD
    logical :: l_ukca_debug_asad
    !> True for interactive dry deposition
    logical :: l_ukca_intdd
    !> True to use Luhar et al. (2018) oceanic O3 dry-deposition scheme
    logical :: l_ukca_ddepo3_ocean
    !> True to apply dry deposition losses only in level 1
    logical :: l_ukca_ddep_lev1
    !> True if considering the impact of surface wetness on dry deposition
    logical :: l_ukca_dry_dep_so2wet
    !> True when using JULES-based interactive dry deposition routines
    logical :: l_deposition_jules
    !> True to use quasi-Newton (Broyden) method to reduce no. of iterations in
    !> N-R solver step
    logical :: l_ukca_quasinewton
    !> True to handle lumped tracers in stratospheric chemistry schemes
    logical :: l_tracer_lumping
    !> True to stop transport of peroxy radicals in StratTrop/CRI scheme
    logical :: l_ukca_ro2_ntp
    !> True for RO2-permutation chemistry in StratTrop/CRI scheme
    logical :: l_ukca_ro2_perm
    !> True for calculating interactive cloud pH values (F for global value of
    !> 5)
    logical :: l_ukca_intph
    !> True for heterogeneous polar stratospheric cloud chemistry
    logical :: l_ukca_het_psc
    !> True to limit the formation of NAT in polar stratospheric clouds
    !> (type 1) to heights above 1 km
    logical :: l_ukca_limit_nat
    !> True to use surface area density climatology for heterogeneous PSC chem.
    logical :: l_ukca_sa_clim
    !> True for tropospheric het. chemistry
    logical :: l_ukca_trophet
    !> Allows the use of heterogeneous chemistry on aerosol surfaces from
    !> CLASSIC within UKCA.
    logical :: l_ukca_classic_hetchem
    !> True if UKCA is expecting to apply Photolysis rates in the solver and
    !> hence needs the rates from the parent
    logical :: l_use_photolysis
    !> True for interactive bVOC emissions
    logical :: l_ukca_ibvoc
    !> True for INFERNO fire emissions
    logical :: l_ukca_inferno
    !> True for INFERNO CH4 fire emissions
    logical :: l_ukca_inferno_ch4
    !> True for interactive expvolc emissions
    logical :: l_ukca_so2ems_expvolc
    !> True for expvolc emissions with plumeria
    logical :: l_ukca_so2ems_plumeria
    !> True for interactive wetland CH4 emissions
    logical :: l_ukca_qch4inter
    !> True when running UKCA in CH4 emissions-driven mode
    logical :: l_ukca_emsdrvn_ch4
    !> Apply scaling to marine DMS emissions.
    logical :: l_ukca_scale_seadms_ems
    !> True to use LOG(p) to distribute lightning NOx in the vertical
    logical :: l_ukca_linox_scaling
    !> Apply scaling factor to SOA production from monoterpene
    logical :: l_ukca_scale_soa_yield_mt
    !> Apply scaling factor to SOA production from isoprene
    logical :: l_ukca_scale_soa_yield_isop
    !> True to support full range of vertical scaling options for 2D emission
    !> fields.
    logical :: l_support_ems_vertprof
    !> True to support the provision of offline emissions in grid-box units
    logical :: l_support_ems_gridbox_units
    !> True to suppress all tracer updates from emissions and boundary layer
    !> mixing (Emissions diagnostics are unaffected)
    logical :: l_suppress_ems
    !> True for H2O feedback from chemistry
    logical :: l_ukca_h2o_feedback
    !> True if using precipitation diagnostics from a parameterized convection
    !> scheme
    logical :: l_param_conv
    !> True if using partial land points at coasts
    logical :: l_ctile
    !> True if external O3, used for troposphere only schemes, is expected as a
    !> mean value for each domain row (i.e. zonal mean if lat const. in row)
    logical :: l_zon_av_ozone
    !> True to include hydrogen conservation when 'l_ukca_h2o_feedback' is true
    logical :: l_ukca_conserve_h
    !> True if using external values for CO2, CH4, O2, H2 and N2 in chemistry
    logical :: l_chem_environ_gas_scalars
    !> True if using an external CO2 field in chemistry
    logical :: l_chem_environ_co2_fld
    !> True if prescribing surface CH4
    logical :: l_ukca_prescribech4
    !> True to use CLASSIC SO4 for het. chem.
    logical :: l_use_classic_so4
    !> True to use CLASSIC black carbon for het. chem. (RAQ scheme only)
    logical :: l_use_classic_soot
    !> True to use CLASSIC organic carbon from fossil fuels for het. chem.
    !> (RAQ only)
    logical :: l_use_classic_ocff
    !> True to use CLASSIC biogenic secondary organic aerosol for het. chem.
    !> (RAQ only)
    logical :: l_use_classic_biogenic
    !> True to use CLASSIC sea salt for het. chem. (RAQ only)
    logical :: l_use_classic_seasalt
    !> True to use gridbox volume in diagnostic calculations. (This is required
    !> for UM diagnostics and to enable use of ASAD framework diagnostics in
    !> non-UM applications.)
    logical :: l_use_gridbox_volume
    !> True to use mass of air in grid box in prognostic and/or diagnostic
    !> calculations. (Note that GLOMAP-mode prognostics will run with or
    !> without this option giving equivalent but not bit-comparable results.
    !> The option is required for the stratospheric chemistry schemes and for
    !> UM diagnostics.)
    logical :: l_use_gridbox_mass
    !> True if using external fields for relative humidity, clear-sky relative
    !> humidity and/or saturation vapour pressure
    logical :: l_environ_rel_humid
    !> True to fix cloud_frac offset bug
    logical :: l_fix_ukca_cloud_frac
    !> True to fix dry deposition velocities
    logical :: l_fix_improve_drydep
    !> True to use correct surface resistance of water when calculating dry
    !> deposition of SO2
    logical :: l_fix_drydep_so2_water
    !> True to fix H2 deposition to shrub/soil
    logical :: l_fix_ukca_h2dd_x
    !> True to fix water vapour units in B-E Offline Oxidants scheme
    logical :: l_fix_ukca_offox_h2o_fac
    !> True to fix storage of H2SO4 in ASAD N-R schemes for updating in GLOMAP
    logical :: l_fix_ukca_h2so4_ystore
    !> True for binary homogeneous sulphate nucleation
    logical :: l_mode_bhn_on
    !> True for boundary layer sulphate nucleation
    logical :: l_mode_bln_on
    !> True for aerosol dry deposition
    logical :: l_ddepaer
    !> True for turning on nucleation scavenging (rainout)
    logical :: l_aero_rainout
    !> True for convective rainout in UKCA
    logical :: l_cv_rainout
    !> True for turning on impaction scavenging
    logical :: l_impc_scav
    !> True for turning on the Slinn impaction scheme for dust and
    !> microplastics
    logical :: l_dust_mp_slinn_impc_scav
    !> True for primary sea-salt emissions
    logical :: l_ukca_primss
    !> True for primary sulphate emissions
    logical :: l_ukca_primsu
    !> True for primary dust emissions
    logical :: l_ukca_primdu
    !> True for primary BC/OC emissions
    logical :: l_ukca_primbcoc
    !> True for primary marine OC aerosol emissions
    logical :: l_ukca_prim_moc
    !> True for primary biofuel BC/OC emissions
    logical :: l_bcoc_bf
    !> True for primary biomass BC/OC emissions
    logical :: l_bcoc_bm
    !> True for primary fossil fuel BC/OC emissions
    logical :: l_bcoc_ff
    !> True to apply scaling factor to biomass burning BC/OC aerosol emissions
    logical :: l_ukca_scale_biom_aer_ems
    !> True for fine mode NO3/NH4 emissions
    logical :: l_ukca_fine_no3_prod
    !> True for coarse mode NO3 emissions
    logical :: l_ukca_coarse_no3_prod
    !> True for nitrate emissions in MODE
    logical :: l_no3_prod_in_aero_step
    !> True to apply scaling factor to sea salt emissions
    logical :: l_ukca_scale_sea_salt_ems
    !> True to apply scaling factor to marine particulate organic matter
    logical :: l_ukca_scale_marine_pom_ems
    !> True for microplastic fragment emissions
    logical :: l_ukca_mp_fragment
    !> True for microplastic fibre emissions
    logical :: l_ukca_mp_fibre
    !> Provide output for calculating direct radiative effects of aerosols
    !> using RADAER
    logical :: l_ukca_radaer
    !> True to include total number concentration of active aerosol in
    !> non-transported prognostics (e.g. for combination with an external cloud
    !> mask for calculating CDNC in the UM hybrid resolution model)
    logical :: l_ntpreq_n_activ_sum
    !> True to include to include the dry diameter for nucleation soluble mode
    logical :: l_ntpreq_dryd_nuc_sol
    !> True for diagnosing UKCA CCN at fixed supersaturation
    logical :: l_ukca_sfix
    !> True to check, trap and fix for negative values in 'pvol' and 'mdwat'
    logical :: l_fix_neg_pvol_wat
    !> True to fix impaction scavenging bugs
    logical :: l_fix_ukca_impscav
    !> True to correct sea-salt density
    logical :: l_fix_nacl_density
    !> if True the surface type used by the aerosol dry deposition is provided
    !> by the parent, rather than being inferred from roughness length in
    !> GLOMAP.
    logical :: l_improve_aero_drydep
    !> True to fix bugs in the calculation of aerosol water content values.
    logical :: l_fix_ukca_water_content
    !> True to fix probability density fn. of updraft velocities in Activate
    logical :: l_fix_ukca_activate_pdf
    !> True to fix CDNC vertical replication bug in Activate
    logical :: l_fix_ukca_activate_vert_rep
    !> True to reproduce effects of an old bug in the calculation of updraft
    !> pdf spread related to TKE indexing in the Unified Model
    logical :: l_bug_repro_tke_index
    !> True to update aerosol component hygroscopicities to kappa-Kohler values
    !> and fix bug in calculation of volume-weighted hygroscopicity value
    logical :: l_fix_ukca_hygroscopicities
    !> True for dust and microplastics being subjected to nuc scav, conden,
    !> coag, ageing, and activation
    logical :: l_dust_mp_ageing
    !> Control argument for skipping set up of constants if already done
    logical :: l_skip_const_setup
    !> True if the atmosphere model is using the PC2 cloud scheme
    logical :: l_cloud_pc2
    !> True if UKCA is using a scheme that involves stratospheric chemistry
    !> i.e. Std Strat, Strattrop or CRI-strat
    logical :: l_strat_chem
    !> True to read photolysis rates from offline_photol_rates_file, rather
    !> than calculating them online
    logical :: l_offline_photol

    !> path to offline photolysis rates file
    character(len=256) :: offline_photol_rates_file
    !> path to environment namelist file
    character(len=256) :: environment_data_file
    !> path to initial tracer file
    character(len=256) :: initial_tracer_file
    !> path to initial non-transported prognostics (NTP) file
    character(len=256) :: initial_ntp_file
    !> directory for output files, relative to the working directory (empty
    !> means the working directory)
    character(len=256) :: output_dir

  endtype box_config_type

contains

  subroutine read_box_config(filename, cfg)

    !! Reads the box model configuration from a user-provided namelist file and
    !! stores the configuration in a box_config_type type.

    use box_debug_mod, only: is_debug_level
    use box_err_codes_mod, only: box_errcode_config_namelist
    use ukca_missing_data_mod, only: imdi

    !> Name of the namelist file to read
    character(len=*), intent(in)  :: filename
    !> The resulting box model configuration read from the namelist file
    type(box_config_type), intent(out) :: cfg
    !> Routine name for logging and error reporting
    character(len=ukca_maxlen_procname), parameter :: &
      routine_name = mod_name//":read_box_config"
    !> I/O status for opening the namelist file
    integer :: iostat_open
    !> I/O status for reading each namelist section
    integer :: iostat_read
    !> I/O message from opening or reading the namelist file
    character(len=256) :: iomsg
    !> Error code for error reporting
    integer :: err_code
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: err_msg
    !> Debug level to start recording debug message
    integer, parameter :: min_debug_level = 1
    !> unit for opening file
    integer :: unit
    !> Loop index
    integer :: i
    !> Array of namelist names
    character(len=16), dimension(10), parameter :: nml_names = [ &
                                                   "general_config  ", &
                                                   "aerosol         ", &
                                                   "chemistry       ", &
                                                   "constants       ", &
                                                   "deposition      ", &
                                                   "emissions       ", &
                                                   "feedbacks       ", &
                                                   "landsurface     ", &
                                                   "photolysis      ", &
                                                   "IO              "]

    !> model duration (seconds)
    integer :: model_duration
    !> starting year of model
    integer :: start_year
    !> starting month of model
    integer :: start_month
    !> starting day of model
    integer :: start_day
    !> starting hour of model
    integer :: start_hour
    !> starting minute of model
    integer :: start_minute
    !> starting second of model
    integer :: start_second
    !> Chemistry scheme to use
    integer :: i_ukca_chem
    !> Chemical mechanism version identifier
    integer :: i_ukca_chem_version
    !> No. of N-R solver iterations before time step is halved
    integer :: nrsteps
    !> Backward Euler timestep (seconds)
    integer :: dts0
    !> Method for controlling age reset to 0
    integer :: i_ageair_reset_method
    !> Max. level for reset (Method 1)
    integer :: max_ageair_reset_level
    !> Error handling method to use
    integer :: i_error_method
    !> Number of iterations for B-E Solver
    integer :: nit
    !> Iteration to start quasi-Newton step (2-50, 2 recommended)
    integer :: i_ukca_quasinewton_start
    !> Iteration to stop quasi-Newton step (2-50, 3 recommended)
    integer :: i_ukca_quasinewton_end
    !> Method of treating top boundary for certain species in stratospheric
    !> schemes
    integer :: i_ukca_topboundary
    !> 0 = default (5 reactions); 1 = JPL-15 recommended coeff. 2 = JPL-15 +
    !> bromine reactions
    integer :: i_ukca_hetconfig
    !> maximum INFERNO emission level
    integer :: i_inferno_emi
    !> Sea-air DMS exchange scheme to use
    integer :: i_ukca_dms_flux
    !> Choice for flash-freq parameterisation (1 = Price & Rind, 2 = Luhar et
    !> al., 3 = external lightning scheme)
    integer :: i_ukca_light_param
    !> Photolysis scheme: 0 = off, 1 = stratospheric only, 2 = offline/2-D,
    !> 3 = Fast-JX
    integer :: i_photol_scheme
    !> Timestep number at which environment summary diagnostics should be
    !> printed to log file
    integer :: env_log_step
    !> Options for tuning BC absorption via adjusting BC mass density and
    !> refractive index mixing approximations
    integer :: i_ukca_tune_bc
    !> Sea-salt emission options
    integer :: i_primss_method
    !> No. of substeps for nucleation/sedimentation
    integer :: i_mode_nzts
    !> MODE aerosol scheme to use
    integer :: i_mode_setup
    !> Parameterisation method for boundary layer nucleation 1=activation;
    !> 2=kinetic; 3=organic mediated (as per Metzger et al, PNAS, 2010) -
    !> required when 'l_mode_bhn_on' is true.
    integer :: i_mode_bln_param_method
    !> Choice of nucl. scavenging coefficients: 1=original, 2=ECHAM5-HAM,
    !> 3=as(1) but no scav of modes 6&7
    integer :: i_mode_nucscav
    !> Activation scheme to use
    integer :: i_ukca_activation_scheme
    !> Value of nwbins in Activate (1-20) See Rosalind West paper for details
    !> doi:10.5194/acp-14-6369-2014
    integer :: i_ukca_nwbins
    !> Number of surface types considered in interactive dry deposition
    integer :: ntype
    !> fast-jx photolysis mode above cutoff (1=lookup tables, 2=fast-jx +
    !> lookup tables, 3=fast-jx)
    integer :: fastjx_mode
    !> number of wavelengths to use in fast-jx. Options are 8, 12 or 18
    integer :: fastjx_numwl
    !> apply solar variability to photolysis (fast-jx only). 0 = no solar
    !> cycle, 1 = observed cycle, 2 = average cycle.
    integer :: i_solcylc_type
    !> 1st year for the solar cycle (used when i_solcylc_type = 1)
    integer :: solcylc_start_year

    !> Thickness of surface soil layer (m)
    real    :: dzsoil_layer1
    !> Model timestep in seconds (an integer no of timesteps is expected in 1
    !> hour)
    real    :: timestep
    !> Max. height (m) for reset (Method 2)
    real    :: max_ageair_reset_height
    !> Maximum height at which to integrate chemistry with the explicit B-E
    !> Offline Oxidants scheme
    real    :: max_z_for_offline_chem
    !> Cut-off Pressure for tabulated photolysis
    real    :: fastjx_prescutoff
    !> Fraction of SO2 emissions as aerosol(%)
    real    :: mode_parfrac
    !> Marine DMS emission scaling factor
    real    :: seadms_ems_scaling
    !> Sea salt emission scaling factor
    real    :: sea_salt_ems_scaling
    !> Marine POM emission scaling factor
    real    :: marine_pom_ems_scaling
    !> Lightning NOx emissions scaling factor
    real    :: lightnox_scale_fac
    !> Anthropogenic SO2 emissions scaling factor
    real    :: anth_so2_ems_scaling
    !> Scaling factor for production of SOA from monoterpene
    real    :: soa_yield_scaling_mt
    !> Scaling factor for production of SOA from isoprene
    real    :: soa_yield_scaling_isop
    !> SO2 dry deposition velocity scaling factor
    real    :: dry_depvel_so2_scaling
    !> Activation dry radius (nm)
    real    :: mode_activation_dryr
    !> Scaling factor for the dry deposition velocity for the accumulation mode
    real    :: dry_depvel_acc_scaling
    !> Scaling factor for scavenging parameters for the accumulation and coarse
    !> modes
    real    :: acc_cor_scav_scaling
    !> Fraction of in-cloud oxidised SO2 removed by precipitation
    real    :: mode_incld_so2_rfrac
    !> Biomass-burning emissions scaling
    real    :: biom_aer_ems_scaling
    !> value for fitting coefficient a of the interactive cloud pH code
    real    :: ph_fit_coeff_a
    !> value for fitting coefficient b of the interactive cloud pH code
    real    :: ph_fit_coeff_b
    !> y-intercept value of the relationship for the interactive cloud pH code
    real    :: ph_fit_intercept
    !> Lower limit for std. dev. of updraft velocity pdf used in Activate
    !> (default: 0.01 m/s).
    real    :: sigwmin
    !> HNO3 uptake coefficient for nitrate
    real    :: hno3_uptake_coeff
    !> Scaling factor for standard deviation of updraught velocities
    real    :: sigma_updraught_scaling
    !> Configurable universal gas constant R (J/mol/K)
    real    :: const_rmol
    !> Configurable temperature at which sea water freezes (K)
    real    :: const_tfs
    !> Configurable density of pure water (kg/m3)
    real    :: const_rho_water
    !> Configurable density of sea water (kg/m3)
    real    :: const_rhosea
    !> Configurable latent heat of condensation of water at 0 degC (J/kg)
    real    :: const_lc
    !> Configurable number of molecules in 1 mole (Avogadro constant)
    real    :: const_avogadro
    !> Configurable Boltzmann constant (J K-1)
    real    :: const_boltzmann
    !> Configurable density of SO4 particle (kg/m3)
    real    :: const_rho_so4
    !> EW (x) grid spacing in radians
    real    :: delta_lambda
    !> NS (y) grid spacing in radians
    real    :: delta_phi

    !> True if UKCA is expected to use a 360-day calendar for applying a top
    !> boundary condition in stratospheric chemistry schemes and/or for
    !> validating external emissions. (Emissions registered with a day-of-week
    !> scaling requirement can't be used with a 360-day calendar).
    logical :: l_cal360
    !> True for aerosol precursor chemistry
    logical :: l_ukca_chem_aero
    !> True for GLOMAP-mode aerosol scheme
    logical :: l_ukca_mode
    !> True for age-of-air scheme
    logical :: l_ukca_ageair
    !> True to set all non-valid diagnostic field data to missing data value
    logical :: l_blankout_invalid_diags
    !> True to use a timer routine for timing sub-models
    logical :: l_timer
    !> True to turn on perturbed parameter ensemble (PPE) scaling parameters
    logical :: l_ukca_scale_ppe
    !> True to turn off dry deposition
    logical :: l_ukca_drydep_off
    !> True to turn off wet deposition
    logical :: l_ukca_wetdep_off
    !> Include additional print output specific to ASAD
    logical :: l_ukca_debug_asad
    !> True for interactive dry deposition
    logical :: l_ukca_intdd
    !> True to use Luhar et al. (2018) oceanic O3 dry-deposition scheme
    logical :: l_ukca_ddepo3_ocean
    !> True to apply dry deposition losses only in level 1
    logical :: l_ukca_ddep_lev1
    !> True if considering the impact of surface wetness on dry deposition
    logical :: l_ukca_dry_dep_so2wet
    !> True when using JULES-based interactive dry deposition routines
    logical :: l_deposition_jules
    !> True to use quasi-Newton (Broyden) method to reduce no. of iterations in
    !> N-R solver step
    logical :: l_ukca_quasinewton
    !> True to handle lumped tracers in stratospheric chemistry schemes
    logical :: l_tracer_lumping
    !> True to stop transport of peroxy radicals in StratTrop/CRI scheme
    logical :: l_ukca_ro2_ntp
    !> True for RO2-permutation chemistry in StratTrop/CRI scheme
    logical :: l_ukca_ro2_perm
    !> True for calculating interactive cloud pH values (F for global value of
    !> 5)
    logical :: l_ukca_intph
    !> True for heterogeneous polar stratospheric cloud chemistry
    logical :: l_ukca_het_psc
    !> True to limit the formation of NAT in polar stratospheric clouds
    !> (type 1) to heights above 1 km
    logical :: l_ukca_limit_nat
    !> True to use surface area density climatology for heterogeneous PSC chem.
    logical :: l_ukca_sa_clim
    !> True for tropospheric het. chemistry
    logical :: l_ukca_trophet
    !> Allows the use of heterogeneous chemistry on aerosol surfaces from
    !> CLASSIC within UKCA.
    logical :: l_ukca_classic_hetchem
    !> True if UKCA is expecting to apply Photolysis rates in the solver and
    !> hence needs the rates from the parent
    logical :: l_use_photolysis
    !> True for interactive bVOC emissions
    logical :: l_ukca_ibvoc
    !> True for INFERNO fire emissions
    logical :: l_ukca_inferno
    !> True for INFERNO CH4 fire emissions
    logical :: l_ukca_inferno_ch4
    !> True for interactive expvolc emissions
    logical :: l_ukca_so2ems_expvolc
    !> True for expvolc emissions with plumeria
    logical :: l_ukca_so2ems_plumeria
    !> True for interactive wetland CH4 emissions
    logical :: l_ukca_qch4inter
    !> True when running UKCA in CH4 emissions-driven mode
    logical :: l_ukca_emsdrvn_ch4
    !> Apply scaling to marine DMS emissions.
    logical :: l_ukca_scale_seadms_ems
    !> True to use LOG(p) to distribute lightning NOx in the vertical
    logical :: l_ukca_linox_scaling
    !> Apply scaling factor to SOA production from monoterpene
    logical :: l_ukca_scale_soa_yield_mt
    !> Apply scaling factor to SOA production from isoprene
    logical :: l_ukca_scale_soa_yield_isop
    !> True to support full range of vertical scaling options for 2D emission
    !> fields.
    logical :: l_support_ems_vertprof
    !> True to support the provision of offline emissions in grid-box units
    logical :: l_support_ems_gridbox_units
    !> True to suppress all tracer updates from emissions and boundary layer
    !> mixing (Emissions diagnostics are unaffected)
    logical :: l_suppress_ems
    !> True for H2O feedback from chemistry
    logical :: l_ukca_h2o_feedback
    !> True if using precipitation diagnostics from a parameterized convection
    !> scheme
    logical :: l_param_conv
    !> True if using partial land points at coasts
    logical :: l_ctile
    !> True if external O3, used for troposphere only schemes, is expected as a
    !> mean value for each domain row (i.e. zonal mean if lat const. in row)
    logical :: l_zon_av_ozone
    !> True to include hydrogen conservation when 'l_ukca_h2o_feedback' is true
    logical :: l_ukca_conserve_h
    !> True if using external values for CO2, CH4, O2, H2 and N2 in chemistry
    logical :: l_chem_environ_gas_scalars
    !> True if using an external CO2 field in chemistry
    logical :: l_chem_environ_co2_fld
    !> True if prescribing surface CH4
    logical :: l_ukca_prescribech4
    !> True to use CLASSIC SO4 for het. chem.
    logical :: l_use_classic_so4
    !> True to use CLASSIC black carbon for het. chem. (RAQ scheme only)
    logical :: l_use_classic_soot
    !> True to use CLASSIC organic carbon from fossil fuels for het. chem.
    !> (RAQ only)
    logical :: l_use_classic_ocff
    !> True to use CLASSIC biogenic secondary organic aerosol for het. chem.
    !> (RAQ only)
    logical :: l_use_classic_biogenic
    !> True to use CLASSIC sea salt for het. chem. (RAQ only)
    logical :: l_use_classic_seasalt
    !> True to use gridbox volume in diagnostic calculations. (This is required
    !> for UM diagnostics and to enable use of ASAD framework diagnostics in
    !> non-UM applications.)
    logical :: l_use_gridbox_volume
    !> True to use mass of air in grid box in prognostic and/or diagnostic
    !> calculations. (Note that GLOMAP-mode prognostics will run with or
    !> without this option giving equivalent but not bit-comparable results.
    !> The option is required for the stratospheric chemistry schemes and for
    !> UM diagnostics.)
    logical :: l_use_gridbox_mass
    !> True if using external fields for relative humidity, clear-sky relative
    !> humidity and/or saturation vapour pressure
    logical :: l_environ_rel_humid
    !> True to fix cloud_frac offset bug
    logical :: l_fix_ukca_cloud_frac
    !> True to fix dry deposition velocities
    logical :: l_fix_improve_drydep
    !> True to use correct surface resistance of water when calculating dry
    !> deposition of SO2
    logical :: l_fix_drydep_so2_water
    !> True to fix H2 deposition to shrub/soil
    logical :: l_fix_ukca_h2dd_x
    !> True to fix water vapour units in B-E Offline Oxidants scheme
    logical :: l_fix_ukca_offox_h2o_fac
    !> True to fix storage of H2SO4 in ASAD N-R schemes for updating in GLOMAP
    logical :: l_fix_ukca_h2so4_ystore
    !> True for binary homogeneous sulphate nucleation
    logical :: l_mode_bhn_on
    !> True for boundary layer sulphate nucleation
    logical :: l_mode_bln_on
    !> True for aerosol dry deposition
    logical :: l_ddepaer
    !> True for turning on nucleation scavenging (rainout)
    logical :: l_aero_rainout
    !> True for convective rainout in UKCA
    logical :: l_cv_rainout
    !> True for turning on impaction scavenging
    logical :: l_impc_scav
    !> True for turning on the Slinn impaction scheme for dust and
    !> microplastics
    logical :: l_dust_mp_slinn_impc_scav
    !> True for primary sea-salt emissions
    logical :: l_ukca_primss
    !> True for primary sulphate emissions
    logical :: l_ukca_primsu
    !> True for primary dust emissions
    logical :: l_ukca_primdu
    !> True for primary BC/OC emissions
    logical :: l_ukca_primbcoc
    !> True for primary marine OC aerosol emissions
    logical :: l_ukca_prim_moc
    !> True for primary biofuel BC/OC emissions
    logical :: l_bcoc_bf
    !> True for primary biomass BC/OC emissions
    logical :: l_bcoc_bm
    !> True for primary fossil fuel BC/OC emissions
    logical :: l_bcoc_ff
    !> True to apply scaling factor to biomass burning BC/OC aerosol emissions
    logical :: l_ukca_scale_biom_aer_ems
    !> True for fine mode NO3/NH4 emissions
    logical :: l_ukca_fine_no3_prod
    !> True for coarse mode NO3 emissions
    logical :: l_ukca_coarse_no3_prod
    !> True for nitrate emissions in MODE
    logical :: l_no3_prod_in_aero_step
    !> True to apply scaling factor to sea salt emissions
    logical :: l_ukca_scale_sea_salt_ems
    !> True to apply scaling factor to marine particulate organic matter
    logical :: l_ukca_scale_marine_pom_ems
    !> True for microplastic fragment emissions
    logical :: l_ukca_mp_fragment
    !> True for microplastic fibre emissions
    logical :: l_ukca_mp_fibre
    !> Provide output for calculating direct radiative effects of aerosols
    !> using RADAER
    logical :: l_ukca_radaer
    !> True to include total number concentration of active aerosol in
    !> non-transported prognostics (e.g. for combination with an external cloud
    !> mask for calculating CDNC in the UM hybrid resolution model)
    logical :: l_ntpreq_n_activ_sum
    !> True to include to include the dry diameter for nucleation soluble mode
    logical :: l_ntpreq_dryd_nuc_sol
    !> True for diagnosing UKCA CCN at fixed supersaturation
    logical :: l_ukca_sfix
    !> True to check, trap and fix for negative values in 'pvol' and 'mdwat'
    logical :: l_fix_neg_pvol_wat
    !> True to fix impaction scavenging bugs
    logical :: l_fix_ukca_impscav
    !> True to correct sea-salt density
    logical :: l_fix_nacl_density
    !> if True the surface type used by the aerosol dry deposition is provided
    !> by the parent, rather than being inferred from roughness length in
    !> GLOMAP.
    logical :: l_improve_aero_drydep
    !> True to fix bugs in the calculation of aerosol water content values.
    logical :: l_fix_ukca_water_content
    !> True to fix probability density fn. of updraft velocities in Activate
    logical :: l_fix_ukca_activate_pdf
    !> True to fix CDNC vertical replication bug in Activate
    logical :: l_fix_ukca_activate_vert_rep
    !> True to reproduce effects of an old bug in the calculation of updraft
    !> pdf spread related to TKE indexing in the Unified Model
    logical :: l_bug_repro_tke_index
    !> True to update aerosol component hygroscopicities to kappa-Kohler values
    !> and fix bug in calculation of volume-weighted hygroscopicity value
    logical :: l_fix_ukca_hygroscopicities
    !> True for dust and microplastics being subjected to nuc scav, conden,
    !> coag, ageing, and activation
    logical :: l_dust_mp_ageing
    !> Control argument for skipping set up of constants if already done
    logical :: l_skip_const_setup
    !> True if the atmosphere model is using the PC2 cloud scheme
    logical :: l_cloud_pc2
    !> True if UKCA is using a scheme that involves stratospheric chemistry
    !> i.e. Std Strat, Strattrop or CRI-strat
    logical :: l_strat_chem
    !> True to read photolysis rates from offline_photol_rates_file, rather
    !> than calculating them online
    logical :: l_offline_photol

    !> path to offline photolysis rates file
    character(len=256) :: offline_photol_rates_file
    !> path to environment namelist file
    character(len=256) :: environment_data_file
    !> path to initial tracer file
    character(len=256) :: initial_tracer_file
    !> path to initial non-transported prognostics (NTP) file
    character(len=256) :: initial_ntp_file
    !> directory for output files, relative to the working directory (empty
    !> means the working directory)
    character(len=256) :: output_dir

    namelist /general_config/ env_log_step, &
      i_ageair_reset_method, &
      i_error_method, &
      i_ukca_chem, &
      i_ukca_chem_version, &
      max_ageair_reset_level, &
      model_duration, &
      start_day, &
      start_hour, &
      start_minute, &
      start_month, &
      start_second, &
      start_year, &
      l_blankout_invalid_diags, &
      l_cal360, &
      l_chem_environ_co2_fld, &
      l_chem_environ_gas_scalars, &
      l_ctile, &
      l_environ_rel_humid, &
      l_fix_ukca_cloud_frac, &
      l_param_conv, &
      l_timer, &
      l_tracer_lumping, &
      l_ukca_ageair, &
      l_ukca_debug_asad, &
      l_ukca_scale_ppe, &
      l_use_gridbox_mass, &
      l_use_gridbox_volume, &
      l_zon_av_ozone, &
      max_ageair_reset_height, &
      max_z_for_offline_chem, &
      timestep, &
      delta_lambda, &
      delta_phi

    namelist /aerosol/ i_mode_bln_param_method, &
      i_mode_nzts, &
      i_mode_setup, &
      l_bug_repro_tke_index, &
      l_dust_mp_ageing, &
      l_dust_mp_slinn_impc_scav, &
      l_fix_nacl_density, &
      l_fix_neg_pvol_wat, &
      l_fix_ukca_activate_pdf, &
      l_fix_ukca_activate_vert_rep, &
      l_fix_ukca_hygroscopicities, &
      l_fix_ukca_impscav, &
      l_fix_ukca_water_content, &
      l_improve_aero_drydep, &
      l_mode_bhn_on, &
      l_mode_bln_on, &
      l_ntpreq_dryd_nuc_sol, &
      l_ntpreq_n_activ_sum, &
      l_ukca_mode, &
      l_ukca_sfix, &
      mode_activation_dryr, &
      mode_incld_so2_rfrac, &
      sigwmin

    namelist /chemistry/ dts0, &
      i_ukca_hetconfig, &
      i_ukca_quasinewton_end, &
      i_ukca_quasinewton_start, &
      i_ukca_topboundary, &
      nit, &
      nrsteps, &
      l_fix_ukca_h2so4_ystore, &
      l_fix_ukca_offox_h2o_fac, &
      l_ukca_chem_aero, &
      l_ukca_classic_hetchem, &
      l_ukca_het_psc, &
      l_ukca_intph, &
      l_ukca_limit_nat, &
      l_ukca_prescribech4, &
      l_ukca_quasinewton, &
      l_ukca_ro2_ntp, &
      l_ukca_ro2_perm, &
      l_ukca_sa_clim, &
      l_ukca_trophet, &
      l_use_classic_biogenic, &
      l_use_classic_ocff, &
      l_use_classic_seasalt, &
      l_use_classic_so4, &
      l_use_classic_soot, &
      ph_fit_coeff_a, &
      ph_fit_coeff_b, &
      ph_fit_intercept

    namelist /constants/ l_skip_const_setup, &
      const_avogadro, &
      const_boltzmann, &
      const_lc, &
      const_rho_so4, &
      const_rho_water, &
      const_rhosea, &
      const_rmol, &
      const_tfs

    namelist /deposition/ i_mode_nucscav, &
      l_aero_rainout, &
      l_cv_rainout, &
      l_ddepaer, &
      l_deposition_jules, &
      l_fix_drydep_so2_water, &
      l_fix_improve_drydep, &
      l_fix_ukca_h2dd_x, &
      l_impc_scav, &
      l_ukca_ddep_lev1, &
      l_ukca_ddepo3_ocean, &
      l_ukca_dry_dep_so2wet, &
      l_ukca_drydep_off, &
      l_ukca_intdd, &
      l_ukca_wetdep_off, &
      acc_cor_scav_scaling, &
      dry_depvel_acc_scaling, &
      dry_depvel_so2_scaling

    namelist /emissions/ i_inferno_emi, &
      i_primss_method, &
      i_ukca_dms_flux, &
      i_ukca_light_param, &
      l_bcoc_bf, &
      l_bcoc_bm, &
      l_bcoc_ff, &
      l_no3_prod_in_aero_step, &
      l_support_ems_gridbox_units, &
      l_support_ems_vertprof, &
      l_suppress_ems, &
      l_ukca_coarse_no3_prod, &
      l_ukca_emsdrvn_ch4, &
      l_ukca_fine_no3_prod, &
      l_ukca_ibvoc, &
      l_ukca_inferno, &
      l_ukca_inferno_ch4, &
      l_ukca_linox_scaling, &
      l_ukca_mp_fibre, &
      l_ukca_mp_fragment, &
      l_ukca_prim_moc, &
      l_ukca_primbcoc, &
      l_ukca_primdu, &
      l_ukca_primss, &
      l_ukca_primsu, &
      l_ukca_qch4inter, &
      l_ukca_scale_biom_aer_ems, &
      l_ukca_scale_marine_pom_ems, &
      l_ukca_scale_sea_salt_ems, &
      l_ukca_scale_seadms_ems, &
      l_ukca_scale_soa_yield_isop, &
      l_ukca_scale_soa_yield_mt, &
      l_ukca_so2ems_expvolc, &
      l_ukca_so2ems_plumeria, &
      anth_so2_ems_scaling, &
      biom_aer_ems_scaling, &
      hno3_uptake_coeff, &
      lightnox_scale_fac, &
      marine_pom_ems_scaling, &
      mode_parfrac, &
      sea_salt_ems_scaling, &
      seadms_ems_scaling, &
      soa_yield_scaling_isop, &
      soa_yield_scaling_mt

    namelist /feedbacks/ i_ukca_activation_scheme, &
      i_ukca_nwbins, &
      i_ukca_tune_bc, &
      l_ukca_conserve_h, &
      l_ukca_h2o_feedback, &
      l_ukca_radaer, &
      sigma_updraught_scaling

    namelist /landsurface/ ntype, dzsoil_layer1

    namelist /IO/ environment_data_file, &
      initial_tracer_file, &
      initial_ntp_file, &
      offline_photol_rates_file, &
      output_dir

    namelist /photolysis/ fastjx_mode, &
      fastjx_numwl, &
      i_photol_scheme, &
      i_solcylc_type, &
      solcylc_start_year, &
      l_cloud_pc2, &
      l_strat_chem, &
      l_use_photolysis, &
      fastjx_prescutoff, &
      l_offline_photol

    ! general integer defaults
    env_log_step = 1
    i_ageair_reset_method = 1
    i_error_method = 2
    i_ukca_chem = 51
    i_ukca_chem_version = 132
    max_ageair_reset_level = 10
    model_duration = 86400
    start_day = 1
    start_hour = 0
    start_minute = 0
    start_month = 1
    start_second = 0
    start_year = 2000

    ! aerosol integer defaults
    i_mode_bln_param_method = 1
    i_mode_nzts = 15
    i_mode_setup = 2

    ! chemistry integer defaults
    dts0 = 300
    i_ukca_hetconfig = 0
    i_ukca_quasinewton_start = 2
    i_ukca_quasinewton_end = 3
    i_ukca_topboundary = 0
    nit = 1
    nrsteps = 45

    ! deposition integer defaults
    i_mode_nucscav = 3

    ! emissions integer defaults
    i_inferno_emi = 20
    i_primss_method = 2
    i_ukca_dms_flux = 1
    i_ukca_light_param = 0

    ! feedbacks integer defaults
    i_ukca_activation_scheme = 1
    i_ukca_nwbins = 20
    i_ukca_tune_bc = 0

    ! landsurface integer defaults
    ntype = 9

    ! photolysis integer defaults
    fastjx_mode = 1
    fastjx_numwl = 18
    i_photol_scheme = 0
    i_solcylc_type = 2
    solcylc_start_year = imdi

    ! general real defaults
    max_ageair_reset_height = 2000.0
    max_z_for_offline_chem = 20000.0
    timestep = 3600.0
    delta_lambda = 0.0327249
    delta_phi = 0.0218166

    ! aerosol real defaults
    mode_activation_dryr = 37.5
    mode_incld_so2_rfrac = 1.0
    sigwmin = 0.1

    ! chemistry real defaults
    ph_fit_coeff_a = 0.142
    ph_fit_coeff_b = -0.931
    ph_fit_intercept = 4.65

    ! constants real defaults
    const_avogadro = 6.022e23
    const_boltzmann = 1.3804e-23
    const_lc = 2.501e6
    const_rho_so4 = 1769.0
    const_rho_water = 1000.0
    const_rhosea = 1026.0
    const_rmol = 8.314
    const_tfs = 271.35

    ! deposition real defaults
    acc_cor_scav_scaling = 1.0
    dry_depvel_acc_scaling = 1.0
    dry_depvel_so2_scaling = 1.0

    ! emissions real defaults
    anth_so2_ems_scaling = 1.0
    biom_aer_ems_scaling = 1.0
    hno3_uptake_coeff = 0.193
    lightnox_scale_fac = 1.0
    marine_pom_ems_scaling = 1.0
    mode_parfrac = 2.5
    sea_salt_ems_scaling = 1.0
    seadms_ems_scaling = 1.0
    soa_yield_scaling_isop = 1.0
    soa_yield_scaling_mt = 1.0

    ! feedbacks real defaults
    sigma_updraught_scaling = 1.0

    ! landsurface real defaults
    dzsoil_layer1 = 0.1

    ! photolysis real defaults
    fastjx_prescutoff = 20.0

    ! general logical defaults
    l_blankout_invalid_diags = .false.
    l_cal360 = .false.
    l_chem_environ_co2_fld = .false.
    l_chem_environ_gas_scalars = .false.
    l_ctile = .false.
    l_environ_rel_humid = .false.
    l_fix_ukca_cloud_frac = .false.
    l_param_conv = .false.
    l_timer = .false.
    l_tracer_lumping = .false.
    l_ukca_ageair = .false.
    l_ukca_debug_asad = .false.
    l_ukca_scale_ppe = .false.
    l_use_gridbox_mass = .false.
    l_use_gridbox_volume = .false.
    l_zon_av_ozone = .false.

    ! aerosol logical defaults
    l_bug_repro_tke_index = .false.
    l_dust_mp_ageing = .false.
    l_dust_mp_slinn_impc_scav = .false.
    l_fix_nacl_density = .false.
    l_fix_neg_pvol_wat = .false.
    l_fix_ukca_activate_pdf = .false.
    l_fix_ukca_activate_vert_rep = .false.
    l_fix_ukca_hygroscopicities = .false.
    l_fix_ukca_impscav = .false.
    l_fix_ukca_water_content = .false.
    l_improve_aero_drydep = .false.
    l_mode_bhn_on = .true.
    l_mode_bln_on = .true.
    l_ntpreq_dryd_nuc_sol = .false.
    l_ntpreq_n_activ_sum = .false.
    l_ukca_mode = .false.
    l_ukca_sfix = .false.

    ! chemistry logical defaults
    l_fix_ukca_h2so4_ystore = .false.
    l_fix_ukca_offox_h2o_fac = .false.
    l_ukca_chem_aero = .false.
    l_ukca_classic_hetchem = .false.
    l_ukca_het_psc = .false.
    l_ukca_intph = .false.
    l_ukca_limit_nat = .false.
    l_ukca_prescribech4 = .false.
    l_ukca_quasinewton = .false.
    l_ukca_ro2_ntp = .false.
    l_ukca_ro2_perm = .false.
    l_ukca_sa_clim = .false.
    l_ukca_trophet = .false.
    l_use_classic_biogenic = .false.
    l_use_classic_ocff = .false.
    l_use_classic_seasalt = .false.
    l_use_classic_so4 = .false.
    l_use_classic_soot = .false.

    ! constants logical defaults
    l_skip_const_setup = .false.

    ! deposition logical defaults
    l_aero_rainout = .true.
    l_cv_rainout = .true.
    l_ddepaer = .false.
    l_deposition_jules = .false.
    l_fix_drydep_so2_water = .false.
    l_fix_improve_drydep = .false.
    l_fix_ukca_h2dd_x = .false.
    l_impc_scav = .false.
    l_ukca_ddep_lev1 = .false.
    l_ukca_ddepo3_ocean = .false.
    l_ukca_dry_dep_so2wet = .false.
    l_ukca_drydep_off = .true.
    l_ukca_intdd = .false.
    l_ukca_wetdep_off = .true.

    ! emissions logical defaults
    l_bcoc_bf = .false.
    l_bcoc_bm = .false.
    l_bcoc_ff = .false.
    l_no3_prod_in_aero_step = .false.
    l_support_ems_gridbox_units = .true.
    l_support_ems_vertprof = .true.
    l_suppress_ems = .false.
    l_ukca_coarse_no3_prod = .false.
    l_ukca_emsdrvn_ch4 = .false.
    l_ukca_fine_no3_prod = .false.
    l_ukca_ibvoc = .false.
    l_ukca_inferno = .false.
    l_ukca_inferno_ch4 = .false.
    l_ukca_linox_scaling = .false.
    l_ukca_mp_fibre = .false.
    l_ukca_mp_fragment = .false.
    l_ukca_prim_moc = .false.
    l_ukca_primbcoc = .false.
    l_ukca_primdu = .false.
    l_ukca_primss = .false.
    l_ukca_primsu = .false.
    l_ukca_qch4inter = .false.
    l_ukca_scale_biom_aer_ems = .false.
    l_ukca_scale_marine_pom_ems = .false.
    l_ukca_scale_sea_salt_ems = .false.
    l_ukca_scale_seadms_ems = .false.
    l_ukca_scale_soa_yield_isop = .false.
    l_ukca_scale_soa_yield_mt = .false.
    l_ukca_so2ems_expvolc = .false.
    l_ukca_so2ems_plumeria = .false.

    ! feedbacks logical defaults
    l_ukca_conserve_h = .false.
    l_ukca_h2o_feedback = .false.
    l_ukca_radaer = .false.

    ! photolysis logical defaults
    l_cloud_pc2 = .false.
    l_strat_chem = .false.
    l_use_photolysis = .false.
    l_offline_photol = .true.

    ! IO character defaults
    ! IO input files default to their standard names, next to the namelist
    environment_data_file = "env_namelist.nml"
    initial_tracer_file = "initial_tracers.txt"
    initial_ntp_file = "initial_ntp.txt"
    offline_photol_rates_file = ""
    output_dir = ""

    open(newunit=unit, file=filename, status='old', action='read', &
         iostat=iostat_open, iomsg=iomsg)

    if(iostat_open /= 0) then
      write(err_msg, "(4A)") "Error opening box config namelist file '", &
        trim(filename), "'. Original error: ", trim(iomsg)
      err_code = box_errcode_config_namelist
      call ereport(routine_name, err_code, err_msg)
    endif

    ! for each namelist loop over read logic
    do i = 1, size(nml_names)
      iostat_read = 0
      rewind(unit)
      select case(trim(nml_names(i)))
      case("general_config")
        read(unit, nml=general_config, iostat=iostat_read, iomsg=iomsg)
      case("chemistry")
        read(unit, nml=chemistry, iostat=iostat_read, iomsg=iomsg)
      case("photolysis")
        read(unit, nml=photolysis, iostat=iostat_read, iomsg=iomsg)
      case("emissions")
        read(unit, nml=emissions, iostat=iostat_read, iomsg=iomsg)
      case("aerosol")
        read(unit, nml=aerosol, iostat=iostat_read, iomsg=iomsg)
      case("landsurface")
        read(unit, nml=landsurface, iostat=iostat_read, iomsg=iomsg)
      case("deposition")
        read(unit, nml=deposition, iostat=iostat_read, iomsg=iomsg)
      case("constants")
        read(unit, nml=constants, iostat=iostat_read, iomsg=iomsg)
      case("feedbacks")
        read(unit, nml=feedbacks, iostat=iostat_read, iomsg=iomsg)
      case("IO")
        read(unit, nml=IO, iostat=iostat_read, iomsg=iomsg)
      case default
        err_code = box_errcode_config_namelist
        write(err_msg, "(2A)") "Unexpected namelist section called: ", &
          trim(nml_names(i))
        call ereport(routine_name, err_code, err_msg)
      endselect

      ! check if the section was missing and warn or if there was an actual
      ! read error
      if(is_iostat_end(iostat_read)) then
        err_code = -box_errcode_config_namelist
        write(err_msg, "(3A)") "Unable to find a namelist section for ", &
          trim(nml_names(i)), &
          " in the config file. Using default values for its options."
        call ereport(routine_name, err_code, err_msg)
      else if(iostat_read /= 0) then
        err_code = box_errcode_config_namelist
        write(err_msg, "(4A)") "Error recorded reading namelist section: ", &
          trim(nml_names(i)), '. Original error msg: ', trim(iomsg)
        call ereport(routine_name, err_code, err_msg)
      else if(is_debug_level(min_debug_level)) then
        write(umMessage, "(3A)") "Read namelist '", trim(nml_names(i)), "'"
        call umPrint(umMessage, src=routine_name)
      endif
    enddo

    close(unit)

    ! integer general config parameters
    cfg%env_log_step = env_log_step
    cfg%i_ageair_reset_method = i_ageair_reset_method
    cfg%i_error_method = i_error_method
    cfg%i_ukca_chem = i_ukca_chem
    cfg%i_ukca_chem_version = i_ukca_chem_version
    cfg%max_ageair_reset_level = max_ageair_reset_level
    cfg%model_duration = model_duration
    cfg%start_day = start_day
    cfg%start_hour = start_hour
    cfg%start_minute = start_minute
    cfg%start_month = start_month
    cfg%start_second = start_second
    cfg%start_year = start_year

    ! integer aerosol config parameters
    cfg%i_mode_bln_param_method = i_mode_bln_param_method
    cfg%i_mode_nzts = i_mode_nzts
    cfg%i_mode_setup = i_mode_setup

    ! integer chemistry config parameters
    cfg%dts0 = dts0
    cfg%i_ukca_hetconfig = i_ukca_hetconfig
    cfg%i_ukca_quasinewton_end = i_ukca_quasinewton_end
    cfg%i_ukca_quasinewton_start = i_ukca_quasinewton_start
    cfg%i_ukca_topboundary = i_ukca_topboundary
    cfg%nit = nit
    cfg%nrsteps = nrsteps

    ! integer deposition config parameters
    cfg%i_mode_nucscav = i_mode_nucscav

    ! integer emissions config parameters
    cfg%i_inferno_emi = i_inferno_emi
    cfg%i_primss_method = i_primss_method
    cfg%i_ukca_dms_flux = i_ukca_dms_flux
    cfg%i_ukca_light_param = i_ukca_light_param

    ! integer feedbacks config parameters
    cfg%i_ukca_activation_scheme = i_ukca_activation_scheme
    cfg%i_ukca_nwbins = i_ukca_nwbins
    cfg%i_ukca_tune_bc = i_ukca_tune_bc

    ! integer landsurface config parameters
    cfg%ntype = ntype

    ! integer photolysis config parameters
    cfg%fastjx_mode = fastjx_mode
    cfg%fastjx_numwl = fastjx_numwl
    cfg%i_photol_scheme = i_photol_scheme
    cfg%i_solcylc_type = i_solcylc_type
    cfg%solcylc_start_year = solcylc_start_year

    ! real general config parameters
    cfg%max_ageair_reset_height = max_ageair_reset_height
    cfg%max_z_for_offline_chem = max_z_for_offline_chem
    cfg%timestep = timestep
    cfg%delta_lambda = delta_lambda
    cfg%delta_phi = delta_phi

    ! real aerosol config parameters
    cfg%mode_activation_dryr = mode_activation_dryr
    cfg%mode_incld_so2_rfrac = mode_incld_so2_rfrac
    cfg%sigwmin = sigwmin

    ! real chemistry config parameters
    cfg%ph_fit_coeff_a = ph_fit_coeff_a
    cfg%ph_fit_coeff_b = ph_fit_coeff_b
    cfg%ph_fit_intercept = ph_fit_intercept

    ! real constants config parameters
    cfg%const_avogadro = const_avogadro
    cfg%const_boltzmann = const_boltzmann
    cfg%const_lc = const_lc
    cfg%const_rho_so4 = const_rho_so4
    cfg%const_rho_water = const_rho_water
    cfg%const_rhosea = const_rhosea
    cfg%const_rmol = const_rmol
    cfg%const_tfs = const_tfs

    ! real deposition config parameters
    cfg%acc_cor_scav_scaling = acc_cor_scav_scaling
    cfg%dry_depvel_acc_scaling = dry_depvel_acc_scaling
    cfg%dry_depvel_so2_scaling = dry_depvel_so2_scaling

    ! real emissions config parameters
    cfg%anth_so2_ems_scaling = anth_so2_ems_scaling
    cfg%biom_aer_ems_scaling = biom_aer_ems_scaling
    cfg%hno3_uptake_coeff = hno3_uptake_coeff
    cfg%lightnox_scale_fac = lightnox_scale_fac
    cfg%marine_pom_ems_scaling = marine_pom_ems_scaling
    cfg%mode_parfrac = mode_parfrac
    cfg%sea_salt_ems_scaling = sea_salt_ems_scaling
    cfg%seadms_ems_scaling = seadms_ems_scaling
    cfg%soa_yield_scaling_isop = soa_yield_scaling_isop
    cfg%soa_yield_scaling_mt = soa_yield_scaling_mt

    ! real feedbacks config parameters
    cfg%sigma_updraught_scaling = sigma_updraught_scaling

    ! real landsurface config parameters
    cfg%dzsoil_layer1 = dzsoil_layer1

    ! real photolysis config parameters
    cfg%fastjx_prescutoff = fastjx_prescutoff

    ! logical general config parameters
    cfg%l_blankout_invalid_diags = l_blankout_invalid_diags
    cfg%l_cal360 = l_cal360
    cfg%l_chem_environ_co2_fld = l_chem_environ_co2_fld
    cfg%l_chem_environ_gas_scalars = l_chem_environ_gas_scalars
    cfg%l_ctile = l_ctile
    cfg%l_environ_rel_humid = l_environ_rel_humid
    cfg%l_fix_ukca_cloud_frac = l_fix_ukca_cloud_frac
    cfg%l_param_conv = l_param_conv
    cfg%l_timer = l_timer
    cfg%l_tracer_lumping = l_tracer_lumping
    cfg%l_ukca_ageair = l_ukca_ageair
    cfg%l_ukca_debug_asad = l_ukca_debug_asad
    cfg%l_ukca_scale_ppe = l_ukca_scale_ppe
    cfg%l_use_gridbox_mass = l_use_gridbox_mass
    cfg%l_use_gridbox_volume = l_use_gridbox_volume
    cfg%l_zon_av_ozone = l_zon_av_ozone

    ! logical aerosol config parameters
    cfg%l_bug_repro_tke_index = l_bug_repro_tke_index
    cfg%l_dust_mp_ageing = l_dust_mp_ageing
    cfg%l_dust_mp_slinn_impc_scav = l_dust_mp_slinn_impc_scav
    cfg%l_fix_nacl_density = l_fix_nacl_density
    cfg%l_fix_neg_pvol_wat = l_fix_neg_pvol_wat
    cfg%l_fix_ukca_activate_pdf = l_fix_ukca_activate_pdf
    cfg%l_fix_ukca_activate_vert_rep = l_fix_ukca_activate_vert_rep
    cfg%l_fix_ukca_hygroscopicities = l_fix_ukca_hygroscopicities
    cfg%l_fix_ukca_impscav = l_fix_ukca_impscav
    cfg%l_fix_ukca_water_content = l_fix_ukca_water_content
    cfg%l_improve_aero_drydep = l_improve_aero_drydep
    cfg%l_mode_bhn_on = l_mode_bhn_on
    cfg%l_mode_bln_on = l_mode_bln_on
    cfg%l_ntpreq_dryd_nuc_sol = l_ntpreq_dryd_nuc_sol
    cfg%l_ntpreq_n_activ_sum = l_ntpreq_n_activ_sum
    cfg%l_ukca_mode = l_ukca_mode
    cfg%l_ukca_sfix = l_ukca_sfix

    ! logical chemistry config parameters
    cfg%l_fix_ukca_h2so4_ystore = l_fix_ukca_h2so4_ystore
    cfg%l_fix_ukca_offox_h2o_fac = l_fix_ukca_offox_h2o_fac
    cfg%l_ukca_chem_aero = l_ukca_chem_aero
    cfg%l_ukca_classic_hetchem = l_ukca_classic_hetchem
    cfg%l_ukca_het_psc = l_ukca_het_psc
    cfg%l_ukca_intph = l_ukca_intph
    cfg%l_ukca_limit_nat = l_ukca_limit_nat
    cfg%l_ukca_prescribech4 = l_ukca_prescribech4
    cfg%l_ukca_quasinewton = l_ukca_quasinewton
    cfg%l_ukca_ro2_ntp = l_ukca_ro2_ntp
    cfg%l_ukca_ro2_perm = l_ukca_ro2_perm
    cfg%l_ukca_sa_clim = l_ukca_sa_clim
    cfg%l_ukca_trophet = l_ukca_trophet
    cfg%l_use_classic_biogenic = l_use_classic_biogenic
    cfg%l_use_classic_ocff = l_use_classic_ocff
    cfg%l_use_classic_seasalt = l_use_classic_seasalt
    cfg%l_use_classic_so4 = l_use_classic_so4
    cfg%l_use_classic_soot = l_use_classic_soot

    ! logical constants config parameters
    cfg%l_skip_const_setup = l_skip_const_setup

    ! logical deposition config parameters
    cfg%l_aero_rainout = l_aero_rainout
    cfg%l_cv_rainout = l_cv_rainout
    cfg%l_ddepaer = l_ddepaer
    cfg%l_deposition_jules = l_deposition_jules
    cfg%l_fix_drydep_so2_water = l_fix_drydep_so2_water
    cfg%l_fix_improve_drydep = l_fix_improve_drydep
    cfg%l_fix_ukca_h2dd_x = l_fix_ukca_h2dd_x
    cfg%l_impc_scav = l_impc_scav
    cfg%l_ukca_ddep_lev1 = l_ukca_ddep_lev1
    cfg%l_ukca_ddepo3_ocean = l_ukca_ddepo3_ocean
    cfg%l_ukca_dry_dep_so2wet = l_ukca_dry_dep_so2wet
    cfg%l_ukca_drydep_off = l_ukca_drydep_off
    cfg%l_ukca_intdd = l_ukca_intdd
    cfg%l_ukca_wetdep_off = l_ukca_wetdep_off

    ! logical emissions config parameters
    cfg%l_bcoc_bf = l_bcoc_bf
    cfg%l_bcoc_bm = l_bcoc_bm
    cfg%l_bcoc_ff = l_bcoc_ff
    cfg%l_no3_prod_in_aero_step = l_no3_prod_in_aero_step
    cfg%l_support_ems_gridbox_units = l_support_ems_gridbox_units
    cfg%l_support_ems_vertprof = l_support_ems_vertprof
    cfg%l_suppress_ems = l_suppress_ems
    cfg%l_ukca_coarse_no3_prod = l_ukca_coarse_no3_prod
    cfg%l_ukca_emsdrvn_ch4 = l_ukca_emsdrvn_ch4
    cfg%l_ukca_fine_no3_prod = l_ukca_fine_no3_prod
    cfg%l_ukca_ibvoc = l_ukca_ibvoc
    cfg%l_ukca_inferno = l_ukca_inferno
    cfg%l_ukca_inferno_ch4 = l_ukca_inferno_ch4
    cfg%l_ukca_linox_scaling = l_ukca_linox_scaling
    cfg%l_ukca_mp_fibre = l_ukca_mp_fibre
    cfg%l_ukca_mp_fragment = l_ukca_mp_fragment
    cfg%l_ukca_prim_moc = l_ukca_prim_moc
    cfg%l_ukca_primbcoc = l_ukca_primbcoc
    cfg%l_ukca_primdu = l_ukca_primdu
    cfg%l_ukca_primss = l_ukca_primss
    cfg%l_ukca_primsu = l_ukca_primsu
    cfg%l_ukca_qch4inter = l_ukca_qch4inter
    cfg%l_ukca_scale_biom_aer_ems = l_ukca_scale_biom_aer_ems
    cfg%l_ukca_scale_marine_pom_ems = l_ukca_scale_marine_pom_ems
    cfg%l_ukca_scale_sea_salt_ems = l_ukca_scale_sea_salt_ems
    cfg%l_ukca_scale_seadms_ems = l_ukca_scale_seadms_ems
    cfg%l_ukca_scale_soa_yield_isop = l_ukca_scale_soa_yield_isop
    cfg%l_ukca_scale_soa_yield_mt = l_ukca_scale_soa_yield_mt
    cfg%l_ukca_so2ems_expvolc = l_ukca_so2ems_expvolc
    cfg%l_ukca_so2ems_plumeria = l_ukca_so2ems_plumeria

    ! feedbacks logical config parameters
    cfg%l_ukca_conserve_h = l_ukca_conserve_h
    cfg%l_ukca_h2o_feedback = l_ukca_h2o_feedback
    cfg%l_ukca_radaer = l_ukca_radaer

    ! photolysis logical config parameters
    cfg%l_cloud_pc2 = l_cloud_pc2
    cfg%l_strat_chem = l_strat_chem
    cfg%l_use_photolysis = l_use_photolysis
    cfg%l_offline_photol = l_offline_photol

    ! character IO config parameters
    ! relative input file paths are relative to the namelist's directory
    cfg%environment_data_file = resolve_path(environment_data_file, filename)
    cfg%initial_tracer_file = resolve_path(initial_tracer_file, filename)
    cfg%initial_ntp_file = resolve_path(initial_ntp_file, filename)
    cfg%offline_photol_rates_file = &
      resolve_path(offline_photol_rates_file, filename)
    cfg%output_dir = output_dir

    ! stop now, rather than part way through setup, if an input is missing
    call check_input_file(cfg%environment_data_file, "environment_data_file")
    call check_input_file(cfg%initial_tracer_file, "initial_tracer_file")
    call check_input_file(cfg%initial_ntp_file, "initial_ntp_file")
    call check_output_dir(cfg%output_dir)

    ! set the options that are derived from the ones read above
    call infer_config_options(cfg)

  endsubroutine read_box_config

  function resolve_path(path, namelist_file) result(resolved)

    !! Resolve a file path given in the box config namelist. A relative path
    !! is taken to be relative to the namelist file's directory, so a config
    !! folder can be run from any working directory.

    use box_err_codes_mod, only: box_errcode_config_namelist

    !> The path as given in the namelist
    character(len=*), intent(in) :: path
    !> Path to the namelist file the path was read from
    character(len=*), intent(in) :: namelist_file
    !> The resolved path
    character(len=256) :: resolved
    !> Position of the last '/' in the namelist file path
    integer :: i_slash
    !> Error code for error reporting
    integer :: err_code
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: err_msg

    ! an empty or absolute path, or a namelist in the working directory, needs
    ! no change
    resolved = path
    i_slash = index(namelist_file, '/', back=.true.)
    if(len_trim(path) == 0 .or. i_slash == 0 .or. path(1:1) == '/') return

    if(i_slash + len_trim(path) > len(resolved)) then
      write(err_msg, "(4A)") "Path too long after adding the namelist's ", &
        "directory: '", namelist_file(1:i_slash)//trim(path), "'"
      err_code = box_errcode_config_namelist
      call ereport(mod_name//":resolve_path", err_code, err_msg)
    endif
    resolved = namelist_file(1:i_slash)//trim(path)

  endfunction resolve_path

  subroutine check_input_file(path, option_name)

    !! Stop with an error if an input file named in the IO namelist does not
    !! exist.

    use box_err_codes_mod, only: box_errcode_config_namelist

    !> The resolved path to the input file
    character(len=*), intent(in) :: path
    !> Name of the IO namelist option that set the path
    character(len=*), intent(in) :: option_name
    !> Whether the file exists
    logical :: exists
    !> Error code for error reporting
    integer :: err_code
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: err_msg

    inquire(file=trim(path), exist=exists)

    if(.not. exists) then
      write(err_msg, "(5A)") "Input file not found: '", trim(path), &
        "' (set by ", option_name, " in the IO namelist)"
      err_code = box_errcode_config_namelist
      call ereport(mod_name//":check_input_file", err_code, err_msg)
    endif

  endsubroutine check_input_file

  subroutine check_output_dir(output_dir)

    !! Stop with an error if the output directory set in the IO namelist does
    !! not exist. An empty output directory means the working directory.

    use box_err_codes_mod, only: box_errcode_config_namelist

    !> The output directory
    character(len=*), intent(in) :: output_dir
    !> Whether the directory exists
    logical :: exists
    !> Error code for error reporting
    integer :: err_code
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: err_msg

    if(len_trim(output_dir) == 0) return

    ! the trailing '/' makes inquire only match a directory, not a file
    inquire(file=trim(output_dir)//'/', exist=exists)

    if(.not. exists) then
      write(err_msg, "(3A)") "Output directory not found: '", &
        trim(output_dir), "' (set by output_dir in the IO namelist)"
      err_code = box_errcode_config_namelist
      call ereport(mod_name//":check_output_dir", err_code, err_msg)
    endif

  endsubroutine check_output_dir

  function output_file_path(cfg, filename) result(path)

    !! Return the path to write an output file to: the file name inside the
    !! configured output directory.

    !> The box model configuration
    type(box_config_type), intent(in) :: cfg
    !> Name of the output file
    character(len=*), intent(in) :: filename
    !> Path to write the output file to
    character(len=512) :: path
    !> Length of the output directory path
    integer :: n

    n = len_trim(cfg%output_dir)
    if(n == 0) then
      path = filename
    else if(cfg%output_dir(n:n) == '/') then
      path = cfg%output_dir(1:n)//filename
    else
      path = cfg%output_dir(1:n)//'/'//filename
    endif

  endfunction output_file_path

  subroutine infer_config_options(cfg)

    !! Infers any configuration options that can be derived from the explicitly
    !! set parameters - help to reduce the number of config options in the
    !! namelist

    !> The box model configuration to add the inferred options to
    type(box_config_type), intent(inout) :: cfg

    ! chem_timestep always equals timestep in box model
    cfg%chem_timestep = int(cfg%timestep)

  endsubroutine infer_config_options

  subroutine print_box_config(cfg)

    !! Print the box model configuration to the log, grouped by namelist
    !! section.

    !> The box model configuration to print
    type(box_config_type), intent(in) :: cfg
    !> Routine name for logging
    character(len=*), parameter :: routine_name = mod_name//":print_box_config"
    !> Column at which values start, after the option name
    integer, parameter :: label_width = 45
    !> Formats for integer, real, scientific, logical and character values
    character(len=80) :: fmt_int, fmt_real, fmt_sci, fmt_log, fmt_char

    ! Create format strings that start the value at column label_width
    write(fmt_int, "(A, I0, A)") "(A, T", label_width, ", I0)"
    write(fmt_real, "(A, I0, A)") "(A, T", label_width, ", G0.5)"
    write(fmt_sci, "(A, I0, A)") "(A, T", label_width, ", ES11.4)"
    write(fmt_log, "(A, I0, A)") "(A, T", label_width, ", L1)"
    write(fmt_char, "(A, I0, A)") "(A, T", label_width, ", A)"

    call umPrint('', src=routine_name)
    call umPrint('='//repeat('=', 78)//'=', src=routine_name)
    call umPrint('  BOX MODEL CONFIGURATION', src=routine_name)
    call umPrint('='//repeat('=', 78)//'=', src=routine_name)
    call umPrint('', src=routine_name)

    ! General Configuration
    call umPrint('General Configuration:', src=routine_name)
    call print_field('  chem_timestep (s)', cfg%chem_timestep, fmt_int)
    call print_field('  env_log_step', cfg%env_log_step, fmt_int)
    call print_field('  i_ageair_reset_method', &
                     cfg%i_ageair_reset_method, fmt_int)
    call print_field('  i_error_method', cfg%i_error_method, fmt_int)
    call print_field('  i_ukca_chem', cfg%i_ukca_chem, fmt_int)
    call print_field('  i_ukca_chem_version', cfg%i_ukca_chem_version, fmt_int)
    call print_field('  max_ageair_reset_level', &
                     cfg%max_ageair_reset_level, fmt_int)
    call print_field('  model_duration (s)', cfg%model_duration, fmt_int)
    call print_field('  start_day', cfg%start_day, fmt_int)
    call print_field('  start_hour', cfg%start_hour, fmt_int)
    call print_field('  start_minute', cfg%start_minute, fmt_int)
    call print_field('  start_month', cfg%start_month, fmt_int)
    call print_field('  start_second', cfg%start_second, fmt_int)
    call print_field('  start_year', cfg%start_year, fmt_int)
    call print_field('  max_ageair_reset_height (m)', &
                     cfg%max_ageair_reset_height, fmt_real)
    call print_field('  max_z_for_offline_chem (m)', &
                     cfg%max_z_for_offline_chem, fmt_real)
    call print_field('  timestep (s)', cfg%timestep, fmt_real)
    call print_field('  delta_lambda (radians)', cfg%delta_lambda, fmt_real)
    call print_field('  delta_phi (radians)', cfg%delta_phi, fmt_real)
    call print_field('  l_blankout_invalid_diags', &
                     cfg%l_blankout_invalid_diags, fmt_log)
    call print_field('  l_cal360', cfg%l_cal360, fmt_log)
    call print_field('  l_chem_environ_co2_fld', &
                     cfg%l_chem_environ_co2_fld, fmt_log)
    call print_field('  l_chem_environ_gas_scalars', &
                     cfg%l_chem_environ_gas_scalars, fmt_log)
    call print_field('  l_ctile', cfg%l_ctile, fmt_log)
    call print_field('  l_environ_rel_humid', cfg%l_environ_rel_humid, fmt_log)
    call print_field('  l_fix_ukca_cloud_frac', &
                     cfg%l_fix_ukca_cloud_frac, fmt_log)
    call print_field('  l_param_conv', cfg%l_param_conv, fmt_log)
    call print_field('  l_timer', cfg%l_timer, fmt_log)
    call print_field('  l_tracer_lumping', cfg%l_tracer_lumping, fmt_log)
    call print_field('  l_ukca_ageair', cfg%l_ukca_ageair, fmt_log)
    call print_field('  l_ukca_debug_asad', cfg%l_ukca_debug_asad, fmt_log)
    call print_field('  l_ukca_scale_ppe', cfg%l_ukca_scale_ppe, fmt_log)
    call print_field('  l_use_gridbox_mass', cfg%l_use_gridbox_mass, fmt_log)
    call print_field('  l_use_gridbox_volume', &
                     cfg%l_use_gridbox_volume, fmt_log)
    call print_field('  l_zon_av_ozone', cfg%l_zon_av_ozone, fmt_log)
    call umPrint('', src=routine_name)

    ! Aerosol Configuration
    call umPrint('Aerosol Configuration:', src=routine_name)
    call print_field('  i_mode_bln_param_method', &
                     cfg%i_mode_bln_param_method, fmt_int)
    call print_field('  i_mode_nzts', cfg%i_mode_nzts, fmt_int)
    call print_field('  i_mode_setup', cfg%i_mode_setup, fmt_int)
    call print_field('  mode_activation_dryr', &
                     cfg%mode_activation_dryr, fmt_real)
    call print_field('  mode_incld_so2_rfrac', &
                     cfg%mode_incld_so2_rfrac, fmt_real)
    call print_field('  sigwmin', cfg%sigwmin, fmt_real)
    call print_field('  l_bug_repro_tke_index', &
                     cfg%l_bug_repro_tke_index, fmt_log)
    call print_field('  l_dust_mp_ageing', cfg%l_dust_mp_ageing, fmt_log)
    call print_field('  l_dust_mp_slinn_impc_scav', &
                     cfg%l_dust_mp_slinn_impc_scav, fmt_log)
    call print_field('  l_fix_nacl_density', cfg%l_fix_nacl_density, fmt_log)
    call print_field('  l_fix_neg_pvol_wat', cfg%l_fix_neg_pvol_wat, fmt_log)
    call print_field('  l_fix_ukca_activate_pdf', &
                     cfg%l_fix_ukca_activate_pdf, fmt_log)
    call print_field('  l_fix_ukca_activate_vert_rep', &
                     cfg%l_fix_ukca_activate_vert_rep, fmt_log)
    call print_field('  l_fix_ukca_hygroscopicities', &
                     cfg%l_fix_ukca_hygroscopicities, fmt_log)
    call print_field('  l_fix_ukca_impscav', cfg%l_fix_ukca_impscav, fmt_log)
    call print_field('  l_fix_ukca_water_content', &
                     cfg%l_fix_ukca_water_content, fmt_log)
    call print_field('  l_improve_aero_drydep', &
                     cfg%l_improve_aero_drydep, fmt_log)
    call print_field('  l_mode_bhn_on', cfg%l_mode_bhn_on, fmt_log)
    call print_field('  l_mode_bln_on', cfg%l_mode_bln_on, fmt_log)
    call print_field('  l_ntpreq_dryd_nuc_sol', &
                     cfg%l_ntpreq_dryd_nuc_sol, fmt_log)
    call print_field('  l_ntpreq_n_activ_sum', &
                     cfg%l_ntpreq_n_activ_sum, fmt_log)
    call print_field('  l_ukca_mode', cfg%l_ukca_mode, fmt_log)
    call print_field('  l_ukca_sfix', cfg%l_ukca_sfix, fmt_log)
    call umPrint('', src=routine_name)

    ! chemistry configuration
    call umPrint('Chemistry Configuration:', src=routine_name)
    call print_field('  dts0 (s)', cfg%dts0, fmt_int)
    call print_field('  i_ukca_hetconfig', cfg%i_ukca_hetconfig, fmt_int)
    call print_field('  i_ukca_quasinewton_end', &
                     cfg%i_ukca_quasinewton_end, fmt_int)
    call print_field('  i_ukca_quasinewton_start', &
                     cfg%i_ukca_quasinewton_start, fmt_int)
    call print_field('  i_ukca_topboundary', cfg%i_ukca_topboundary, fmt_int)
    call print_field('  nit', cfg%nit, fmt_int)
    call print_field('  nrsteps', cfg%nrsteps, fmt_int)
    call print_field('  ph_fit_coeff_a', cfg%ph_fit_coeff_a, fmt_real)
    call print_field('  ph_fit_coeff_b', cfg%ph_fit_coeff_b, fmt_real)
    call print_field('  ph_fit_intercept', cfg%ph_fit_intercept, fmt_real)
    call print_field('  l_fix_ukca_h2so4_ystore', &
                     cfg%l_fix_ukca_h2so4_ystore, fmt_log)
    call print_field('  l_fix_ukca_offox_h2o_fac', &
                     cfg%l_fix_ukca_offox_h2o_fac, fmt_log)
    call print_field('  l_ukca_chem_aero', cfg%l_ukca_chem_aero, fmt_log)
    call print_field('  l_ukca_classic_hetchem', &
                     cfg%l_ukca_classic_hetchem, fmt_log)
    call print_field('  l_ukca_het_psc', cfg%l_ukca_het_psc, fmt_log)
    call print_field('  l_ukca_intph', cfg%l_ukca_intph, fmt_log)
    call print_field('  l_ukca_limit_nat', cfg%l_ukca_limit_nat, fmt_log)
    call print_field('  l_ukca_prescribech4', cfg%l_ukca_prescribech4, fmt_log)
    call print_field('  l_ukca_quasinewton', cfg%l_ukca_quasinewton, fmt_log)
    call print_field('  l_ukca_ro2_ntp', cfg%l_ukca_ro2_ntp, fmt_log)
    call print_field('  l_ukca_ro2_perm', cfg%l_ukca_ro2_perm, fmt_log)
    call print_field('  l_ukca_sa_clim', cfg%l_ukca_sa_clim, fmt_log)
    call print_field('  l_ukca_trophet', cfg%l_ukca_trophet, fmt_log)
    call print_field('  l_use_classic_biogenic', &
                     cfg%l_use_classic_biogenic, fmt_log)
    call print_field('  l_use_classic_ocff', cfg%l_use_classic_ocff, fmt_log)
    call print_field('  l_use_classic_seasalt', &
                     cfg%l_use_classic_seasalt, fmt_log)
    call print_field('  l_use_classic_so4', cfg%l_use_classic_so4, fmt_log)
    call print_field('  l_use_classic_soot', cfg%l_use_classic_soot, fmt_log)
    call umPrint('', src=routine_name)

    ! Constants Configuration
    call umPrint('Constants Configuration:', src=routine_name)
    call print_field('  const_avogadro', cfg%const_avogadro, fmt_real)
    call print_field('  const_boltzmann', cfg%const_boltzmann, fmt_sci)
    call print_field('  const_lc', cfg%const_lc, fmt_sci)
    call print_field('  const_rho_so4', cfg%const_rho_so4, fmt_real)
    call print_field('  const_rho_water', cfg%const_rho_water, fmt_real)
    call print_field('  const_rhosea', cfg%const_rhosea, fmt_real)
    call print_field('  const_rmol', cfg%const_rmol, fmt_real)
    call print_field('  const_tfs', cfg%const_tfs, fmt_real)
    call print_field('  l_skip_const_setup', cfg%l_skip_const_setup, fmt_log)
    call umPrint('', src=routine_name)

    ! Deposition Configuration
    call umPrint('Deposition Configuration:', src=routine_name)
    call print_field('  i_mode_nucscav', cfg%i_mode_nucscav, fmt_int)
    call print_field('  acc_cor_scav_scaling', &
                     cfg%acc_cor_scav_scaling, fmt_real)
    call print_field('  dry_depvel_acc_scaling', &
                     cfg%dry_depvel_acc_scaling, fmt_real)
    call print_field('  dry_depvel_so2_scaling', &
                     cfg%dry_depvel_so2_scaling, fmt_real)
    call print_field('  l_aero_rainout', cfg%l_aero_rainout, fmt_log)
    call print_field('  l_cv_rainout', cfg%l_cv_rainout, fmt_log)
    call print_field('  l_ddepaer', cfg%l_ddepaer, fmt_log)
    call print_field('  l_deposition_jules', cfg%l_deposition_jules, fmt_log)
    call print_field('  l_fix_drydep_so2_water', &
                     cfg%l_fix_drydep_so2_water, fmt_log)
    call print_field('  l_fix_improve_drydep', &
                     cfg%l_fix_improve_drydep, fmt_log)
    call print_field('  l_fix_ukca_h2dd_x', cfg%l_fix_ukca_h2dd_x, fmt_log)
    call print_field('  l_impc_scav', cfg%l_impc_scav, fmt_log)
    call print_field('  l_ukca_ddep_lev1', cfg%l_ukca_ddep_lev1, fmt_log)
    call print_field('  l_ukca_ddepo3_ocean', cfg%l_ukca_ddepo3_ocean, fmt_log)
    call print_field('  l_ukca_dry_dep_so2wet', &
                     cfg%l_ukca_dry_dep_so2wet, fmt_log)
    call print_field('  l_ukca_drydep_off', cfg%l_ukca_drydep_off, fmt_log)
    call print_field('  l_ukca_intdd', cfg%l_ukca_intdd, fmt_log)
    call print_field('  l_ukca_wetdep_off', cfg%l_ukca_wetdep_off, fmt_log)
    call umPrint('', src=routine_name)

    ! Emissions Configuration
    call umPrint('Emissions Configuration:', src=routine_name)
    call print_field('  i_inferno_emi', cfg%i_inferno_emi, fmt_int)
    call print_field('  i_primss_method', cfg%i_primss_method, fmt_int)
    call print_field('  i_ukca_dms_flux', cfg%i_ukca_dms_flux, fmt_int)
    call print_field('  i_ukca_light_param', cfg%i_ukca_light_param, fmt_int)
    call print_field('  anth_so2_ems_scaling', &
                     cfg%anth_so2_ems_scaling, fmt_real)
    call print_field('  biom_aer_ems_scaling', &
                     cfg%biom_aer_ems_scaling, fmt_real)
    call print_field('  hno3_uptake_coeff', cfg%hno3_uptake_coeff, fmt_real)
    call print_field('  lightnox_scale_fac', cfg%lightnox_scale_fac, fmt_real)
    call print_field('  marine_pom_ems_scaling', &
                     cfg%marine_pom_ems_scaling, fmt_real)
    call print_field('  mode_parfrac', cfg%mode_parfrac, fmt_real)
    call print_field('  sea_salt_ems_scaling', &
                     cfg%sea_salt_ems_scaling, fmt_real)
    call print_field('  seadms_ems_scaling', cfg%seadms_ems_scaling, fmt_real)
    call print_field('  soa_yield_scaling_isop', &
                     cfg%soa_yield_scaling_isop, fmt_real)
    call print_field('  soa_yield_scaling_mt', &
                     cfg%soa_yield_scaling_mt, fmt_real)
    call print_field('  l_bcoc_bf', cfg%l_bcoc_bf, fmt_log)
    call print_field('  l_bcoc_bm', cfg%l_bcoc_bm, fmt_log)
    call print_field('  l_bcoc_ff', cfg%l_bcoc_ff, fmt_log)
    call print_field('  l_no3_prod_in_aero_step', &
                     cfg%l_no3_prod_in_aero_step, fmt_log)
    call print_field('  l_support_ems_gridbox_units', &
                     cfg%l_support_ems_gridbox_units, fmt_log)
    call print_field('  l_support_ems_vertprof', &
                     cfg%l_support_ems_vertprof, fmt_log)
    call print_field('  l_suppress_ems', cfg%l_suppress_ems, fmt_log)
    call print_field('  l_ukca_coarse_no3_prod', &
                     cfg%l_ukca_coarse_no3_prod, fmt_log)
    call print_field('  l_ukca_emsdrvn_ch4', cfg%l_ukca_emsdrvn_ch4, fmt_log)
    call print_field('  l_ukca_fine_no3_prod', &
                     cfg%l_ukca_fine_no3_prod, fmt_log)
    call print_field('  l_ukca_ibvoc', cfg%l_ukca_ibvoc, fmt_log)
    call print_field('  l_ukca_inferno', cfg%l_ukca_inferno, fmt_log)
    call print_field('  l_ukca_inferno_ch4', cfg%l_ukca_inferno_ch4, fmt_log)
    call print_field('  l_ukca_linox_scaling', &
                     cfg%l_ukca_linox_scaling, fmt_log)
    call print_field('  l_ukca_mp_fibre', cfg%l_ukca_mp_fibre, fmt_log)
    call print_field('  l_ukca_mp_fragment', cfg%l_ukca_mp_fragment, fmt_log)
    call print_field('  l_ukca_prim_moc', cfg%l_ukca_prim_moc, fmt_log)
    call print_field('  l_ukca_primbcoc', cfg%l_ukca_primbcoc, fmt_log)
    call print_field('  l_ukca_primdu', cfg%l_ukca_primdu, fmt_log)
    call print_field('  l_ukca_primss', cfg%l_ukca_primss, fmt_log)
    call print_field('  l_ukca_primsu', cfg%l_ukca_primsu, fmt_log)
    call print_field('  l_ukca_qch4inter', cfg%l_ukca_qch4inter, fmt_log)
    call print_field('  l_ukca_scale_biom_aer_ems', &
                     cfg%l_ukca_scale_biom_aer_ems, fmt_log)
    call print_field('  l_ukca_scale_marine_pom_ems', &
                     cfg%l_ukca_scale_marine_pom_ems, fmt_log)
    call print_field('  l_ukca_scale_sea_salt_ems', &
                     cfg%l_ukca_scale_sea_salt_ems, fmt_log)
    call print_field('  l_ukca_scale_seadms_ems', &
                     cfg%l_ukca_scale_seadms_ems, fmt_log)
    call print_field('  l_ukca_scale_soa_yield_isop', &
                     cfg%l_ukca_scale_soa_yield_isop, fmt_log)
    call print_field('  l_ukca_scale_soa_yield_mt', &
                     cfg%l_ukca_scale_soa_yield_mt, fmt_log)
    call print_field('  l_ukca_so2ems_expvolc', &
                     cfg%l_ukca_so2ems_expvolc, fmt_log)
    call print_field('  l_ukca_so2ems_plumeria', &
                     cfg%l_ukca_so2ems_plumeria, fmt_log)
    call umPrint('', src=routine_name)

    ! Feedbacks Configuration
    call umPrint('Feedbacks Configuration:', src=routine_name)
    call print_field('  i_ukca_activation_scheme', &
                     cfg%i_ukca_activation_scheme, fmt_int)
    call print_field('  i_ukca_nwbins', cfg%i_ukca_nwbins, fmt_int)
    call print_field('  i_ukca_tune_bc', cfg%i_ukca_tune_bc, fmt_int)
    call print_field('  sigma_updraught_scaling', &
                     cfg%sigma_updraught_scaling, fmt_real)
    call print_field('  l_ukca_conserve_h', cfg%l_ukca_conserve_h, fmt_log)
    call print_field('  l_ukca_h2o_feedback', cfg%l_ukca_h2o_feedback, fmt_log)
    call print_field('  l_ukca_radaer', cfg%l_ukca_radaer, fmt_log)
    call umPrint('', src=routine_name)

    ! IO Configuration
    call umPrint('IO Configuration:', src=routine_name)
    call print_field('  environment_data_file', &
                     cfg%environment_data_file, fmt_char)
    call print_field('  initial_tracer_file', &
                     cfg%initial_tracer_file, fmt_char)
    call print_field('  initial_ntp_file', cfg%initial_ntp_file, fmt_char)
    call print_field('  offline_photol_rates_file', &
                     cfg%offline_photol_rates_file, fmt_char)
    call print_field('  output_dir', cfg%output_dir, fmt_char)
    call umPrint('', src=routine_name)

    ! Landsurface Configuration
    call umPrint('Landsurface Configuration:', src=routine_name)
    call print_field('  ntype', cfg%ntype, fmt_int)
    call print_field('  dzsoil_layer1 (m)', cfg%dzsoil_layer1, fmt_real)
    call umPrint('', src=routine_name)

    ! Photolysis Configuration
    call umPrint('Photolysis Configuration:', src=routine_name)
    call print_field('  fastjx_mode', cfg%fastjx_mode, fmt_int)
    call print_field('  fastjx_numwl', cfg%fastjx_numwl, fmt_int)
    call print_field('  i_photol_scheme', cfg%i_photol_scheme, fmt_int)
    call print_field('  i_solcylc_type', cfg%i_solcylc_type, fmt_int)
    call print_field('  solcylc_start_year', cfg%solcylc_start_year, fmt_int)
    call print_field('  fastjx_prescutoff (hPa)', &
                     cfg%fastjx_prescutoff, fmt_real)
    call print_field('  l_cloud_pc2', cfg%l_cloud_pc2, fmt_log)
    call print_field('  l_strat_chem', cfg%l_strat_chem, fmt_log)
    call print_field('  l_use_photolysis', cfg%l_use_photolysis, fmt_log)
    call print_field('  l_offline_photol', cfg%l_offline_photol, fmt_log)
    call umPrint('', src=routine_name)

    call umPrint('='//repeat('=', 78)//'=', src=routine_name)
    call umPrint('', src=routine_name)

  endsubroutine print_box_config

  subroutine print_field_int(label, value, fmt)

    !! Print a labelled integer configuration option

    !> The label to print before the value
    character(len=*), intent(in) :: label
    !> The value to print
    integer, intent(in) :: value
    !> The format to print the label and value with
    character(len=*), intent(in) :: fmt

    write(umMessage, fmt) label, value
    call umPrint(umMessage, src=mod_name)

  endsubroutine print_field_int

  subroutine print_field_real(label, value, fmt)

    !! Print a labelled real configuration option

    !> The label to print before the value
    character(len=*), intent(in) :: label
    !> The value to print
    real, intent(in) :: value
    !> The format to print the label and value with
    character(len=*), intent(in) :: fmt

    write(umMessage, fmt) label, value
    call umPrint(umMessage, src=mod_name)

  endsubroutine print_field_real

  subroutine print_field_logical(label, value, fmt)

    !! Print a labelled logical configuration option

    !> The label to print before the value
    character(len=*), intent(in) :: label
    !> The value to print
    logical, intent(in) :: value
    !> The format to print the label and value with
    character(len=*), intent(in) :: fmt

    write(umMessage, fmt) label, value
    call umPrint(umMessage, src=mod_name)

  endsubroutine print_field_logical

  subroutine print_field_char(label, value, fmt)

    !! Print a labelled character configuration option

    !> The label to print before the value
    character(len=*), intent(in) :: label
    !> The value to print
    character(len=*), intent(in) :: value
    !> The format to print the label and value with
    character(len=*), intent(in) :: fmt

    write(umMessage, fmt) label, trim(value)
    call umPrint(umMessage, src=mod_name)

  endsubroutine print_field_char

endmodule box_config_mod
