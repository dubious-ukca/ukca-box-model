module box_environment_mod

  !! Module to handle the creation of the box model environment, stored in
  !! box_environment_type. This holds all environmental fields for a box model
  !! run. The API call ukca_set_environment is then used to pass this
  !! information from the box model into the main UKCA model.

  use umprintmgr, only: umMessage, umPrint
  use box_debug_mod, only: is_debug_level
  use box_const_mod, only: row_length, rows, model_levels, land_points, &
                           nlev_ent_tr_mix
  use box_jules_mod, only: npft, ntype
  use box_internal_ukca_config_mod, only: jppj
  use ukca_missing_data_mod, only: imdi, rmdi
  use, intrinsic :: ieee_arithmetic, only: ieee_value, ieee_quiet_nan
  use ereport_mod, only: ereport
  use ukca_api_mod, only: ukca_maxlen_procname, ukca_maxlen_message

  implicit none

  !> Module name for logging and error reporting
  character(len=*), parameter :: mod_name = "box_environment_mod"

  interface print_field
    procedure print_field_real
    procedure print_field_int
    procedure print_field_logical
  endinterface print_field

  private

  ! subroutine for creating a fresh box_environment_type
  public :: create_box_environment_type
  ! subroutine for reading environmental namelist and creating a
  ! box_environment_type from the parsed fields
  public :: read_box_environment_nml
  ! subroutine to print the environmental fields stored in the input
  ! box_environment_type
  public :: print_box_environment
  ! subroutine to set the ukca environment information from the input
  ! box_environment_type
  public :: set_box_environment
  ! subroutine to derive additional environment variables from the input
  ! box_environment_type and set these in the ukca environment
  public :: derive_env_variables
  ! subroutine to print internal ukca environment variables
  public :: print_ukca_environment
  ! subroutine to update a box environment entry with values from the tracer
  ! array
  public :: update_env_from_tracers
  ! subroutine to update a tracer with values from a box environment entry
  public :: update_tracer_from_env

  !> derived type for storing all ukca environmental fields
  type, public :: box_environment_type

    ! real scalar fields
    !> height of model top (m)
    real :: z_top_of_model = rmdi
    !> sin of solar declination
    real :: sin_declination = rmdi
    !> equation of time, specified as an hour angle (radians)
    real :: equation_of_time = rmdi
    !> prescribed mass fraction of methane in air
    real :: atmospheric_ch4 = rmdi
    !> prescribed mass fraction of carbon dioxide in air
    real :: atmospheric_co2 = rmdi
    !> prescribed mass fraction of molecular hydrogen in air
    real :: atmospheric_h2 = rmdi
    !> prescribed mass fraction of molecular nitrogen in air
    real :: atmospheric_n2 = rmdi
    !> prescribed mass fraction of molecular oxygen in air
    real :: atmospheric_o2 = rmdi
    !> prescribed mass fraction of nitrous oxide in air
    real :: atmospheric_n2o = rmdi
    !> prescribed mass fraction of cfc11 in air
    real :: atmospheric_cfc11 = rmdi
    !> prescribed mass fraction of cfc12 in air
    real :: atmospheric_cfc12 = rmdi
    !> prescribed mass fraction of cfc113 in air
    real :: atmospheric_cfc113 = rmdi
    !> prescribed mass fraction of hcfc22 in air
    real :: atmospheric_hcfc22 = rmdi
    !> prescribed mass fraction of hfc125 in air
    real :: atmospheric_hfc125 = rmdi
    !> prescribed mass fraction of hfc134a in air
    real :: atmospheric_hfc134a = rmdi
    !> prescribed mass fraction of methyl bromide in air
    real :: atmospheric_mebr = rmdi
    !> prescribed mass fraction of methyl chloride in air
    real :: atmospheric_mecl = rmdi
    !> prescribed mass fraction of dibromomethane in air
    real :: atmospheric_ch2br2 = rmdi
    !> prescribed mass fraction of tribromomethane in air
    real :: atmospheric_chbr3 = rmdi
    !> prescribed mass fraction of cfc114 in air
    real :: atmospheric_cfc114 = rmdi
    !> prescribed mass fraction of cfc115 in air
    real :: atmospheric_cfc115 = rmdi
    !> prescribed mass fraction of carbon tetrachloride in air
    real :: atmospheric_ccl4 = rmdi
    !> prescribed mass fraction of methyl chloroform in air
    real :: atmospheric_meccl3 = rmdi
    !> prescribed mass fraction of hcfc141b in air
    real :: atmospheric_hcfc141b = rmdi
    !> prescribed mass fraction of hcfc142b in air
    real :: atmospheric_hcfc142b = rmdi
    !> prescribed mass fraction of h1211 in air
    real :: atmospheric_h1211 = rmdi
    !> prescribed mass fraction of h1202 in air
    real :: atmospheric_h1202 = rmdi
    !> prescribed mass fraction of h1301 in air
    real :: atmospheric_h1301 = rmdi
    !> prescribed mass fraction of h2402 in air
    real :: atmospheric_h2402 = rmdi
    !> prescribed mass fraction of carbonyl sulfide in air
    real :: atmospheric_cos = rmdi

    ! real 1D fields
    !> moisture_content_of_soil_layer at surface (kg/m^2) {UM:00009}
    real, dimension(:), allocatable :: soil_moisture_layer1
    !> land_area_fraction {UM:00505}
    real, dimension(:), allocatable :: fland
    !> Gridbox mean isoprene emission flux (kgC/m2/s)
    real, dimension(:), allocatable :: ibvoc_isoprene
    !> Gridbox mean (mono-)terpene emission flux (kgC/m2/s)
    real, dimension(:), allocatable :: ibvoc_terpene
    !> Gridbox mean methanol emission flux (kgC/m2/s)
    real, dimension(:), allocatable :: ibvoc_methanol
    !> Gridbox mean acetone emission flux (kgC/m2/s)
    real, dimension(:), allocatable :: ibvoc_acetone
    !> Gridbox mean Black Carbon emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_bc
    !> Gridbox mean Methane emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_ch4
    !> Gridbox mean Carbon monoxide emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_co
    !> Gridbox mean Nitric oxide emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_nox
    !> Gridbox mean Organic Carbon emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_oc
    !> Gridbox mean Sulphur dioxide emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_so2
    !> Gridbox mean ethene emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_c2h4
    !> Gridbox mean ethane emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_c2h6
    !> Gridbox mean propane emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_c3h8
    !> Gridbox mean formaldehyde emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_hcho
    !> Gridbox mean acetaldehyde emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_mecho
    !> Gridbox mean ammonia emissions from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_nh3
    !> Gridbox mean dimethyl sulfide from fires (kg/m2/s)
    real, dimension(:), allocatable :: inferno_dms
    !> eta of each theta level (dimensionless, 0 at surface, 1 at model top)
    real, dimension(:), allocatable :: eta_theta_levels

    ! real 2D fields
    !> latitude (degrees north)
    real, dimension(:, :), allocatable :: latitude
    !> true latitude (radians north)
    real, dimension(:, :), allocatable :: true_latitude
    !> longitude (degrees east, >=0, <360)
    real, dimension(:, :), allocatable :: longitude
    !> true longitude (radians east)
    real, dimension(:, :), allocatable :: true_longitude
    !> SIN(latitude)
    real, dimension(:, :), allocatable :: sin_latitude
    !> COS(latitude)
    real, dimension(:, :), allocatable :: cos_latitude
    !> TAN(latitude)
    real, dimension(:, :), allocatable :: tan_latitude
    !> convective cloud liquid water path (kg/m^2) {UM:00016}
    real, dimension(:, :), allocatable :: conv_cloud_lwp
    !> surface_temperature [CF] (K) {UM:00024}
    real, dimension(:, :), allocatable :: tstar
    !> atmosphere_boundary_layer_thickness [CF] (m) {UM:00025}
    real, dimension(:, :), allocatable :: zbl
    !> surface_roughness_length [CF] (m)
    real, dimension(:, :), allocatable :: rough_length
    !> sea_ice_area_fraction [CF] with respect to sea area {UM:00031}
    real, dimension(:, :), allocatable :: seaice_frac
    !> fraction of surface type with respect to land area {UM:00216}
    real, dimension(:, :), allocatable :: frac_types
    !> leaf_area_index [CF] of plant functional type {UM:00217}
    real, dimension(:, :), allocatable :: laift_lp
    !> canopy_height [CF] of plant functional type (m) {UM:00218}
    real, dimension(:, :), allocatable :: canhtft_lp
    !> surface_temperature [CF] on tiles (K) {UM:00233}
    real, dimension(:, :), allocatable :: tstar_tile
    !> surface_roughness_length [CF] on tiles (m) {UM:00234}
    real, dimension(:, :), allocatable :: z0tile_lp
    !> surface_air_pressure [CF] (Pa) {UM:00409}
    real, dimension(:, :), allocatable :: pstar
    !> surface_albedo [CF]
    real, dimension(:, :), allocatable :: surf_albedo
    !> height of top of decoupled stratocumulus layer, for bl_tracer_mix (L
    !> units) {UM:03073}
    real, dimension(:, :), allocatable :: zhsc
    !> wind_speed [CF] at 10 m (m/s) {UM:03230}
    real, dimension(:, :), allocatable :: u_scalar_10m
    !> surface_upward_sensible_heat_flux [CF] (W/m^2) {UM:03217}
    real, dimension(:, :), allocatable :: surf_hf
    !> explicit friction velocity (m/s) {UM:03465}
    real, dimension(:, :), allocatable :: u_s
    !> CH4 wetland flux (ugC/m2/s) {UM:08242}
    real, dimension(:, :), allocatable :: ch4_wetl_emiss
    !> mole_concentration_of_dimethyl_sulphide_in_sea_water [CF] (nmol/l)
    !> {UM:00132}
    real, dimension(:, :), allocatable :: dms_sea_conc
    !> ocean near-surface chlorophyll (kg/m^3) {UM:00096}
    real, dimension(:, :), allocatable :: chloro_sea
    !> dust emissions in CLASSIC size bin 1 (kg/m^2/s) {UM:03401}
    real, dimension(:, :), allocatable :: dust_flux_div1
    !> dust emissions in CLASSIC size bin 2 (kg/m^2/s) {UM:03402}
    real, dimension(:, :), allocatable :: dust_flux_div2
    !> dust emissions in CLASSIC size bin 3 (kg/m^2/s) {UM:03403}
    real, dimension(:, :), allocatable :: dust_flux_div3
    !> dust emissions in CLASSIC size bin 4 (kg/m^2/s) {UM:03404}
    real, dimension(:, :), allocatable :: dust_flux_div4
    !> dust emissions in CLASSIC size bin 5 (kg/m^2/s) {UM:03405}
    real, dimension(:, :), allocatable :: dust_flux_div5
    !> dust emissions in CLASSIC size bin 6 (kg/m^2/s) {UM:03406}
    real, dimension(:, :), allocatable :: dust_flux_div6
    !> surface wetness {UM:00634}
    real, dimension(:, :), allocatable :: surf_wetness
    !> Gridbox surface area (m^2)
    real, dimension(:, :), allocatable :: grid_surf_area
    !> External cloud-to-ground flash rate [s-1]
    real, dimension(:, :), allocatable :: ext_cg_flash
    !> External intracloud flash rate [s-1]
    real, dimension(:, :), allocatable :: ext_ic_flash

    ! integer 2D fields
    !> grid level of surface mixed layer inversion, for bl_tracer_mix
    !> {UM:03065}
    integer, dimension(:, :), allocatable :: kent
    !> grid level of decoupled stratocumulus inversion, for bl_tracer_mix
    !> {UM:03069}
    integer, dimension(:, :), allocatable :: kent_dsc
    !> lowest convective cloud base level no. {UM:05218}
    integer, dimension(:, :), allocatable :: conv_cloud_base
    !> lowest convective cloud top level no. {UM:05219}
    integer, dimension(:, :), allocatable :: conv_cloud_top
    !> surface type for gridbox as required by Zhang et al (Aero drydep) scheme
    integer, dimension(:, :), allocatable :: lscat_zhang

    ! logical 2D fields
    !> land_binary_mask [CF] (land = .true.) {UM:00030}
    logical, dimension(:, :), allocatable :: land_sea_mask
    !> active tile indicator (.true. if tile is in use)
    logical, dimension(:, :), allocatable :: l_tile_active

    ! real 3D fields
    !> `uwind_rho_levels` (m/s) {UM:00002}
    real, dimension(:, :, :), allocatable :: u_rho_levels
    !> `vwind_rho_levels` (m/s) {UM:00003}
    real, dimension(:, :, :), allocatable :: v_rho_levels
    !> geopotential_height_theta_levels (m) {UM:16201}
    real, dimension(:, :, :), allocatable :: geopH_on_theta_mlevs
    !> air_potential_temperature [CF] (K) {UM:00004}
    real, dimension(:, :, :), allocatable :: theta
    !> specific_humidity [CF] {UM:00010}
    real, dimension(:, :, :), allocatable :: q
    !> mass_fraction_of_cloud_ice_in_air [CF] {UM:00012}
    real, dimension(:, :, :), allocatable :: qcf
    !> fractional convective cloud amount with anvil {UM:00211}
    real, dimension(:, :, :), allocatable :: conv_cloud_amount
    !> density*radius*radius (kg/m) {UM:00253}
    real, dimension(:, :, :), allocatable :: rho_r2
    !> mass_fraction_of_cloud_liquid_water_in_air [CF] {UM:00254}
    real, dimension(:, :, :), allocatable :: qcl
    !> dimensionless_exner_function [CF] at rho levels {UM:00255}
    real, dimension(:, :, :), allocatable :: exner_rho_levels
    !> cloud_area_fraction_in_atmosphere_layer [CF] {UM:00265}
    real, dimension(:, :, :), allocatable :: area_cloud_fraction
    !> bulk cloud fraction {UM:00266}
    real, dimension(:, :, :), allocatable :: cloud_frac
    !> liquid cloud fraction {UM:00267}
    real, dimension(:, :, :), allocatable :: cloud_liq_frac
    !> dimensionless_exner_function [CF] at theta levels {UM:00406}
    real, dimension(:, :, :), allocatable :: exner_theta_levels
    !> air_pressure [CF] at layer boundaries (Pa), for photolysis
    real, dimension(:, :, :), allocatable :: p_layer_boundaries
    !> air_pressure [CF] at theta levels (Pa) {UM:00408}
    real, dimension(:, :, :), allocatable :: p_theta_levels
    !> air_temperature [CF] at theta levels (K), for photolysis
    real, dimension(:, :, :), allocatable :: t_theta_levels
    !> mixing coefficient above surface: (scalar eddy diffusivity * density)
    !> / dz, for bl_tracer_mix (M/(L^2*T) units) {UM:03060}
    real, dimension(:, :, :), allocatable :: rhokh_rdz
    !> dt/(density*radius*radius*dz) for scalar flux divergence, for
    !> bl_tracer_mix (T/M units) {UM:03064}
    real, dimension(:, :, :), allocatable :: dtrdz
    !> density * entrainment rate implied by placing of subsidence at surface
    !> mixed layer inversion, for bl_tracer_mix (M/L^2/T units) {UM:03066}
    real, dimension(:, :, :), allocatable :: we_lim
    !> fraction of timestep surface mixed layer inversion is above level, for
    !> bl_tracer_mix {UM:03067}
    real, dimension(:, :, :), allocatable :: t_frac
    !> level height as fraction of surface mixed layer inversion height above
    !> ML base, for bl_tracer_mix {UM:03068}
    real, dimension(:, :, :), allocatable :: zrzi
    !> density * entrainment rate implied by placing of subsidence at
    !> decoupled stratocumulus inversion, for bl_tracer_mix (M/L^2/T units)
    !> {UM:03070}
    real, dimension(:, :, :), allocatable :: we_lim_dsc
    !> fraction of timestep decoupled stratocumulus inversion is above level,
    !> for bl_tracer_mix {UM:03071}
    real, dimension(:, :, :), allocatable :: t_frac_dsc
    !> level height as fraction of decoupled stratocumulus inversion height
    !> above DSC ML base, for bl_tracer_mix {UM:03072}
    real, dimension(:, :, :), allocatable :: zrzi_dsc
    !> stomatal conductance on plant functional type (m/s) {UM:03462}
    real, dimension(:, :, :), allocatable :: stcon
    !> large_scale_rainfall_flux [CF] out of model levels (kg/m^2/s)
    !> {UM:04222}
    real, dimension(:, :, :), allocatable :: ls_rain3d
    !> large_scale_snowfall_flux [CF] out of model levels (kg/m^2/s)
    !> {UM:04223}
    real, dimension(:, :, :), allocatable :: ls_snow3d
    !> rain autoconversion rate, mass fraction (/s) {UM:04257}
    real, dimension(:, :, :), allocatable :: autoconv
    !> rain accretion rate, mass fraction (/s) {UM:04258}
    real, dimension(:, :, :), allocatable :: accretion
    !> ertel_potential_vorticity [CF] on theta levels (K m^2/(kg s))
    !> {UM:15218}
    real, dimension(:, :, :), allocatable :: pv_on_theta_mlevs
    !> convective_rainfall_flux [CF] (kg/m^2/s) {UM:05227}
    real, dimension(:, :, :), allocatable :: conv_rain3d
    !> convective_snowfall_flux [CF] (kg/m^2/s) {UM:05228}
    real, dimension(:, :, :), allocatable :: conv_snow3d
    !> sulphate aerosol surface area density (cm^2/cm^3)
    real, dimension(:, :, :), allocatable :: so4_sa_clim
    !> mass fraction of aitken mode sulfate dry aerosol expressed as sulfur in
    !> air {UM:00103}
    real, dimension(:, :, :), allocatable :: so4_aitken
    !> mass fraction of accumulation mode sulfate dry aerosol expressed as
    !> sulfur in air {UM:00104}
    real, dimension(:, :, :), allocatable :: so4_accum
    !> mass fraction of fresh black carbon dry aerosol in air {UM:00108}
    real, dimension(:, :, :), allocatable :: soot_fresh
    !> mass fraction of aged black carbon dry aerosol in air {UM:00109}
    real, dimension(:, :, :), allocatable :: soot_aged
    !> mass fraction of fresh organic carbon from fossil fuel dry aerosol in
    !> air {UM:00114}
    real, dimension(:, :, :), allocatable :: ocff_fresh
    !> mass fraction of aged organic carbon from fossil fuel dry aerosol in
    !> air (kg/kg) {UM:00115}
    real, dimension(:, :, :), allocatable :: ocff_aged
    !> mass fraction of biogenic secondary organic dry aerosol in air
    !> {UM:00351}
    real, dimension(:, :, :), allocatable :: biogenic
    !> mass fraction of dust division 1 dry aerosol in air {UM:00431}
    real, dimension(:, :, :), allocatable :: dust_div1
    !> mass fraction of dust division 2 dry aerosol in air {UM:00432}
    real, dimension(:, :, :), allocatable :: dust_div2
    !> mass fraction of dust division 3 dry aerosol in air {UM:00433}
    real, dimension(:, :, :), allocatable :: dust_div3
    !> mass fraction of dust division 4 dry aerosol in air {UM:00434}
    real, dimension(:, :, :), allocatable :: dust_div4
    !> mass fraction of dust division 5 dry aerosol in air {UM:00435}
    real, dimension(:, :, :), allocatable :: dust_div5
    !> mass fraction of dust division 6 dry aerosol in air {UM:00436}
    real, dimension(:, :, :), allocatable :: dust_div6
    !> atmosphere number concentration of film mode sea salt particles (/m^3)
    !> {UM:01247}
    real, dimension(:, :, :), allocatable :: sea_salt_film
    !> atmosphere number concentration of jet mode sea salt particles (/m^3)
    !> {UM:01248}
    real, dimension(:, :, :), allocatable :: sea_salt_jet
    !> mass_fraction_of_carbon_dioxide_in_air [CF] {UM:00252}
    real, dimension(:, :, :), allocatable :: co2_interactive
    !> riming rate for ice crystals from cloud liquid, mass fraction (/s)
    !> {UM:04247}
    real, dimension(:, :, :), allocatable :: rim_cry
    !> riming rate for ice aggregates, mass fraction (/s) {UM:04248}
    real, dimension(:, :, :), allocatable :: rim_agg
    !> upward_air_velocity [CF] (m/s) {UM:00150}
    real, dimension(:, :, :), allocatable :: vertvel
    !> turbulent kinetic energy (m^2/s^2) {UM:03473}
    real, dimension(:, :, :), allocatable :: bl_tke
    !> altitude of grid-cell interfaces (m)
    real, dimension(:, :, :), allocatable :: interf_z
    !> grid cell area (m^2), all levels
    real, dimension(:, :, :), allocatable :: grid_area_fullht
    !> grid cell volume (m^3), theta levels
    real, dimension(:, :, :), allocatable :: grid_volume
    !> grid cell air mass (kg), theta levels
    real, dimension(:, :, :), allocatable :: grid_airmass
    !> relative_humidity [CF]
    real, dimension(:, :, :), allocatable :: rel_humid_frac
    !> clear-sky relative humidity
    real, dimension(:, :, :), allocatable :: rel_humid_frac_clr
    !> saturation vapour pressure of water (Pa)
    real, dimension(:, :, :), allocatable :: qsvp
    !> hydrogen peroxide as offline oxidant (kg/kg-air)
    real, dimension(:, :, :), allocatable :: h2o2_offline
    !> hydroperoxyl radical as offline oxidant (kg/kg-air)
    real, dimension(:, :, :), allocatable :: ho2_offline
    !> nitrate radical as offline oxidant (kg/kg-air)
    real, dimension(:, :, :), allocatable :: no3_offline
    !> mass_fraction_of_ozone_in_air [CF] {UM:00060}
    real, dimension(:, :, :), allocatable :: o3_offline
    !> hydroxyl radical as offline oxidant (kg/kg-air)
    real, dimension(:, :, :), allocatable :: oh_offline
    !> distance from the centre of the Earth to theta levels (m)
    real, dimension(:, :, :), allocatable :: r_theta_levels
    !> distance from the centre of the Earth to rho levels (m)
    real, dimension(:, :, :), allocatable :: r_rho_levels
    !> air_pressure [CF] at rho levels (Pa) {UM:00407}
    real, dimension(:, :, :), allocatable :: p_rho_levels
    !> aerosol optical depth of accumulation mode sulphate, for photolysis
    real, dimension(:, :, :), allocatable :: aod_sulph_accum
    !> aerosol optical depth of Aitken mode sulphate, for photolysis
    real, dimension(:, :, :), allocatable :: aod_sulph_aitk

    ! real 4D fields
    !> photolysis rates (row_length, rows, model_levels, jppj)
    real, dimension(:, :, :, :), allocatable :: photol_rates

  endtype box_environment_type

