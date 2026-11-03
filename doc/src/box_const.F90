module box_const_mod

  !! Module containing constants for the UKCA box model.

  use ukca_api_mod, only: ukca_strat_lbc_env
  use, intrinsic :: iso_c_binding, only: c_double

  implicit none

  public

  !> c iso binding of real 64 bit
  integer, parameter, private :: real64 = c_double

  !> dimension 1 - x
  integer, parameter :: row_length = 1
  !> dimension 2 - y
  integer, parameter :: rows = 1
  !> dimension 3 - z
  integer, parameter :: model_levels = 1
  !> No of boundary layer levels
  integer, parameter :: bl_levels = 1
  !> Number of grid levels for entrainment-related fields used by tr_mix
  integer, parameter :: nlev_ent_tr_mix = 3
  !> Number of land points
  integer, parameter :: land_points = 1

  !> use in photolysis - Number of CCA levels
  integer, parameter :: n_cca_lev = 0

  ! RW - TODO - this will be dependent on the equivalent logical - need to add
  ! validator

  !> The level at which to fix the tropopause height in the box model.
  integer, parameter :: fixed_tropopause_level = 1

  !> Grid points per segment for the column-based chemical solver
  integer, parameter :: ukca_chem_seg_size = 1
  !> Columns per segment for aerosol
  integer, parameter :: ukca_mode_seg_size = 1

  !> Number of levels above tropopause at which to start overwriting O3 and
  !> HNO3 with values derived from O3 data in troposphere only schemes
  integer, parameter :: nlev_above_trop_o3_env = 2
  !> Number of top levels at which to apply stratospheric CH4 loss rate in
  !> troposphere only schemes
  integer, parameter :: nlev_ch4_stratloss = 1

  !> Logical to fix the tropopause level in the box model.
  logical, parameter :: l_fix_tropopause_level = .true.
  !> STASH diagnostics always off in box model
  logical, parameter :: l_enable_diag_um = .false.
  !> If True no saving of horizontal arrays between timesteps
  logical, parameter :: l_ukca_persist_off = .false.
  !> No emissions currently in box model - True to turn off emissions
  logical, parameter :: l_ukca_emissions_off = .true.
  !> Box model doesn't pass to um but we set this to true anyway
  logical, parameter :: l_ukca_asad_columns = .true.
  ! TODO - change below to true when the co2_interactive issue is fixed in ukca
  !> Box model doesn't pass to um but we set this to true anyway
  logical, parameter :: l_ukca_asad_full = .false.
  !> True to explicitly enable marine DMS emissions - (deprecated redundant
  !> setting; if omitted from 'ukca_setup' call DMS emissions are enabled or
  !> disabled according to the value of 'i_ukca_dms_flux')
  logical, parameter :: l_ukca_enable_seadms_ems = .true.

  ! convenience constants
  !> mathematical pi
  real, parameter :: const_pi = 3.14159265358979323846
  !> mathematical pi divided by 180.0 degrees
  real, parameter :: const_pi_over_180 = const_pi / 180.0
  !> the reciprocal of mathematical pi divided by 180.0 degrees
  real, parameter :: const_recip_pi_over_180 = 180.0 / const_pi

  !> True if Convective Cloud Amount is calculated as a 3-D field, i.e. loop
  !> over n_cca_lev, else use only first level from cca array.
  logical, parameter :: l_3d_cca = .false.
  !> Use O2 + hv -> O(3P) + O(3P) photolysis rate from Socrates
  logical, parameter :: l_environ_jo2 = .false.
  !> Use O2 + hv -> O(1D) + O(3P) photolysis rate from Socrates
  logical, parameter :: l_environ_jo2b = .false.
  !> True if z_top_of_model is being supplied by parent model
  logical, parameter :: l_environ_z_top = .false.

  ! TODO - we should facilitate differing planet constants
  ! planet constants

  !> Mean scale height for pressure
  real, parameter :: sclht = 6.8e+03
  !> Gas constant for dry air
  real, parameter :: earth_r = 287.05
  !> Earth radius in metres
  real, parameter :: earth_radius = 6371229.0
  !> Specific heat of dry air at constant pressure
  real, parameter :: earth_cp = 1005.0
  !> Ratio of gas constant to specific heat
  real, parameter :: kappa = earth_r / earth_cp
  !> Reference surface pressure
  real, parameter :: earth_pref = 100000.0
  !> repsilon, ratio of molecular weights of water and dry air
  real, parameter :: earth_repsilon = 0.62198
  !> 1.0/repsilon-1.0
  real, parameter :: c_virtual = 1.0 / earth_repsilon - 1.0

  !> only ever use strat lbc from env (um scenario)
  integer, parameter :: i_strat_lbc_source = ukca_strat_lbc_env

  !> placeholder for JO2 rates from Radiation
  real, parameter :: rad_ctl_jo2(row_length, rows, model_levels) = 0.0
  !> placeholder for JO2B rates from Radiation
  real, parameter :: rad_ctl_jo2b(row_length, rows, model_levels) = 0.0
  !> hours in a day
  real(kind=real64), parameter :: rhour_per_day_const = 24.0_real64

endmodule box_const_mod