contains

  subroutine create_box_environment_type(env)

    !! Allocate the arrays in a box environment and set every field to its
    !! missing data value. The environment is passed in so that its
    !! deferred-shape arrays can be allocated.

    !> The box environment to allocate and initialise
    type(box_environment_type), intent(out) :: env

    ! real 1D fields
    allocate(env%soil_moisture_layer1(land_points))
    allocate(env%fland(land_points))
    allocate(env%ibvoc_isoprene(land_points))
    allocate(env%ibvoc_terpene(land_points))
    allocate(env%ibvoc_methanol(land_points))
    allocate(env%ibvoc_acetone(land_points))
    allocate(env%inferno_bc(land_points))
    allocate(env%inferno_ch4(land_points))
    allocate(env%inferno_co(land_points))
    allocate(env%inferno_nox(land_points))
    allocate(env%inferno_oc(land_points))
    allocate(env%inferno_so2(land_points))
    allocate(env%inferno_c2h4(land_points))
    allocate(env%inferno_c2h6(land_points))
    allocate(env%inferno_c3h8(land_points))
    allocate(env%inferno_hcho(land_points))
    allocate(env%inferno_mecho(land_points))
    allocate(env%inferno_nh3(land_points))
    allocate(env%inferno_dms(land_points))
    allocate(env%eta_theta_levels(0:model_levels))

    ! real 2D fields
    allocate(env%latitude(row_length, rows))
    allocate(env%true_latitude(row_length, rows))
    allocate(env%longitude(row_length, rows))
    allocate(env%true_longitude(row_length, rows))
    allocate(env%sin_latitude(row_length, rows))
    allocate(env%cos_latitude(row_length, rows))
    allocate(env%tan_latitude(row_length, rows))
    allocate(env%conv_cloud_lwp(row_length, rows))
    allocate(env%tstar(row_length, rows))
    allocate(env%zbl(row_length, rows))
    allocate(env%rough_length(row_length, rows))
    allocate(env%seaice_frac(row_length, rows))
    allocate(env%frac_types(land_points, ntype))
    allocate(env%laift_lp(land_points, npft))
    allocate(env%canhtft_lp(land_points, npft))
    allocate(env%tstar_tile(land_points, ntype))
    allocate(env%z0tile_lp(land_points, ntype))
    allocate(env%pstar(row_length, rows))
    allocate(env%surf_albedo(row_length, rows))
    allocate(env%zhsc(row_length, rows))
    allocate(env%u_scalar_10m(row_length, rows))
    allocate(env%surf_hf(row_length, rows))
    allocate(env%u_s(row_length, rows))
    allocate(env%ch4_wetl_emiss(row_length, rows))
    allocate(env%dms_sea_conc(row_length, rows))
    allocate(env%chloro_sea(row_length, rows))
    allocate(env%dust_flux_div1(row_length, rows))
    allocate(env%dust_flux_div2(row_length, rows))
    allocate(env%dust_flux_div3(row_length, rows))
    allocate(env%dust_flux_div4(row_length, rows))
    allocate(env%dust_flux_div5(row_length, rows))
    allocate(env%dust_flux_div6(row_length, rows))
    allocate(env%surf_wetness(row_length, rows))
    allocate(env%grid_surf_area(row_length, rows))
    allocate(env%ext_cg_flash(row_length, rows))
    allocate(env%ext_ic_flash(row_length, rows))

    ! integer 2D fields
    allocate(env%kent(row_length, rows))
    allocate(env%kent_dsc(row_length, rows))
    allocate(env%conv_cloud_base(row_length, rows))
    allocate(env%conv_cloud_top(row_length, rows))
    allocate(env%lscat_zhang(row_length, rows))

    ! logical 2D fields
    allocate(env%land_sea_mask(row_length, rows))
    allocate(env%l_tile_active(land_points, ntype))

    ! real 3D fields
    allocate(env%u_rho_levels(row_length, rows, model_levels))
    allocate(env%v_rho_levels(row_length, rows, model_levels))
    allocate(env%geopH_on_theta_mlevs(row_length, rows, model_levels))
    allocate(env%theta(row_length, rows, model_levels))
    allocate(env%q(row_length, rows, model_levels))
    allocate(env%qcf(row_length, rows, model_levels))
    allocate(env%conv_cloud_amount(row_length, rows, model_levels))
    allocate(env%rho_r2(row_length, rows, model_levels + 1))
    allocate(env%qcl(row_length, rows, model_levels))
    allocate(env%exner_rho_levels(row_length, rows, model_levels + 1))
    allocate(env%area_cloud_fraction(row_length, rows, model_levels))
    allocate(env%cloud_frac(row_length, rows, model_levels))
    allocate(env%cloud_liq_frac(row_length, rows, model_levels))
    allocate(env%exner_theta_levels(row_length, rows, model_levels))
    allocate(env%p_layer_boundaries(row_length, rows, model_levels))
    allocate(env%p_theta_levels(row_length, rows, model_levels))
    allocate(env%t_theta_levels(row_length, rows, model_levels))
    allocate(env%rhokh_rdz(row_length, rows, model_levels))
    allocate(env%dtrdz(row_length, rows, model_levels))
    allocate(env%we_lim(row_length, rows, nlev_ent_tr_mix))
    allocate(env%t_frac(row_length, rows, nlev_ent_tr_mix))
    allocate(env%zrzi(row_length, rows, nlev_ent_tr_mix))
    allocate(env%we_lim_dsc(row_length, rows, nlev_ent_tr_mix))
    allocate(env%t_frac_dsc(row_length, rows, nlev_ent_tr_mix))
    allocate(env%zrzi_dsc(row_length, rows, nlev_ent_tr_mix))
    allocate(env%stcon(row_length, rows, ntype))
    allocate(env%ls_rain3d(row_length, rows, model_levels))
    allocate(env%ls_snow3d(row_length, rows, model_levels))
    allocate(env%autoconv(row_length, rows, model_levels))
    allocate(env%accretion(row_length, rows, model_levels))
    allocate(env%pv_on_theta_mlevs(row_length, rows, model_levels))
    allocate(env%conv_rain3d(row_length, rows, model_levels))
    allocate(env%conv_snow3d(row_length, rows, model_levels))
    allocate(env%so4_sa_clim(row_length, rows, model_levels))
    allocate(env%so4_aitken(row_length, rows, model_levels))
    allocate(env%so4_accum(row_length, rows, model_levels))
    allocate(env%soot_fresh(row_length, rows, model_levels))
    allocate(env%soot_aged(row_length, rows, model_levels))
    allocate(env%ocff_fresh(row_length, rows, model_levels))
    allocate(env%ocff_aged(row_length, rows, model_levels))
    allocate(env%biogenic(row_length, rows, model_levels))
    allocate(env%dust_div1(row_length, rows, model_levels))
    allocate(env%dust_div2(row_length, rows, model_levels))
    allocate(env%dust_div3(row_length, rows, model_levels))
    allocate(env%dust_div4(row_length, rows, model_levels))
    allocate(env%dust_div5(row_length, rows, model_levels))
    allocate(env%dust_div6(row_length, rows, model_levels))
    allocate(env%sea_salt_film(row_length, rows, model_levels))
    allocate(env%sea_salt_jet(row_length, rows, model_levels))
    allocate(env%co2_interactive(row_length, rows, model_levels))
    allocate(env%rim_cry(row_length, rows, model_levels))
    allocate(env%rim_agg(row_length, rows, model_levels))
    allocate(env%vertvel(row_length, rows, model_levels))
    allocate(env%bl_tke(row_length, rows, model_levels))
    allocate(env%interf_z(row_length, rows, model_levels))
    allocate(env%grid_area_fullht(row_length, rows, model_levels))
    allocate(env%grid_volume(row_length, rows, model_levels))
    allocate(env%grid_airmass(row_length, rows, model_levels))
    allocate(env%rel_humid_frac(row_length, rows, model_levels))
    allocate(env%rel_humid_frac_clr(row_length, rows, model_levels))
    allocate(env%qsvp(row_length, rows, model_levels))
    allocate(env%h2o2_offline(row_length, rows, model_levels))
    allocate(env%ho2_offline(row_length, rows, model_levels))
    allocate(env%no3_offline(row_length, rows, model_levels))
    allocate(env%o3_offline(row_length, rows, model_levels))
    allocate(env%oh_offline(row_length, rows, model_levels))
    allocate(env%r_theta_levels(row_length, rows, 0:model_levels))
    allocate(env%r_rho_levels(row_length, rows, model_levels))
    allocate(env%p_rho_levels(row_length, rows, model_levels))
    allocate(env%aod_sulph_accum(row_length, rows, model_levels))
    allocate(env%aod_sulph_aitk(row_length, rows, model_levels))

    ! real 4D fields
    allocate(env%photol_rates(row_length, rows, model_levels, jppj))

    ! real 1D defaults
    env%soil_moisture_layer1 = rmdi
    env%fland = rmdi
    env%ibvoc_isoprene = rmdi
    env%ibvoc_terpene = rmdi
    env%ibvoc_methanol = rmdi
    env%ibvoc_acetone = rmdi
    env%inferno_bc = rmdi
    env%inferno_ch4 = rmdi
    env%inferno_co = rmdi
    env%inferno_nox = rmdi
    env%inferno_oc = rmdi
    env%inferno_so2 = rmdi
    env%inferno_c2h4 = rmdi
    env%inferno_c2h6 = rmdi
    env%inferno_c3h8 = rmdi
    env%inferno_hcho = rmdi
    env%inferno_mecho = rmdi
    env%inferno_nh3 = rmdi
    env%inferno_dms = rmdi
    env%eta_theta_levels = rmdi

    ! real 2D defaults
    env%latitude = rmdi
    env%true_latitude = rmdi
    env%longitude = rmdi
    env%true_longitude = rmdi
    env%sin_latitude = rmdi
    env%cos_latitude = rmdi
    env%tan_latitude = rmdi
    env%conv_cloud_lwp = rmdi
    env%tstar = rmdi
    env%zbl = rmdi
    env%rough_length = rmdi
    env%seaice_frac = rmdi
    env%frac_types = rmdi
    env%laift_lp = rmdi
    env%canhtft_lp = rmdi
    env%tstar_tile = rmdi
    env%z0tile_lp = rmdi
    env%pstar = rmdi
    env%surf_albedo = rmdi
    env%zhsc = rmdi
    env%u_scalar_10m = rmdi
    env%surf_hf = rmdi
    env%u_s = rmdi
    env%ch4_wetl_emiss = rmdi
    env%dms_sea_conc = rmdi
    env%chloro_sea = rmdi
    env%dust_flux_div1 = rmdi
    env%dust_flux_div2 = rmdi
    env%dust_flux_div3 = rmdi
    env%dust_flux_div4 = rmdi
    env%dust_flux_div5 = rmdi
    env%dust_flux_div6 = rmdi
    env%surf_wetness = rmdi
    env%grid_surf_area = rmdi
    env%ext_cg_flash = rmdi
    env%ext_ic_flash = rmdi

    ! integer 2D defaults
    env%kent = imdi
    env%kent_dsc = imdi
    env%conv_cloud_base = imdi
    env%conv_cloud_top = imdi
    env%lscat_zhang = imdi

    ! logical 2D defaults
    env%land_sea_mask = .false.
    env%l_tile_active = .false.

    ! real 3D defaults
    env%u_rho_levels = rmdi
    env%v_rho_levels = rmdi
    env%geopH_on_theta_mlevs = rmdi
    env%theta = rmdi
    env%q = rmdi
    env%qcf = rmdi
    env%conv_cloud_amount = rmdi
    env%rho_r2 = rmdi
    env%qcl = rmdi
    env%exner_rho_levels = rmdi
    env%area_cloud_fraction = rmdi
    env%cloud_frac = rmdi
    env%cloud_liq_frac = rmdi
    env%exner_theta_levels = rmdi
    env%p_layer_boundaries = rmdi
    env%p_theta_levels = rmdi
    env%t_theta_levels = rmdi
    env%rhokh_rdz = rmdi
    env%dtrdz = rmdi
    env%we_lim = rmdi
    env%t_frac = rmdi
    env%zrzi = rmdi
    env%we_lim_dsc = rmdi
    env%t_frac_dsc = rmdi
    env%zrzi_dsc = rmdi
    env%stcon = rmdi
    env%ls_rain3d = rmdi
    env%ls_snow3d = rmdi
    env%autoconv = rmdi
    env%accretion = rmdi
    env%pv_on_theta_mlevs = rmdi
    env%conv_rain3d = rmdi
    env%conv_snow3d = rmdi
    env%so4_sa_clim = rmdi
    env%so4_aitken = rmdi
    env%so4_accum = rmdi
    env%soot_fresh = rmdi
    env%soot_aged = rmdi
    env%ocff_fresh = rmdi
    env%ocff_aged = rmdi
    env%biogenic = rmdi
    env%dust_div1 = rmdi
    env%dust_div2 = rmdi
    env%dust_div3 = rmdi
    env%dust_div4 = rmdi
    env%dust_div5 = rmdi
    env%dust_div6 = rmdi
    env%sea_salt_film = rmdi
    env%sea_salt_jet = rmdi
    env%co2_interactive = rmdi
    env%rim_cry = rmdi
    env%rim_agg = rmdi
    env%vertvel = rmdi
    env%bl_tke = rmdi
    env%interf_z = rmdi
    env%grid_area_fullht = rmdi
    env%grid_volume = rmdi
    env%grid_airmass = rmdi
    env%rel_humid_frac = rmdi
    env%rel_humid_frac_clr = rmdi
    env%qsvp = rmdi
    env%h2o2_offline = rmdi
    env%ho2_offline = rmdi
    env%no3_offline = rmdi
    env%o3_offline = rmdi
    env%oh_offline = rmdi
    env%r_theta_levels = rmdi
    env%r_rho_levels = rmdi
    env%p_rho_levels = rmdi
    env%aod_sulph_accum = rmdi
    env%aod_sulph_aitk = rmdi

    ! 4D real defaults
    env%photol_rates = rmdi

  endsubroutine create_box_environment_type

  subroutine read_box_environment_nml(filename, env)

    !! Read in the box environment namelist and store the values in the box
    !! environment type. This is used to read in the environmental fields for
    !! the box model.

    use box_debug_mod, only: is_debug_level
    use box_err_codes_mod, only: box_errcode_env_namelist

    !> Path to the environment namelist file
    character(len=*), intent(in)  :: filename
    !> return message from opening file
    character(len=256) :: iomsg
    !> Error code for error reporting
    integer :: err_code
    !> unit for opening file
    integer :: unit
    !> loop index
    integer :: i
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: err_msg
    !> Routine name for error reporting
    character(len=ukca_maxlen_procname), parameter :: &
      routine_name = mod_name//":read_box_environment_nml"
    !> I/O status for opening
    integer :: iostat_open
    !> I/O status for reading
    integer :: iostat_read
    !> Debug level to start recording debug message
    integer, parameter :: min_debug_level = 1

    ! create an array of namelist names
    character(len=28), dimension(7), &
      parameter :: nml_names = [ &
                   "core_environment            ", &
                   "photolysis_environment      ", &
                   "prescribed_conc_environment ", &
                   "deposition_environment      ", &
                   "emissions_environment       ", &
                   "aerosol_environment         ", &
                   "offlinechem_environment     "]

    !> environment type to store the environment
    type(box_environment_type), intent(inout) :: env

    !> real scalar environment fields
    real :: z_top_of_model, sin_declination, equation_of_time, &
            atmospheric_ch4, atmospheric_co2, atmospheric_h2, atmospheric_n2, &
            atmospheric_o2, atmospheric_n2o, &
            atmospheric_cfc11, atmospheric_cfc12, &
            atmospheric_cfc113, atmospheric_hcfc22, atmospheric_hfc125, &
            atmospheric_hfc134a, atmospheric_mebr, atmospheric_mecl, &
            atmospheric_ch2br2, atmospheric_chbr3, atmospheric_cfc114, &
            atmospheric_cfc115, atmospheric_ccl4, atmospheric_meccl3, &
            atmospheric_hcfc141b, atmospheric_hcfc142b, atmospheric_h1211, &
            atmospheric_h1202, atmospheric_h1301, atmospheric_h2402, &
            atmospheric_cos

    !> real 1D environment fields
    real :: soil_moisture_layer1, fland, &
            ibvoc_isoprene, ibvoc_terpene, &
            ibvoc_methanol, ibvoc_acetone, &
            inferno_bc, inferno_ch4, inferno_co, &
            inferno_nox, inferno_oc, inferno_so2, inferno_c2h4, inferno_c2h6, &
            inferno_c3h8, inferno_hcho, inferno_mecho, inferno_nh3, inferno_dms

    !> real 2D environment fields
    real :: latitude, longitude, &
            conv_cloud_lwp, tstar, zbl, rough_length, &
            seaice_frac, frac_types, laift_lp, &
            canhtft_lp, tstar_tile, z0tile_lp, &
            pstar, surf_albedo, zhsc, u_scalar_10m, &
            surf_hf, u_s, ch4_wetl_emiss, &
            dms_sea_conc, chloro_sea, &
            dust_flux_div1, dust_flux_div2, dust_flux_div3, &
            dust_flux_div4, dust_flux_div5, dust_flux_div6, &
            surf_wetness, grid_surf_area, &
            ext_cg_flash, ext_ic_flash

    !> integer 2D environment fields
    integer :: kent, kent_dsc, conv_cloud_base, conv_cloud_top, lscat_zhang

    !> logical 2D environment fields
    logical :: land_sea_mask, l_tile_active

    !> real 3D environment fields
    real :: u_rho_levels, v_rho_levels, geopH_on_theta_mlevs, q, qcf, &
            conv_cloud_amount, rho_r2, qcl, &
            area_cloud_fraction, &
            cloud_frac, cloud_liq_frac, &
            p_layer_boundaries, &
            p_theta_levels, t_theta_levels, &
            rhokh_rdz, dtrdz, we_lim, t_frac, zrzi, &
            we_lim_dsc, t_frac_dsc, zrzi_dsc, stcon, &
            ls_rain3d, ls_snow3d, autoconv, &
            accretion, pv_on_theta_mlevs, &
            conv_rain3d, conv_snow3d, so4_sa_clim, &
            so4_aitken, so4_accum, soot_fresh, &
            soot_aged, ocff_fresh, ocff_aged, &
            biogenic, dust_div1, dust_div2, dust_div3, dust_div4, dust_div5, &
            dust_div6, sea_salt_film, sea_salt_jet, co2_interactive, rim_cry, &
            rim_agg, vertvel, bl_tke, interf_z, &
            grid_area_fullht, grid_volume, &
            grid_airmass, rel_humid_frac, &
            rel_humid_frac_clr, qsvp, h2o2_offline, &
            ho2_offline, no3_offline, o3_offline, &
            oh_offline, aod_sulph_accum, &
            aod_sulph_aitk

    ! setup the namelists - variables separated by where the field are used in
    ! the code, e.g. photolysis will be environment fields used by photolysis
    ! code
    namelist /core_environment/ z_top_of_model, latitude, longitude, tstar, &
      zbl, rough_length, seaice_frac, pstar, u_s, conv_cloud_base, &
      conv_cloud_top, land_sea_mask, q, qcf, rho_r2, qcl, cloud_frac, &
      p_layer_boundaries, p_theta_levels, t_theta_levels, &
      ls_rain3d, ls_snow3d, pv_on_theta_mlevs, conv_rain3d, conv_snow3d, &
      co2_interactive, grid_volume, grid_airmass, rel_humid_frac, &
      rel_humid_frac_clr, qsvp

    namelist /photolysis_environment/ sin_declination, equation_of_time, &
      conv_cloud_lwp, surf_albedo, conv_cloud_amount, area_cloud_fraction, &
      aod_sulph_accum, aod_sulph_aitk

    namelist /prescribed_conc_environment/ atmospheric_ch4, atmospheric_co2, &
      atmospheric_h2, atmospheric_n2, atmospheric_o2, atmospheric_n2o, &
      atmospheric_cfc11, atmospheric_cfc12, atmospheric_cfc113, &
      atmospheric_hcfc22, atmospheric_hfc125, atmospheric_hfc134a, &
      atmospheric_mebr, atmospheric_mecl, atmospheric_ch2br2, &
      atmospheric_chbr3, atmospheric_cfc114, atmospheric_cfc115, &
      atmospheric_ccl4, atmospheric_meccl3, atmospheric_hcfc141b, &
      atmospheric_hcfc142b, atmospheric_h1211, atmospheric_h1202, &
      atmospheric_h1301, atmospheric_h2402, atmospheric_cos

    namelist /deposition_environment/ soil_moisture_layer1, &
      fland, frac_types, &
      laift_lp, canhtft_lp, tstar_tile, z0tile_lp, surf_hf, surf_wetness, &
      l_tile_active, stcon

    namelist /emissions_environment/ ibvoc_isoprene, ibvoc_terpene, &
      ibvoc_methanol, ibvoc_acetone, inferno_bc, inferno_ch4, inferno_co, &
      inferno_nox, inferno_oc, inferno_so2, inferno_c2h4, inferno_c2h6, &
      inferno_c3h8, inferno_hcho, inferno_mecho, inferno_nh3, inferno_dms, &
      zhsc, u_scalar_10m, ch4_wetl_emiss, dms_sea_conc, chloro_sea, &
      dust_flux_div1, dust_flux_div2, dust_flux_div3, dust_flux_div4, &
      dust_flux_div5, dust_flux_div6, grid_surf_area, ext_cg_flash, &
      ext_ic_flash, kent, kent_dsc, &
      u_rho_levels, v_rho_levels, geopH_on_theta_mlevs, &
      rhokh_rdz, dtrdz, we_lim, t_frac, zrzi, we_lim_dsc, t_frac_dsc, &
      zrzi_dsc, dust_div1, dust_div2, dust_div3, dust_div4, dust_div5, &
      dust_div6, interf_z, grid_area_fullht

    namelist /aerosol_environment/ lscat_zhang, cloud_liq_frac, autoconv, &
      accretion, so4_sa_clim, so4_aitken, so4_accum, soot_fresh, soot_aged, &
      ocff_fresh, ocff_aged, biogenic, sea_salt_film, sea_salt_jet, rim_cry, &
      rim_agg, vertvel, bl_tke

    namelist /offlinechem_environment/ h2o2_offline, &
      ho2_offline, no3_offline, &
      o3_offline, oh_offline

    iostat_open = 0
    iostat_read = 0

    ! creates the box environment type and allocates the arrays
    call create_box_environment_type(env)

    ! defaults - real scalar environment fields
    z_top_of_model = rmdi
    sin_declination = rmdi
    equation_of_time = rmdi
    atmospheric_ch4 = rmdi
    atmospheric_co2 = rmdi
    atmospheric_h2 = rmdi
    atmospheric_n2 = rmdi
    atmospheric_o2 = rmdi
    atmospheric_n2o = rmdi
    atmospheric_cfc11 = rmdi
    atmospheric_cfc12 = rmdi
    atmospheric_cfc113 = rmdi
    atmospheric_hcfc22 = rmdi
    atmospheric_hfc125 = rmdi
    atmospheric_hfc134a = rmdi
    atmospheric_mebr = rmdi
    atmospheric_mecl = rmdi
    atmospheric_ch2br2 = rmdi
    atmospheric_chbr3 = rmdi
    atmospheric_cfc114 = rmdi
    atmospheric_cfc115 = rmdi
    atmospheric_ccl4 = rmdi
    atmospheric_meccl3 = rmdi
    atmospheric_hcfc141b = rmdi
    atmospheric_hcfc142b = rmdi
    atmospheric_h1211 = rmdi
    atmospheric_h1202 = rmdi
    atmospheric_h1301 = rmdi
    atmospheric_h2402 = rmdi
    atmospheric_cos = rmdi

    ! defaults - real 1D environment fields
    soil_moisture_layer1 = rmdi
    fland = rmdi
    ibvoc_isoprene = rmdi
    ibvoc_terpene = rmdi
    ibvoc_methanol = rmdi
    ibvoc_acetone = rmdi
    inferno_bc = rmdi
    inferno_ch4 = rmdi
    inferno_co = rmdi
    inferno_nox = rmdi
    inferno_oc = rmdi
    inferno_so2 = rmdi
    inferno_c2h4 = rmdi
    inferno_c2h6 = rmdi
    inferno_c3h8 = rmdi
    inferno_hcho = rmdi
    inferno_mecho = rmdi
    inferno_nh3 = rmdi
    inferno_dms = rmdi

    ! defaults - real 2D environment fields
    latitude = rmdi
    longitude = rmdi
    conv_cloud_lwp = rmdi
    tstar = rmdi
    zbl = rmdi
    rough_length = rmdi
    seaice_frac = rmdi
    frac_types = rmdi
    laift_lp = rmdi
    canhtft_lp = rmdi
    tstar_tile = rmdi
    z0tile_lp = rmdi
    pstar = rmdi
    surf_albedo = rmdi
    zhsc = rmdi
    u_scalar_10m = rmdi
    surf_hf = rmdi
    u_s = rmdi
    ch4_wetl_emiss = rmdi
    dms_sea_conc = rmdi
    chloro_sea = rmdi
    surf_wetness = rmdi
    grid_surf_area = rmdi
    ext_cg_flash = rmdi
    ext_ic_flash = rmdi

    ! defaults - integer 2D environment fields
    kent = imdi
    kent_dsc = imdi
    conv_cloud_base = imdi
    conv_cloud_top = imdi
    lscat_zhang = imdi

    ! defaults - logical 2D fields
    land_sea_mask = .false.
    l_tile_active = .false.

    ! defaults - real 3D fields
    dust_flux_div1 = rmdi
    dust_flux_div2 = rmdi
    dust_flux_div3 = rmdi
    dust_flux_div4 = rmdi
    dust_flux_div5 = rmdi
    dust_flux_div6 = rmdi
    u_rho_levels = rmdi
    v_rho_levels = rmdi
    geopH_on_theta_mlevs = rmdi
    q = rmdi
    qcf = rmdi
    conv_cloud_amount = rmdi
    rho_r2 = rmdi
    qcl = rmdi
    area_cloud_fraction = rmdi
    cloud_frac = rmdi
    cloud_liq_frac = rmdi
    p_layer_boundaries = rmdi
    p_theta_levels = rmdi
    t_theta_levels = rmdi
    rhokh_rdz = rmdi
    dtrdz = rmdi
    we_lim = rmdi
    t_frac = rmdi
    zrzi = rmdi
    we_lim_dsc = rmdi
    t_frac_dsc = rmdi
    zrzi_dsc = rmdi
    stcon = rmdi
    ls_rain3d = rmdi
    ls_snow3d = rmdi
    autoconv = rmdi
    accretion = rmdi
    pv_on_theta_mlevs = rmdi
    conv_rain3d = rmdi
    conv_snow3d = rmdi
    so4_sa_clim = rmdi
    so4_aitken = rmdi
    so4_accum = rmdi
    soot_fresh = rmdi
    soot_aged = rmdi
    ocff_fresh = rmdi
    ocff_aged = rmdi
    biogenic = rmdi
    dust_div1 = rmdi
    dust_div2 = rmdi
    dust_div3 = rmdi
    dust_div4 = rmdi
    dust_div5 = rmdi
    dust_div6 = rmdi
    sea_salt_film = rmdi
    sea_salt_jet = rmdi
    co2_interactive = rmdi
    rim_cry = rmdi
    rim_agg = rmdi
    vertvel = rmdi
    bl_tke = rmdi
    interf_z = rmdi
    grid_area_fullht = rmdi
    grid_volume = rmdi
    grid_airmass = 0.0
    rel_humid_frac = rmdi
    rel_humid_frac_clr = rmdi
    qsvp = rmdi
    h2o2_offline = rmdi
    ho2_offline = rmdi
    no3_offline = rmdi
    o3_offline = rmdi
    oh_offline = rmdi
    aod_sulph_accum = rmdi
    aod_sulph_aitk = rmdi

    open(newunit=unit, file=filename, status='old', action='read', &
         iostat=iostat_open, iomsg=iomsg)

    if(iostat_open /= 0) then
      write(err_msg, "(4A)") "Error opening env namelist file '", &
        trim(filename), "'. Original error: ", trim(iomsg)
      err_code = box_errcode_env_namelist
      call ereport(routine_name, err_code, err_msg)
    endif

    ! for each namelist loop over read logic
    do i = 1, size(nml_names)
      rewind(unit)
      select case(trim(nml_names(i)))
      case("core_environment")
        read(unit, nml=core_environment, iostat=iostat_read, iomsg=iomsg)
      case("photolysis_environment")
        read(unit, nml=photolysis_environment, iostat=iostat_read, iomsg=iomsg)
      case("prescribed_conc_environment")
        read(unit, nml=prescribed_conc_environment, iostat=iostat_read, &
             iomsg=iomsg)
      case("deposition_environment")
        read(unit, nml=deposition_environment, iostat=iostat_read, iomsg=iomsg)
      case("emissions_environment")
        read(unit, nml=emissions_environment, iostat=iostat_read, iomsg=iomsg)
      case("aerosol_environment")
        read(unit, nml=aerosol_environment, iostat=iostat_read, iomsg=iomsg)
      case("offlinechem_environment")
        read(unit, nml=offlinechem_environment, iostat=iostat_read, &
             iomsg=iomsg)
      case default
        err_code = box_errcode_env_namelist
        write(err_msg, "(2A)") "Unexpected namelist section called: ", &
          trim(nml_names(i))
        call ereport(routine_name, err_code, err_msg)
      endselect

      ! check if the section was missing and warn or if there was an actual
      ! read error
      if(is_iostat_end(iostat_read)) then
        err_code = -box_errcode_env_namelist
        write(err_msg, "(3A)") "Unable to find a namelist section for ", &
          trim(nml_names(i)), &
          " in the config file. Using missing values for fields."
        call ereport(routine_name, err_code, err_msg)
      else if(iostat_read /= 0) then
        err_code = box_errcode_env_namelist
        write(err_msg, "(4A)") "Error recorded reading namelist section: ", &
          trim(nml_names(i)), '. Original error msg: ', trim(iomsg)
        call ereport(routine_name, err_code, err_msg)
      else if(is_debug_level(min_debug_level)) then
        write(umMessage, "(3A)") "Read namelist '", trim(nml_names(i)), "'"
        call umPrint(umMessage, src=routine_name)
      endif

    enddo

    close(unit)

    ! real scalar fields
    env%z_top_of_model = z_top_of_model
    env%sin_declination = sin_declination
    env%equation_of_time = equation_of_time
    env%atmospheric_ch4 = atmospheric_ch4
    env%atmospheric_co2 = atmospheric_co2
    env%atmospheric_h2 = atmospheric_h2
    env%atmospheric_n2 = atmospheric_n2
    env%atmospheric_o2 = atmospheric_o2
    env%atmospheric_n2o = atmospheric_n2o
    env%atmospheric_cfc11 = atmospheric_cfc11
    env%atmospheric_cfc12 = atmospheric_cfc12
    env%atmospheric_cfc113 = atmospheric_cfc113
    env%atmospheric_hcfc22 = atmospheric_hcfc22
    env%atmospheric_hfc125 = atmospheric_hfc125
    env%atmospheric_hfc134a = atmospheric_hfc134a
    env%atmospheric_mebr = atmospheric_mebr
    env%atmospheric_mecl = atmospheric_mecl
    env%atmospheric_ch2br2 = atmospheric_ch2br2
    env%atmospheric_chbr3 = atmospheric_chbr3
    env%atmospheric_cfc114 = atmospheric_cfc114
    env%atmospheric_cfc115 = atmospheric_cfc115
    env%atmospheric_ccl4 = atmospheric_ccl4
    env%atmospheric_meccl3 = atmospheric_meccl3
    env%atmospheric_hcfc141b = atmospheric_hcfc141b
    env%atmospheric_hcfc142b = atmospheric_hcfc142b
    env%atmospheric_h1211 = atmospheric_h1211
    env%atmospheric_h1202 = atmospheric_h1202
    env%atmospheric_h1301 = atmospheric_h1301
    env%atmospheric_h2402 = atmospheric_h2402
    env%atmospheric_cos = atmospheric_cos

    ! real 1D fields
    env%soil_moisture_layer1 = soil_moisture_layer1
    env%fland = fland
    env%ibvoc_isoprene = ibvoc_isoprene
    env%ibvoc_terpene = ibvoc_terpene
    env%ibvoc_methanol = ibvoc_methanol
    env%ibvoc_acetone = ibvoc_acetone
    env%inferno_bc = inferno_bc
    env%inferno_ch4 = inferno_ch4
    env%inferno_co = inferno_co
    env%inferno_nox = inferno_nox
    env%inferno_oc = inferno_oc
    env%inferno_so2 = inferno_so2
    env%inferno_c2h4 = inferno_c2h4
    env%inferno_c2h6 = inferno_c2h6
    env%inferno_c3h8 = inferno_c3h8
    env%inferno_hcho = inferno_hcho
    env%inferno_mecho = inferno_mecho
    env%inferno_nh3 = inferno_nh3
    env%inferno_dms = inferno_dms

    ! real 2D fields
    env%latitude = latitude
    env%longitude = longitude
    env%conv_cloud_lwp = conv_cloud_lwp
    env%tstar = tstar
    env%zbl = zbl
    env%rough_length = rough_length
    env%seaice_frac = seaice_frac
    env%frac_types = frac_types
    env%laift_lp = laift_lp
    env%canhtft_lp = canhtft_lp
    env%tstar_tile = tstar_tile
    env%z0tile_lp = z0tile_lp
    env%pstar = pstar
    env%surf_albedo = surf_albedo
    env%zhsc = zhsc
    env%u_scalar_10m = u_scalar_10m
    env%surf_hf = surf_hf
    env%u_s = u_s
    env%ch4_wetl_emiss = ch4_wetl_emiss
    env%dms_sea_conc = dms_sea_conc
    env%chloro_sea = chloro_sea
    env%surf_wetness = surf_wetness
    env%grid_surf_area = grid_surf_area
    env%ext_cg_flash = ext_cg_flash
    env%ext_ic_flash = ext_ic_flash

    ! integer 2D fields
    env%kent = kent
    env%kent_dsc = kent_dsc
    env%conv_cloud_base = conv_cloud_base
    env%conv_cloud_top = conv_cloud_top
    env%lscat_zhang = lscat_zhang

    ! logical 2D fields
    env%land_sea_mask = land_sea_mask
    env%l_tile_active = l_tile_active

    ! real 3D fields
    env%dust_flux_div1 = dust_flux_div1
    env%dust_flux_div2 = dust_flux_div2
    env%dust_flux_div3 = dust_flux_div3
    env%dust_flux_div4 = dust_flux_div4
    env%dust_flux_div5 = dust_flux_div5
    env%dust_flux_div6 = dust_flux_div6
    env%u_rho_levels = u_rho_levels
    env%v_rho_levels = v_rho_levels
    env%geopH_on_theta_mlevs = geopH_on_theta_mlevs
    env%q = q
    env%qcf = qcf
    env%conv_cloud_amount = conv_cloud_amount
    env%rho_r2 = rho_r2
    env%qcl = qcl
    env%area_cloud_fraction = area_cloud_fraction
    env%cloud_frac = cloud_frac
    env%cloud_liq_frac = cloud_liq_frac
    env%p_layer_boundaries = p_layer_boundaries
    env%p_theta_levels = p_theta_levels
    env%t_theta_levels = t_theta_levels
    env%rhokh_rdz = rhokh_rdz
    env%dtrdz = dtrdz
    env%we_lim = we_lim
    env%t_frac = t_frac
    env%zrzi = zrzi
    env%we_lim_dsc = we_lim_dsc
    env%t_frac_dsc = t_frac_dsc
    env%zrzi_dsc = zrzi_dsc
    env%stcon = stcon
    env%ls_rain3d = ls_rain3d
    env%ls_snow3d = ls_snow3d
    env%autoconv = autoconv
    env%accretion = accretion
    env%pv_on_theta_mlevs = pv_on_theta_mlevs
    env%conv_rain3d = conv_rain3d
    env%conv_snow3d = conv_snow3d
    env%so4_sa_clim = so4_sa_clim
    env%so4_aitken = so4_aitken
    env%so4_accum = so4_accum
    env%soot_fresh = soot_fresh
    env%soot_aged = soot_aged
    env%ocff_fresh = ocff_fresh
    env%ocff_aged = ocff_aged
    env%biogenic = biogenic
    env%dust_div1 = dust_div1
    env%dust_div2 = dust_div2
    env%dust_div3 = dust_div3
    env%dust_div4 = dust_div4
    env%dust_div5 = dust_div5
    env%dust_div6 = dust_div6
    env%sea_salt_film = sea_salt_film
    env%sea_salt_jet = sea_salt_jet
    env%co2_interactive = co2_interactive
    env%rim_cry = rim_cry
    env%rim_agg = rim_agg
    env%vertvel = vertvel
    env%bl_tke = bl_tke
    env%interf_z = interf_z
    env%grid_area_fullht = grid_area_fullht
    env%grid_volume = grid_volume
    env%grid_airmass = grid_airmass
    env%rel_humid_frac = rel_humid_frac
    env%rel_humid_frac_clr = rel_humid_frac_clr
    env%qsvp = qsvp
    env%h2o2_offline = h2o2_offline
    env%ho2_offline = ho2_offline
    env%no3_offline = no3_offline
    env%o3_offline = o3_offline
    env%oh_offline = oh_offline
    env%aod_sulph_accum = aod_sulph_accum
    env%aod_sulph_aitk = aod_sulph_aitk

  endsubroutine read_box_environment_nml

  subroutine print_box_environment(env)

    !! Print the box environment to the console. This is used for logging and
    !! debugging purposes. Fields are categorised by where they are used in the
    !! code, e.g. photolysis environment section will be fields used primarily
    !! by the photolysis code.

    use box_debug_mod, only: is_debug_level

    !> The box environment to print
    type(box_environment_type), intent(in) :: env
    !> Routine name for logging
    character(len=*), parameter :: routine_name = &
                                   mod_name//":print_box_environment"

    !> Column at which values start, after the field label
    integer, parameter :: label_width = 45

    !> Formats for integer, real, scientific and logical values
    character(len=80) :: fmt_int, fmt_real, fmt_sci, fmt_log

    ! Create format strings with dynamic field widths
    fmt_int = '(A, T'//int_to_string(label_width)//', F0.0)'
    fmt_real = '(A, T'//int_to_string(label_width)//', G0.5)'
    fmt_sci = '(A, T'//int_to_string(label_width)//', ES11.4)'
    fmt_log = '(A, T'//int_to_string(label_width)//', L1)'

    ! Print core namelist variables
    call umPrint('Core Environment:', src=routine_name)
    call print_field('  z_top_of_model', env%z_top_of_model, fmt_real)
    call print_field('  latitude', env%latitude(1, 1), fmt_real)
    call print_field('  true_latitude', env%true_latitude(1, 1), fmt_real)
    call print_field('  longitude', env%longitude(1, 1), fmt_real)
    call print_field('  true_longitude', env%true_longitude(1, 1), fmt_real)
    call print_field('  sin_latitude', env%sin_latitude(1, 1), fmt_real)
    call print_field('  cos_latitude', env%cos_latitude(1, 1), fmt_real)
    call print_field('  tan_latitude', env%tan_latitude(1, 1), fmt_real)
    call print_field('  tstar', env%tstar(1, 1), fmt_real)
    call print_field('  zbl', env%zbl(1, 1), fmt_real)
    call print_field('  rough_length', env%rough_length(1, 1), fmt_real)
    call print_field('  seaice_frac', env%seaice_frac(1, 1), fmt_real)
    call print_field('  pstar', env%pstar(1, 1), fmt_real)
    call print_field('  u_s', env%u_s(1, 1), fmt_real)
    call print_field('  conv_cloud_base', env%conv_cloud_base(1, 1), fmt_int)
    call print_field('  conv_cloud_top', env%conv_cloud_top(1, 1), fmt_int)
    call print_field('  land_sea_mask', env%land_sea_mask(1, 1), fmt_log)
    call print_field('  theta', env%theta(1, 1, 1), fmt_real)
    call print_field('  q', env%q(1, 1, 1), fmt_sci)
    call print_field('  qcf', env%qcf(1, 1, 1), fmt_sci)
    call print_field('  rho_r2', env%rho_r2(1, 1, 1), fmt_real)
    call print_field('  qcl', env%qcl(1, 1, 1), fmt_real)
    call print_field('  cloud_frac', env%cloud_frac(1, 1, 1), fmt_real)
    call print_field('  exner_theta_levels', env%exner_theta_levels(1, 1, 1), &
                     fmt_real)
    call print_field('  exner_rho_levels', env%exner_rho_levels(1, 1, 1), &
                     fmt_real)
    call print_field('  p_layer_boundaries', env%p_layer_boundaries(1, 1, 1), &
                     fmt_real)
    call print_field('  t_theta_levels', env%t_theta_levels(1, 1, 1), fmt_real)
    call print_field('  p_theta_levels', env%p_theta_levels(1, 1, 1), fmt_real)
    call print_field('  ls_rain3d', env%ls_rain3d(1, 1, 1), fmt_real)
    call print_field('  ls_snow3d', env%ls_snow3d(1, 1, 1), fmt_real)
    call print_field('  pv_on_theta_mlevs', env%pv_on_theta_mlevs(1, 1, 1), &
                     fmt_real)
    call print_field('  conv_rain3d', env%conv_rain3d(1, 1, 1), fmt_real)
    call print_field('  conv_snow3d', env%conv_snow3d(1, 1, 1), fmt_real)
    call print_field('  co2_interactive', &
                     env%co2_interactive(1, 1, 1), fmt_real)
    call print_field('  grid_volume', env%grid_volume(1, 1, 1), fmt_real)
    call print_field('  grid_airmass', env%grid_airmass(1, 1, 1), fmt_real)
    call print_field('  rel_humid_frac', env%rel_humid_frac(1, 1, 1), fmt_real)
    call print_field('  rel_humid_frac_clr', env%rel_humid_frac_clr(1, 1, 1), &
                     fmt_real)
    call print_field('  qsvp', env%qsvp(1, 1, 1), fmt_real)
    call print_field('  p_rho_levels', env%p_rho_levels(1, 1, 1), fmt_real)
    call print_field('  eta_theta_levels', env%eta_theta_levels(1), fmt_real)
    call print_field('  r_theta_levels', env%r_theta_levels(1, 1, 1), fmt_real)
    call print_field('  r_rho_levels', env%r_rho_levels(1, 1, 1), fmt_real)
    call umPrint('', src=routine_name)

    ! Print photolysis namelist variables
    call umPrint('Photolysis Environment:', src=routine_name)
    call print_field('  sin_declination', env%sin_declination, fmt_real)
    call print_field('  equation_of_time', env%equation_of_time, fmt_real)
    call print_field('  conv_cloud_lwp', env%conv_cloud_lwp(1, 1), fmt_real)
    call print_field('  surf_albedo', env%surf_albedo(1, 1), fmt_real)
    call print_field('  conv_cloud_amount', env%conv_cloud_amount(1, 1, 1), &
                     fmt_real)
    call print_field('  area_cloud_fraction', &
                     env%area_cloud_fraction(1, 1, 1), &
                     fmt_real)
    ! photolysis rates are calculated each time step, after this is printed
    call umPrint('  photol_rates: printed by box_photol_mod (debug)', &
                 src=routine_name)
    call print_field('  aod_sulph_accum', &
                     env%aod_sulph_accum(1, 1, 1), fmt_real)
    call print_field('  aod_sulph_aitk', env%aod_sulph_aitk(1, 1, 1), fmt_real)
    call umPrint('', src=routine_name)

    ! Print prescribed concentration namelist variables
    call umPrint('Prescribed Concentration Environment:', src=routine_name)
    call print_field('  atmospheric_ch4', env%atmospheric_ch4, fmt_real)
    call print_field('  atmospheric_co2', env%atmospheric_co2, fmt_real)
    call print_field('  atmospheric_h2', env%atmospheric_h2, fmt_real)
    call print_field('  atmospheric_n2', env%atmospheric_n2, fmt_real)
    call print_field('  atmospheric_o2', env%atmospheric_o2, fmt_real)
    call print_field('  atmospheric_n2o', env%atmospheric_n2o, fmt_real)
    call print_field('  atmospheric_cfc11', env%atmospheric_cfc11, fmt_real)
    call print_field('  atmospheric_cfc12', env%atmospheric_cfc12, fmt_real)
    call print_field('  atmospheric_cfc113', env%atmospheric_cfc113, fmt_real)
    call print_field('  atmospheric_hcfc22', env%atmospheric_hcfc22, fmt_real)
    call print_field('  atmospheric_hfc125', env%atmospheric_hfc125, fmt_real)
    call print_field('  atmospheric_hfc134a', env%atmospheric_hfc134a, &
                     fmt_real)
    call print_field('  atmospheric_mebr', env%atmospheric_mebr, fmt_real)
    call print_field('  atmospheric_mecl', env%atmospheric_mecl, fmt_real)
    call print_field('  atmospheric_ch2br2', env%atmospheric_ch2br2, fmt_real)
    call print_field('  atmospheric_chbr3', env%atmospheric_chbr3, fmt_real)
    call print_field('  atmospheric_cfc114', env%atmospheric_cfc114, fmt_real)
    call print_field('  atmospheric_cfc115', env%atmospheric_cfc115, fmt_real)
    call print_field('  atmospheric_ccl4', env%atmospheric_ccl4, fmt_real)
    call print_field('  atmospheric_meccl3', env%atmospheric_meccl3, fmt_real)
    call print_field('  atmospheric_hcfc141b', env%atmospheric_hcfc141b, &
                     fmt_real)
    call print_field('  atmospheric_hcfc142b', env%atmospheric_hcfc142b, &
                     fmt_real)
    call print_field('  atmospheric_h1211', env%atmospheric_h1211, fmt_real)
    call print_field('  atmospheric_h1202', env%atmospheric_h1202, fmt_real)
    call print_field('  atmospheric_h1301', env%atmospheric_h1301, fmt_real)
    call print_field('  atmospheric_h2402', env%atmospheric_h2402, fmt_real)
    call print_field('  atmospheric_cos', env%atmospheric_cos, fmt_real)
    call umPrint('', src=routine_name)

    ! Print deposition namelist variables
    call umPrint('Deposition Environment:', src=routine_name)
    call print_field('  soil_moisture_layer1', env%soil_moisture_layer1(1), &
                     fmt_real)
    call print_field('  fland', env%fland(1), fmt_real)
    call print_field('  frac_types', env%frac_types(1, 1), fmt_real)
    call print_field('  laift_lp', env%laift_lp(1, 1), fmt_real)
    call print_field('  canhtft_lp', env%canhtft_lp(1, 1), fmt_real)
    call print_field('  tstar_tile', env%tstar_tile(1, 1), fmt_real)
    call print_field('  z0tile_lp', env%z0tile_lp(1, 1), fmt_real)
    call print_field('  surf_hf', env%surf_hf(1, 1), fmt_real)
    call print_field('  surf_wetness', env%surf_wetness(1, 1), fmt_real)
    call print_field('  l_tile_active', env%l_tile_active(1, 1), fmt_log)
    call print_field('  stcon', env%stcon(1, 1, 1), fmt_real)
    call umPrint('', src=routine_name)

    ! Print emissions namelist variables
    call umPrint('Emissions Environment:', src=routine_name)
    call print_field('  ibvoc_isoprene', env%ibvoc_isoprene(1), fmt_real)
    call print_field('  ibvoc_terpene', env%ibvoc_terpene(1), fmt_real)
    call print_field('  ibvoc_methanol', env%ibvoc_methanol(1), fmt_real)
    call print_field('  ibvoc_acetone', env%ibvoc_acetone(1), fmt_real)
    call print_field('  inferno_bc', env%inferno_bc(1), fmt_real)
    call print_field('  inferno_ch4', env%inferno_ch4(1), fmt_real)
    call print_field('  inferno_co', env%inferno_co(1), fmt_real)
    call print_field('  inferno_nox', env%inferno_nox(1), fmt_real)
    call print_field('  inferno_oc', env%inferno_oc(1), fmt_real)
    call print_field('  inferno_so2', env%inferno_so2(1), fmt_real)
    call print_field('  inferno_c2h4', env%inferno_c2h4(1), fmt_real)
    call print_field('  inferno_c2h6', env%inferno_c2h6(1), fmt_real)
    call print_field('  inferno_c3h8', env%inferno_c3h8(1), fmt_real)
    call print_field('  inferno_hcho', env%inferno_hcho(1), fmt_real)
    call print_field('  inferno_mecho', env%inferno_mecho(1), fmt_real)
    call print_field('  inferno_nh3', env%inferno_nh3(1), fmt_real)
    call print_field('  inferno_dms', env%inferno_dms(1), fmt_real)
    call print_field('  zhsc', env%zhsc(1, 1), fmt_real)
    call print_field('  u_scalar_10m', env%u_scalar_10m(1, 1), fmt_real)
    call print_field('  ch4_wetl_emiss', env%ch4_wetl_emiss(1, 1), fmt_real)
    call print_field('  dms_sea_conc', env%dms_sea_conc(1, 1), fmt_real)
    call print_field('  chloro_sea', env%chloro_sea(1, 1), fmt_real)
    call print_field('  dust_flux_div1', env%dust_flux_div1(1, 1), fmt_real)
    call print_field('  dust_flux_div2', env%dust_flux_div2(1, 1), fmt_real)
    call print_field('  dust_flux_div3', env%dust_flux_div3(1, 1), fmt_real)
    call print_field('  dust_flux_div4', env%dust_flux_div4(1, 1), fmt_real)
    call print_field('  dust_flux_div5', env%dust_flux_div5(1, 1), fmt_real)
    call print_field('  dust_flux_div6', env%dust_flux_div6(1, 1), fmt_real)
    call print_field('  grid_surf_area', env%grid_surf_area(1, 1), fmt_real)
    call print_field('  ext_cg_flash', env%ext_cg_flash(1, 1), fmt_real)
    call print_field('  ext_ic_flash', env%ext_ic_flash(1, 1), fmt_real)
    call print_field('  kent', env%kent(1, 1), fmt_int)
    call print_field('  kent_dsc', env%kent_dsc(1, 1), fmt_int)
    call print_field('  u_rho_levels', env%u_rho_levels(1, 1, 1), fmt_real)
    call print_field('  v_rho_levels', env%v_rho_levels(1, 1, 1), fmt_real)
    call print_field('  geopH_on_theta_mlevs', &
                     env%geopH_on_theta_mlevs(1, 1, 1), fmt_real)
    call print_field('  rhokh_rdz', env%rhokh_rdz(1, 1, 1), fmt_real)
    call print_field('  dtrdz', env%dtrdz(1, 1, 1), fmt_real)
    call print_field('  we_lim', env%we_lim(1, 1, 1), fmt_real)
    call print_field('  t_frac', env%t_frac(1, 1, 1), fmt_real)
    call print_field('  zrzi', env%zrzi(1, 1, 1), fmt_real)
    call print_field('  we_lim_dsc', env%we_lim_dsc(1, 1, 1), fmt_real)
    call print_field('  t_frac_dsc', env%t_frac_dsc(1, 1, 1), fmt_real)
    call print_field('  zrzi_dsc', env%zrzi_dsc(1, 1, 1), fmt_real)
    call print_field('  dust_div1', env%dust_div1(1, 1, 1), fmt_real)
    call print_field('  dust_div2', env%dust_div2(1, 1, 1), fmt_real)
    call print_field('  dust_div3', env%dust_div3(1, 1, 1), fmt_real)
    call print_field('  dust_div4', env%dust_div4(1, 1, 1), fmt_real)
    call print_field('  dust_div5', env%dust_div5(1, 1, 1), fmt_real)
    call print_field('  dust_div6', env%dust_div6(1, 1, 1), fmt_real)
    call print_field('  interf_z', env%interf_z(1, 1, 1), fmt_real)
    call print_field('  grid_area_fullht', env%grid_area_fullht(1, 1, 1), &
                     fmt_real)
    call umPrint('', src=routine_name)

    ! Print aerosol namelist variables
    call umPrint('Aerosol Environment:', src=routine_name)
    call print_field('  lscat_zhang', env%lscat_zhang(1, 1), fmt_int)
    call print_field('  cloud_liq_frac', env%cloud_liq_frac(1, 1, 1), fmt_real)
    call print_field('  autoconv', env%autoconv(1, 1, 1), fmt_real)
    call print_field('  accretion', env%accretion(1, 1, 1), fmt_real)
    call print_field('  so4_sa_clim', env%so4_sa_clim(1, 1, 1), fmt_real)
    call print_field('  so4_aitken', env%so4_aitken(1, 1, 1), fmt_real)
    call print_field('  so4_accum', env%so4_accum(1, 1, 1), fmt_real)
    call print_field('  soot_fresh', env%soot_fresh(1, 1, 1), fmt_real)
    call print_field('  soot_aged', env%soot_aged(1, 1, 1), fmt_real)
    call print_field('  ocff_fresh', env%ocff_fresh(1, 1, 1), fmt_real)
    call print_field('  ocff_aged', env%ocff_aged(1, 1, 1), fmt_real)
    call print_field('  biogenic', env%biogenic(1, 1, 1), fmt_real)
    call print_field('  sea_salt_film', env%sea_salt_film(1, 1, 1), fmt_real)
    call print_field('  sea_salt_jet', env%sea_salt_jet(1, 1, 1), fmt_real)
    call print_field('  rim_cry', env%rim_cry(1, 1, 1), fmt_real)
    call print_field('  rim_agg', env%rim_agg(1, 1, 1), fmt_real)
    call print_field('  vertvel', env%vertvel(1, 1, 1), fmt_real)
    call print_field('  bl_tke', env%bl_tke(1, 1, 1), fmt_real)
    call umPrint('', src=routine_name)

    ! Print offline chemistry namelist variables
    call umPrint('Offline Chemistry Environment:', src=routine_name)
    call print_field('  h2o2_offline', env%h2o2_offline(1, 1, 1), fmt_real)
    call print_field('  ho2_offline', env%ho2_offline(1, 1, 1), fmt_real)
    call print_field('  no3_offline', env%no3_offline(1, 1, 1), fmt_real)
    call print_field('  o3_offline', env%o3_offline(1, 1, 1), fmt_real)
    call print_field('  oh_offline', env%oh_offline(1, 1, 1), fmt_real)
    call umPrint('', src=routine_name)

  endsubroutine print_box_environment

  subroutine print_field_real(label, value, fmt)

    !! Print a labelled real value, with missing data shown as NaN

    !> The label to print before the value
    character(len=*), intent(in) :: label
    !> The format to print the label and value with
    character(len=*), intent(in) :: fmt
    !> The value to print
    real, intent(in) :: value

    write(umMessage, fmt) label, real_or_nan(value)
    call umPrint(umMessage, src=mod_name)

  endsubroutine print_field_real

  subroutine print_field_int(label, value, fmt)

    !! Print a labelled integer value, with missing data shown as NaN

    !> The label to print before the value
    character(len=*), intent(in) :: label
    !> The format to print the label and value with
    character(len=*), intent(in) :: fmt
    !> The value to print
    integer, intent(in) :: value

    write(umMessage, fmt) label, int_or_nan(value)
    call umPrint(umMessage, src=mod_name)

  endsubroutine print_field_int

  subroutine print_field_logical(label, value, fmt)

    !! Print a labelled logical value

    !> The label to print before the value
    character(len=*), intent(in) :: label
    !> The format to print the label and value with
    character(len=*), intent(in) :: fmt
    !> The value to print
    logical, intent(in) :: value

    write(umMessage, fmt) label, value
    call umPrint(umMessage, src=mod_name)

  endsubroutine print_field_logical

  subroutine print_ukca_environment

    !! Print the environment fields UKCA requires, as held inside UKCA, and
    !! warn about any required field that has not been set.

    use ukca_api_mod, only: ukca_get_environment_varlist, &
                            ukca_maxlen_fieldname, &
                            ukca_maxlen_message, ukca_maxlen_procname
    use ukca_environment_fields_mod, only: environ_field_ptrs, &
                                           environ_field_info
    use box_err_codes_mod, only: box_errcode_env_count, box_errcode_env_type

    !> Names of the environment fields UKCA requires
    character(len=ukca_maxlen_fieldname), pointer :: varnames_ptrs(:)
    !> Error code for error reporting
    integer :: err_code
    !> Error message for error reporting
    character(len=ukca_maxlen_message) :: error_message
    !> Routine name for error reporting
    character(len=ukca_maxlen_procname) :: error_routine
    !> The label printed before each field's value
    character(len=256) :: print_label
    !> Loop index over the fields
    integer :: i
    !> Loop index over the last dimension of a 4D field
    integer :: j
    !> Column at which values start, after the field label
    integer, parameter :: label_width = 45

    !> Formats for integer, real, scientific and logical values
    character(len=80) :: fmt_int, fmt_real, fmt_sci, fmt_log

    ! Create format strings with dynamic field widths
    fmt_int = '(A, T'//int_to_string(label_width)//', F0.0)'
    fmt_real = '(A, T'//int_to_string(label_width)//', G0.5)'
    fmt_sci = '(A, T'//int_to_string(label_width)//', ES11.4)'
    fmt_log = '(A, T'//int_to_string(label_width)//', L1)'

    call ukca_get_environment_varlist(varnames_ptrs, err_code, &
                                      error_message, error_routine)

    if(err_code /= 0) then
      call ereport(error_routine, err_code, error_message)
    endif

    error_routine = mod_name//":print_ukca_environment"

    if(size(varnames_ptrs) /= size(environ_field_ptrs)) then
      write(error_message, "(A)") "Mismatch between number of environment "// &
        "variables and field pointers"
      err_code = box_errcode_env_count
      call ereport(error_routine, err_code, error_message)
    endif

    if(size(varnames_ptrs) /= size(environ_field_info)) then
      write(error_message, "(A)") "Mismatch between number of environment "// &
        "variables and field info entries"
      err_code = box_errcode_env_count
      call ereport(error_routine, err_code, error_message)
    endif

    call umPrint('UKCA Environment:', src=error_routine)
    ! loop over the variable names, print their values
    do i = 1, size(varnames_ptrs)
      select case(environ_field_info(i)%group)
        ! scalar real
      case(1)
        if(associated(environ_field_ptrs(i)%value_0d_real)) then
          print_label = "  "//trim(varnames_ptrs(i))
          call print_field(print_label, &
                           environ_field_ptrs(i)%value_0d_real, fmt_real)
        else
          call report_unassociated_variable(varnames_ptrs(i))
        endif
        ! 2D integer
      case(2)
        if(associated(environ_field_ptrs(i)%value_2d_integer)) then
          print_label = "  "//trim(varnames_ptrs(i))//"(1,1)"
          call print_field(print_label, &
                           environ_field_ptrs(i)%value_2d_integer( &
                           1, 1), fmt_int)
        else
          call report_unassociated_variable(varnames_ptrs(i))
        endif
        ! 2D real
      case(3, 12, 14)
        if(associated(environ_field_ptrs(i)%value_2d_real)) then
          print_label = "  "//trim(varnames_ptrs(i))//"(1,1)"
          call print_field(print_label, &
                           environ_field_ptrs(i)%value_2d_real(1, 1), fmt_real)
        else
          call report_unassociated_variable(varnames_ptrs(i))
        endif
        ! 2D logical
      case(4, 13)
        if(associated(environ_field_ptrs(i)%value_2d_logical)) then
          print_label = "  "//trim(varnames_ptrs(i))//"(1,1)"
          call print_field(print_label, &
                           environ_field_ptrs(i)%value_2d_logical( &
                           1, 1), fmt_log)
        else
          call report_unassociated_variable(varnames_ptrs(i))
        endif
        ! 3D real
      case(5, 6, 7, 8, 9, 10)
        if(associated(environ_field_ptrs(i)%value_3d_real)) then
          print_label = "  "//trim(varnames_ptrs(i))//"(1,1,1)"
          call print_field(print_label, &
                           environ_field_ptrs(i)%value_3d_real( &
                           1, 1, 1), fmt_real)
        else
          call report_unassociated_variable(varnames_ptrs(i))
        endif
        ! 1D real
      case(11)
        if(associated(environ_field_ptrs(i)%value_1d_real)) then
          print_label = "  "//trim(varnames_ptrs(i))//"(1)"
          call print_field(print_label, &
                           environ_field_ptrs(i)%value_1d_real(1), fmt_real)
        else
          call report_unassociated_variable(varnames_ptrs(i))
        endif
        ! 4D real
      case(15)
        if(associated(environ_field_ptrs(i)%value_4d_real)) then
          ! one line per value of the last dimension, e.g. per photolysis rate
          do j = 1, size(environ_field_ptrs(i)%value_4d_real, 4)
            print_label = "  "//trim(varnames_ptrs(i))//"(1,1,1,"// &
                          int_to_string(j)//")"
            call print_field(print_label, &
                             environ_field_ptrs(i)%value_4d_real(1, 1, 1, j), &
                             fmt_real)
          enddo
        else
          call report_unassociated_variable(varnames_ptrs(i))
        endif

      case default
        write(error_message, "(2A)") "Unknown environment variable group "// &
          "for variable ", trim(varnames_ptrs(i))
        err_code = box_errcode_env_type
        call ereport(error_routine, err_code, error_message)

      endselect

    enddo

  contains

    subroutine report_unassociated_variable(varname)

      !! Print and warn that a required environment field is not set

      use box_err_codes_mod, only: box_errcode_env_not_assoc

      !> Name of the field that is not set
      character(len=*), intent(in) :: varname
      !> Warning message
      character(len=ukca_maxlen_message) :: msg

      write(msg, "(3A)") trim(varname), " is not associated", &
        " yet is required for the box model run."
      err_code = -box_errcode_env_not_assoc
      call ereport(error_routine, err_code, msg)

    endsubroutine report_unassociated_variable

  endsubroutine print_ukca_environment

  subroutine set_box_environment(env)

    !! Set the internal ukca environment using the box environment data
    !! structure. The internal ukca environment will be what the ukca model
    !! uses when solving chemistry.

    use ukca_api_mod, only: ukca_set_environment
    use box_debug_mod, only: is_debug_level

    !> the box environment, containing both fields from the input namelist
    !> and derived fields.
    type(box_environment_type), intent(in) :: env

    interface set_field
      procedure set_field_0d_real
      procedure set_field_1d_real
      procedure set_field_2d_real
      procedure set_field_2d_int
      procedure set_field_2d_log
      procedure set_field_3d_real
      procedure set_field_4d_real
    endinterface set_field

    ! set scalar fields
    call set_field("sin_declination", env%sin_declination)
    call set_field("equation_of_time", env%equation_of_time)
    call set_field("atmospheric_ch4", env%atmospheric_ch4)
    call set_field("atmospheric_co2", env%atmospheric_co2)
    call set_field("atmospheric_h2", env%atmospheric_h2)
    call set_field("atmospheric_n2", env%atmospheric_n2)
    call set_field("atmospheric_o2", env%atmospheric_o2)
    call set_field("atmospheric_n2o", env%atmospheric_n2o)
    call set_field("atmospheric_cfc11", env%atmospheric_cfc11)
    call set_field("atmospheric_cfc12", env%atmospheric_cfc12)
    call set_field("atmospheric_cfc113", env%atmospheric_cfc113)
    call set_field("atmospheric_hcfc22", env%atmospheric_hcfc22)
    call set_field("atmospheric_hfc125", env%atmospheric_hfc125)
    call set_field("atmospheric_hfc134a", env%atmospheric_hfc134a)
    call set_field("atmospheric_mebr", env%atmospheric_mebr)
    call set_field("atmospheric_mecl", env%atmospheric_mecl)
    call set_field("atmospheric_ch2br2", env%atmospheric_ch2br2)
    call set_field("atmospheric_chbr3", env%atmospheric_chbr3)
    call set_field("atmospheric_cfc114", env%atmospheric_cfc114)
    call set_field("atmospheric_cfc115", env%atmospheric_cfc115)
    call set_field("atmospheric_ccl4", env%atmospheric_ccl4)
    call set_field("atmospheric_meccl3", env%atmospheric_meccl3)
    call set_field("atmospheric_hcfc141b", env%atmospheric_hcfc141b)
    call set_field("atmospheric_hcfc142b", env%atmospheric_hcfc142b)
    call set_field("atmospheric_h1211", env%atmospheric_h1211)
    call set_field("atmospheric_h1202", env%atmospheric_h1202)
    call set_field("atmospheric_h1301", env%atmospheric_h1301)
    call set_field("atmospheric_h2402", env%atmospheric_h2402)
    call set_field("atmospheric_cos", env%atmospheric_cos)

    ! set 1D real fields
    call set_field("soil_moisture_layer1", env%soil_moisture_layer1)
    call set_field("fland", env%fland)
    call set_field("ibvoc_isoprene", env%ibvoc_isoprene)
    call set_field("ibvoc_terpene", env%ibvoc_terpene)
    call set_field("ibvoc_methanol", env%ibvoc_methanol)
    call set_field("ibvoc_acetone", env%ibvoc_acetone)
    call set_field("inferno_bc", env%inferno_bc)
    call set_field("inferno_ch4", env%inferno_ch4)
    call set_field("inferno_co", env%inferno_co)
    call set_field("inferno_nox", env%inferno_nox)
    call set_field("inferno_oc", env%inferno_oc)
    call set_field("inferno_so2", env%inferno_so2)
    call set_field("inferno_c2h4", env%inferno_c2h4)
    call set_field("inferno_c2h6", env%inferno_c2h6)
    call set_field("inferno_c3h8", env%inferno_c3h8)
    call set_field("inferno_hcho", env%inferno_hcho)
    call set_field("inferno_mecho", env%inferno_mecho)
    call set_field("inferno_nh3", env%inferno_nh3)
    call set_field("inferno_dms", env%inferno_dms)

    ! set 2D real fields
    call set_field("latitude", env%latitude)
    call set_field("longitude", env%longitude)
    call set_field("sin_latitude", env%sin_latitude)
    call set_field("cos_latitude", env%cos_latitude)
    call set_field("tan_latitude", env%tan_latitude)
    call set_field("conv_cloud_lwp", env%conv_cloud_lwp)
    call set_field("tstar", env%tstar)
    call set_field("zbl", env%zbl)
    call set_field("rough_length", env%rough_length)
    call set_field("seaice_frac", env%seaice_frac)
    call set_field("frac_types", env%frac_types)
    call set_field("laift_lp", env%laift_lp)
    call set_field("canhtft_lp", env%canhtft_lp)
    call set_field("tstar_tile", env%tstar_tile)
    call set_field("z0tile_lp", env%z0tile_lp)
    call set_field("pstar", env%pstar)
    call set_field("surf_albedo", env%surf_albedo)
    call set_field("zhsc", env%zhsc)
    call set_field("u_scalar_10m", env%u_scalar_10m)
    call set_field("surf_hf", env%surf_hf)
    call set_field("u_s", env%u_s)
    call set_field("ch4_wetl_emiss", env%ch4_wetl_emiss)
    call set_field("dms_sea_conc", env%dms_sea_conc)
    call set_field("chloro_sea", env%chloro_sea)
    call set_field("dust_flux_div1", env%dust_flux_div1)
    call set_field("dust_flux_div2", env%dust_flux_div2)
    call set_field("dust_flux_div3", env%dust_flux_div3)
    call set_field("dust_flux_div4", env%dust_flux_div4)
    call set_field("dust_flux_div5", env%dust_flux_div5)
    call set_field("dust_flux_div6", env%dust_flux_div6)
    call set_field("surf_wetness", env%surf_wetness)
    call set_field("grid_surf_area", env%grid_surf_area)
    call set_field("ext_cg_flash", env%ext_cg_flash)
    call set_field("ext_ic_flash", env%ext_ic_flash)

    ! set 2D integer fields
    call set_field("kent", env%kent)
    call set_field("kent_dsc", env%kent_dsc)
    call set_field("conv_cloud_base", env%conv_cloud_base)
    call set_field("conv_cloud_top", env%conv_cloud_top)
    call set_field("lscat_zhang", env%lscat_zhang)

    ! set 2D logical fields
    call set_field("land_sea_mask", env%land_sea_mask)
    call set_field("l_tile_active", env%l_tile_active)

    ! set 3D real fields
    call set_field("u_rho_levels", env%u_rho_levels)
    call set_field("v_rho_levels", env%v_rho_levels)
    call set_field("geopH_on_theta_mlevs", env%geopH_on_theta_mlevs)
    call set_field("theta", env%theta)
    call set_field("q", env%q)
    call set_field("qcf", env%qcf)
    call set_field("conv_cloud_amount", env%conv_cloud_amount)
    call set_field("rho_r2", env%rho_r2)
    call set_field("qcl", env%qcl)
    call set_field("exner_rho_levels", env%exner_rho_levels)
    call set_field("area_cloud_fraction", env%area_cloud_fraction)
    call set_field("cloud_frac", env%cloud_frac)
    call set_field("cloud_liq_frac", env%cloud_liq_frac)
    call set_field("exner_theta_levels", env%exner_theta_levels)
    ! ! TODO - not sure what to do with fields that can be set via API
    ! call set_field("p_layer_boundaries", env%p_layer_boundaries)
    call set_field("p_theta_levels", env%p_theta_levels)
    call set_field("rhokh_rdz", env%rhokh_rdz)
    call set_field("dtrdz", env%dtrdz)
    call set_field("we_lim", env%we_lim)
    call set_field("t_frac", env%t_frac)
    call set_field("zrzi", env%zrzi)
    call set_field("we_lim_dsc", env%we_lim_dsc)
    call set_field("t_frac_dsc", env%t_frac_dsc)
    call set_field("zrzi_dsc", env%zrzi_dsc)
    call set_field("stcon", env%stcon)
    call set_field("ls_rain3d", env%ls_rain3d)
    call set_field("ls_snow3d", env%ls_snow3d)
    call set_field("autoconv", env%autoconv)
    call set_field("accretion", env%accretion)
    call set_field("pv_on_theta_mlevs", env%pv_on_theta_mlevs)
    call set_field("conv_rain3d", env%conv_rain3d)
    call set_field("conv_snow3d", env%conv_snow3d)
    call set_field("so4_sa_clim", env%so4_sa_clim)
    call set_field("so4_aitken", env%so4_aitken)
    call set_field("so4_accum", env%so4_accum)
    call set_field("soot_fresh", env%soot_fresh)
    call set_field("soot_aged", env%soot_aged)
    call set_field("ocff_fresh", env%ocff_fresh)
    call set_field("ocff_aged", env%ocff_aged)
    call set_field("biogenic", env%biogenic)
    call set_field("dust_div1", env%dust_div1)
    call set_field("dust_div2", env%dust_div2)
    call set_field("dust_div3", env%dust_div3)
    call set_field("dust_div4", env%dust_div4)
    call set_field("dust_div5", env%dust_div5)
    call set_field("dust_div6", env%dust_div6)
    call set_field("sea_salt_film", env%sea_salt_film)
    call set_field("sea_salt_jet", env%sea_salt_jet)
    call set_field("CO2", env%co2_interactive)
    call set_field("rim_cry", env%rim_cry)
    call set_field("rim_agg", env%rim_agg)
    call set_field("vertvel", env%vertvel)
    call set_field("bl_tke", env%bl_tke)
    call set_field("interf_z", env%interf_z)
    call set_field("grid_area_fullht", env%grid_area_fullht)
    call set_field("grid_volume", env%grid_volume)
    call set_field("grid_airmass", env%grid_airmass)
    call set_field("rel_humid_frac", env%rel_humid_frac)
    call set_field("rel_humid_frac_clr", env%rel_humid_frac_clr)
    call set_field("qsvp", env%qsvp)
    call set_field("H2O2", env%h2o2_offline)
    call set_field("HO2", env%ho2_offline)
    call set_field("NO3", env%no3_offline)
    call set_field("O3", env%o3_offline)
    call set_field("OH", env%oh_offline)
    call set_field("p_rho_levels", env%p_rho_levels)

    ! set 4D real fields
    call set_field("photol_rates", env%photol_rates)

  contains

    subroutine set_field_0d_real(field_name, field_value)

      !! Set a real scalar field in the UKCA environment

      !> Name of the UKCA environment field
      character(len=*), intent(in) :: field_name
      !> Value to set the field to
      real, intent(in) :: field_value
      !> Error code returned by ukca_set_environment
      integer :: ecode
      !> Error message returned by ukca_set_environment
      character(len=256) :: errmsg

      ecode = 0

      if(is_debug_level(1)) then
        call umPrint("DEBUG: Setting "//trim(field_name)//" to "// &
                     real_to_string(real_or_nan(field_value)), &
                     src="set_box_environment")
      endif

      call ukca_set_environment(field_name, field_value, ecode, &
                                error_message=errmsg)
      call handle_set_error(field_name, ecode, errmsg)

    endsubroutine set_field_0d_real

    subroutine set_field_1d_real(field_name, field_value)

      !! Set a 1D real field in the UKCA environment

      !> Name of the UKCA environment field
      character(len=*), intent(in) :: field_name
      !> Value to set the field to
      real, allocatable, intent(in) :: field_value(:)
      !> Error code returned by ukca_set_environment
      integer :: ecode
      !> Error message returned by ukca_set_environment
      character(len=256) :: errmsg

      ecode = 0

      if(is_debug_level(1)) then
        call umPrint("DEBUG: Setting "//trim(field_name)//" to "// &
                     real_to_string(real_or_nan(field_value(1))), &
                     src="set_box_environment")
      endif

      call ukca_set_environment(field_name, field_value, ecode, &
                                error_message=errmsg)
      call handle_set_error(field_name, ecode, errmsg)

    endsubroutine set_field_1d_real

    subroutine set_field_2d_real(field_name, field_value)

      !! Set a 2D real field in the UKCA environment

      !> Name of the UKCA environment field
      character(len=*), intent(in) :: field_name
      !> Value to set the field to
      real, allocatable, intent(in) :: field_value(:, :)
      !> Error code returned by ukca_set_environment
      integer :: ecode
      !> Error message returned by ukca_set_environment
      character(len=256) :: errmsg

      ecode = 0

      if(is_debug_level(1)) then
        call umPrint("DEBUG: Setting "//trim(field_name)//" to "// &
                     real_to_string(real_or_nan(field_value(1, 1))), &
                     src="set_box_environment")
      endif

      call ukca_set_environment(field_name, field_value, ecode, &
                                error_message=errmsg)
      call handle_set_error(field_name, ecode, errmsg)

    endsubroutine set_field_2d_real

    subroutine set_field_2d_int(field_name, field_value)

      !! Set a 2D integer field in the UKCA environment

      !> Name of the UKCA environment field
      character(len=*), intent(in) :: field_name
      !> Value to set the field to
      integer, allocatable, intent(in) :: field_value(:, :)
      !> Error code returned by ukca_set_environment
      integer :: ecode
      !> Error message returned by ukca_set_environment
      character(len=256) :: errmsg

      ecode = 0

      if(is_debug_level(1)) then
        call umPrint("DEBUG: Setting "//trim(field_name)//" to "// &
                     real_to_string(int_or_nan(field_value(1, 1))), &
                     src="set_box_environment")
      endif

      call ukca_set_environment(field_name, field_value, ecode, &
                                error_message=errmsg)
      call handle_set_error(field_name, ecode, errmsg)

    endsubroutine set_field_2d_int

    subroutine set_field_2d_log(field_name, field_value)

      !! Set a 2D logical field in the UKCA environment

      !> Name of the UKCA environment field
      character(len=*), intent(in) :: field_name
      !> Value to set the field to
      logical, allocatable, intent(in) :: field_value(:, :)
      !> Error code returned by ukca_set_environment
      integer :: ecode
      !> Error message returned by ukca_set_environment
      character(len=256) :: errmsg

      ecode = 0

      if(is_debug_level(1)) then
        call umPrint("DEBUG: Setting "// &
                     trim(field_name)//" to "// &
                     log_to_string(field_value(1, &
                                               1)), src="set_box_environment")
      endif

      call ukca_set_environment(field_name, field_value, ecode, &
                                error_message=errmsg)
      call handle_set_error(field_name, ecode, errmsg)

    endsubroutine set_field_2d_log

    subroutine set_field_3d_real(field_name, field_value)

      !! Set a 3D real field in the UKCA environment

      !> Name of the UKCA environment field
      character(len=*), intent(in) :: field_name
      !> Value to set the field to
      real, allocatable, intent(in) :: field_value(:, :, :)
      !> Error code returned by ukca_set_environment
      integer :: ecode
      !> Error message returned by ukca_set_environment
      character(len=256) :: errmsg

      ecode = 0

      if(is_debug_level(1)) then
        call umPrint("DEBUG: Setting "//trim(field_name)//" to "// &
                     real_to_string(real_or_nan(field_value(1, 1, 1))), &
                     src="set_box_environment")
      endif

      call ukca_set_environment(field_name, field_value, ecode, &
                                error_message=errmsg)
      call handle_set_error(field_name, ecode, errmsg)

    endsubroutine set_field_3d_real

    subroutine set_field_4d_real(field_name, field_value)

      !! Set a 4D real field in the UKCA environment

      !> Name of the UKCA environment field
      character(len=*), intent(in) :: field_name
      !> Value to set the field to
      real, allocatable, intent(in) :: field_value(:, :, :, :)
      !> Error code returned by ukca_set_environment
      integer :: ecode
      !> Error message returned by ukca_set_environment
      character(len=256) :: errmsg

      ecode = 0

      if(is_debug_level(1)) then
        call umPrint("DEBUG: Setting "//trim(field_name)//" to "// &
                     real_to_string(real_or_nan(field_value(1, 1, 1, 1))), &
                     src="set_box_environment")
      endif

      call ukca_set_environment(field_name, field_value, ecode, &
                                error_message=errmsg)
      call handle_set_error(field_name, ecode, errmsg)

    endsubroutine set_field_4d_real

    subroutine handle_set_error(field_name, ecode, errmsg)

      !! Stop with an error if setting a UKCA environment field failed

      !> Name of the UKCA environment field
      character(len=*), intent(in) :: field_name
      !> Error code returned by ukca_set_environment
      integer, intent(in) :: ecode
      !> Error message returned by ukca_set_environment
      character(len=*), intent(in) :: errmsg
      !> Copy of ecode, as ereport may change its error code argument
      integer :: report_code
      !> Message for error reporting
      character(len=ukca_maxlen_message) :: err_msg

      if(ecode /= 0) then
        report_code = ecode
        write(err_msg, "(4A)") "Error setting ", trim(field_name), &
          " in ukca environment: ", trim(errmsg)
        call ereport('set_box_environment', report_code, err_msg)
      endif
    endsubroutine handle_set_error

  endsubroutine set_box_environment

  subroutine derive_env_variables(env)

    !! Derive environment variables from the input box environment fields, and
    !! store the results in the same environment type.

    !! Example derived field: altitude is derived from the surface pressure and
    !! a theta level pressure, using the hypsometric equation.

    use box_const_mod, only: sclht, earth_radius, row_length, rows, &
                             model_levels, earth_pref, kappa, &
                             const_pi_over_180, c_virtual, earth_r
    use box_err_codes_mod, only: box_errcode_non_phys_calc, &
                                 box_errcode_env_namelist
    use box_debug_mod, only: is_debug_level

    !> the box model environment from which fields will be derived and set in
    type(box_environment_type), intent(inout) :: env

    !> altitude
    real :: alt
    !> height of theta levels
    real, allocatable ::  r_theta_levels(:, :, :)
    !> height of rho levels
    real, allocatable ::  r_rho_levels(:, :, :)
    !> pressure at rho levels
    real, allocatable :: p_rho_levels(:, :, :)
    !> eta of theta levels
    real, allocatable :: eta_theta_levels(:)
    !> dimensionless_exner_function [CF] at theta levels {UM:00406}
    real, allocatable :: exner_theta_levels(:, :, :)
    !> dimensionless exner function at rho levels
    real, allocatable :: exner_rho_levels(:, :, :)
    !> air_potential_temperature [CF] (K) {UM:00004}
    real, allocatable :: theta(:, :, :)
    !> denomTv = ( 1 + ( Rv/Rd - 1 ) q ) T
    real :: theta_v
    !> density
    real, allocatable :: rho(:, :, :)
    !> density, r2
    real, allocatable :: rho_r2(:, :, :)
    !> surface area
    real, allocatable :: surf_area(:, :)
    !> dummy ratio for checking
    real :: ratio
    !> error reporting message
    character(len=256) :: err_msg
    !> error code
    integer :: err_code
    !> minimum debug level for printing messages
    integer, parameter :: minimum_debug = 1

    ! allocate arrays of derived fields
    allocate(r_theta_levels(row_length, rows, 0:model_levels))
    allocate(eta_theta_levels(0:model_levels))
    allocate(r_rho_levels(row_length, rows, 1:model_levels))
    allocate(exner_theta_levels(row_length, rows, model_levels))
    ! UKCA expects exner_rho_levels on model_levels + 1 levels
    allocate(exner_rho_levels(row_length, rows, model_levels + 1))
    allocate(theta(row_length, rows, model_levels))
    allocate(rho(row_length, rows, model_levels))
    allocate(rho_r2(row_length, rows, model_levels))
    allocate(surf_area(row_length, rows))
    allocate(p_rho_levels(row_length, rows, model_levels))

    ! print out p_theta_levels and pstar for debugging
    if(is_debug_level(minimum_debug)) then
      call umPrint("DEBUG: p_theta_levels(1,1,1): "// &
                   real_to_string(env%p_theta_levels(1, 1, 1)), &
                   src="derive_env_variables")
      call umPrint("DEBUG: pstar(1,1): "// &
                   real_to_string(env%pstar(1, 1)), src="derive_env_variables")
    endif

    ! both pressures are needed, and if both were missing (rmdi) their ratio
    ! would be 1 and pass the check below
    if(is_missing(env%pstar(1, 1)) .or. &
       is_missing(env%p_theta_levels(1, 1, 1))) then
      write(err_msg, "(A)") "pstar and p_theta_levels must both be set in "// &
        "the environment namelist, to derive the altitude and other fields."
      err_code = box_errcode_env_namelist
      call ereport('derive_env_variables', err_code, err_msg)
    endif

    ratio = env%p_theta_levels(1, 1, 1) / env%pstar(1, 1)
    if(ratio <= 0.) then

      write(err_msg, "(A)") "Surface pressure and a theta pressure has "// &
        "resulted in a non-positive ratio, which is non-physical."
      err_code = box_errcode_non_phys_calc
      call ereport('derive_env_variables', err_code, err_msg)
    endif

    ! derive altitude
    alt = -sclht * log(env%p_theta_levels(1, 1, 1) / env%pstar(1, 1))

    if(is_debug_level(minimum_debug)) then
      call umPrint("DEBUG: alt: "//real_to_string(alt), &
                   src="derive_env_variables")
    endif

    r_theta_levels(1, 1, 1) = alt + earth_radius
    ! TODO - check if this is correct
    r_theta_levels(1, 1, 0) = earth_radius
    ! hack, for box model theta and rho level are the same
    r_rho_levels = r_theta_levels(1, 1, 1)
    p_rho_levels(1, 1, :) = env%p_theta_levels(1, 1, 1)

    ! add to env type
    env%r_rho_levels = r_rho_levels
    env%r_theta_levels = r_theta_levels
    env%p_rho_levels = p_rho_levels

    ! eta
    eta_theta_levels(0) = 0.
    eta_theta_levels(1) = 1.

    ! add eta levels to env
    env%eta_theta_levels = eta_theta_levels

    ! exner function
    exner_theta_levels(1, 1, 1) = (env%p_theta_levels(1, 1, 1) / &
                                   earth_pref)**kappa
    exner_rho_levels = exner_theta_levels(1, 1, 1)

    env%exner_theta_levels = exner_theta_levels
    env%exner_rho_levels = exner_rho_levels

    ! Calculate theta from T, p and exner:
    theta(1, 1, 1) = env%t_theta_levels(1, 1, 1) / exner_theta_levels(1, 1, 1)
    if(is_debug_level(minimum_debug)) then
      call umPrint("DEBUG: theta(1,1,1): "//real_to_string(theta(1, 1, 1)), &
                   src="derive_env_variables")
    endif
    env%theta = theta

    ! density calc - see calc_rho in um
    theta_v = theta(1, 1, &
                    1) * (1.0 + c_virtual * &
                          (env%q(1, 1, 1) + env%qcl(1, &
                                                    1, 1) + env%qcf(1, 1, 1)))
    rho = p_rho_levels(1, 1, &
                       1) / (earth_r * theta_v * exner_rho_levels(1, 1, 1))

    ! debug - print shape of rho and r_rho_levels
    if(is_debug_level(minimum_debug)) then
      call umPrint("DEBUG: rho shape: "// &
                   int_to_string(size(rho, 1))//", "// &
                   int_to_string(size(rho, 2))//", "// &
                   int_to_string(size(rho, 3)), src="derive_env_variables")
      call umPrint("DEBUG: r_rho_levels shape: "// &
                   int_to_string(size(r_rho_levels, 1))//", "// &
                   int_to_string(size(r_rho_levels, 2))//", "// &
                   int_to_string(size(r_rho_levels, 3)), &
                   src="derive_env_variables")
    endif

    !rho_r2(1,1,:) = rho * r_rho_levels(1,1,:) * r_rho_levels(1,1,:)

    ! trig function of latitude
    env%true_latitude = env%latitude * const_pi_over_180
    env%true_longitude = env%longitude * const_pi_over_180
    env%sin_latitude = sin(env%true_latitude)
    env%cos_latitude = cos(env%true_latitude)
    ! BIT-FOR-BIT: the old (UM) box model computes SIN/COS (box_ukca_mod),
    ! which differs from TAN in the last bits. Revert to TAN once
    ! equivalence is proven. See the bit-for-bit register in the notes.
    env%tan_latitude = sin(env%true_latitude) / cos(env%true_latitude)

    ! tile surface temperatures default to the gridbox surface temperature,
    ! as in the old box model
    if(all(is_missing(env%tstar_tile))) then
      env%tstar_tile = env%tstar(1, 1)
    endif

    ! TODO - need to add a check to see if we have inputs to actual derive all
    ! the variables in this subroutine

    ! TODO - surf area calc

  endsubroutine derive_env_variables

  subroutine update_env_from_tracers(env_entry, tracer_ukca, tracer_name)

    !! Subroutine for updating a box environment entry with the
    !! a current value from the tracer array.

    use box_tracer_mod, only: find_species_index
    use box_err_codes_mod, only: box_errcode_tracer_not_found

    !> The box environment field to update
    real, intent(inout) :: env_entry(:, :, :)
    !> The UKCA tracer array
    real, intent(in) :: tracer_ukca(:, :, :, :)
    !> Name of the tracer to copy into the environment field
    character(len=*), intent(in) :: tracer_name
    !> Routine name for logging
    character(len=*), parameter :: routine_name = "update_env_from_tracers"

    !> Whether the tracer was found in the tracer list
    logical :: found
    !> Index of the tracer in the tracer array
    integer :: tracer_index
    !> Error code for error reporting
    integer :: err_code
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: err_msg

    call find_species_index(tracer_name, tracer_index, found)

    if(found) then
      env_entry(:, :, :) = tracer_ukca(:, :, :, tracer_index)
    else
      err_code = box_errcode_tracer_not_found
      write(err_msg, "(2A)") trim(tracer_name), " not found in tracer "// &
        "variable list. Unable to update box environment with ukca_step value."
      call ereport(mod_name//":"//routine_name, err_code, err_msg)
    endif

  endsubroutine update_env_from_tracers

  subroutine update_tracer_from_env(tracer_ukca, env_entry, tracer_name)

    !! Copy a box environment entry into the matching tracer, so that the
    !! environment stays the master copy of that field (e.g. q into H2O, as
    !! the UM does). Does nothing if the species is not a tracer in this
    !! chemistry scheme.

    use box_tracer_mod, only: find_species_index

    !> The UKCA tracer array
    real, intent(inout) :: tracer_ukca(:, :, :, :)
    !> The box environment entry to copy into the tracer
    real, intent(in) :: env_entry(:, :, :)
    !> Name of the tracer to update
    character(len=*), intent(in) :: tracer_name

    !> Whether the tracer was found in the tracer list
    logical :: found
    !> Index of the tracer in the tracer array
    integer :: tracer_index

    call find_species_index(tracer_name, tracer_index, found)

    if(found) then
      tracer_ukca(:, :, :, tracer_index) = env_entry(:, :, :)
    endif

  endsubroutine update_tracer_from_env

  elemental function is_missing(value) result(missing)

    !! Check whether a real value is the missing data value (rmdi)

    !> The value to check
    real, intent(in) :: value
    !> True if the value is rmdi
    logical :: missing

    missing = abs(value - rmdi) < epsilon(value) * abs(rmdi)
  endfunction is_missing

  function real_or_nan(value) result(out)

    !! Return NaN if a real value is the missing data value (rmdi), so missing
    !! fields stand out when printed. Otherwise return the value.

    !> The value to check
    real, intent(in) :: value
    !> The value, or NaN if it is missing data
    real :: out

    if(is_missing(value)) then
      out = ieee_value(value, ieee_quiet_nan)
    else
      out = value
    endif
  endfunction real_or_nan

  function int_or_nan(value) result(out)

    !! Return NaN if an integer value is the missing data value (imdi), so
    !! missing fields stand out when printed. Otherwise return the value as a
    !! real.

    !> The value to check
    integer, intent(in) :: value
    !> The value as a real, or NaN if it is missing data
    real :: out

    if(value == imdi) then
      ! to produce a NaN
      out = ieee_value(real(value), ieee_quiet_nan)
    else
      out = real(value)
    endif
  endfunction int_or_nan

  function int_to_string(value) result(str)

    !! Convert an integer to a string, with no padding

    !> The integer to convert
    integer, intent(in) :: value
    !> The integer as a string
    character(len=:), allocatable :: str
    !> Buffer to write the integer into
    character(len=20) :: buffer

    write(buffer, '(I0)') value
    str = trim(buffer)
  endfunction int_to_string

  function real_to_string(value) result(str)

    !! Convert a real to a string for printing in debug messages

    !> The value to convert
    real, intent(in) :: value
    !> The value as a string
    character(len=32) :: str
    write(str, '(ES11.4)') value
    str = adjustl(str)
  endfunction real_to_string

  function log_to_string(value) result(str)

    !! Convert a logical to a string for printing in debug messages

    !> The value to convert
    logical, intent(in) :: value
    !> "True" or "False"
    character(len=5) :: str
    if(value) then
      str = 'True'
    else
      str = 'False'
    endif
  endfunction log_to_string

endmodule box_environment_mod
