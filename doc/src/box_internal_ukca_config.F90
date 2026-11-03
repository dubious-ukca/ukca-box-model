module box_internal_ukca_config_mod

  !! Module for setting up UKCA's internal configuration from the box config
  !! (setup_internal_ukca_config, which calls ukca_setup), and for storing
  !! internal ukca configuration options that are dependent on configuration
  !! choices, but also need to be made accessible by the box model.
  !!
  !! Note these values are only valid after ukca_setup() has been called, and
  !! the internal configuration been set up.
  !!
  !! This includes the number of photolytic reactions, which is needed by the
  !! box model to allocate arrays for photolysis rates.

  use ukca_missing_data_mod, only: imdi

  implicit none

  private

  public :: setup_internal_ukca_config
  public :: read_internal_ukca_config

  !> Number of dust emission size ranges
  integer, public, protected :: n_dust_emissions = imdi
  !> Number of photolytic reactions
  integer, public, protected :: jppj = imdi

  !> module name for error reporting
  character(len=*), parameter :: mod_name = &
                                 "box_internal_ukca_config_mod"

contains

  subroutine setup_internal_ukca_config(cfg)

    !! Set up UKCA's internal configuration by calling ukca_setup with the box
    !! config, the box model's fixed settings (box_const_mod) and the JULES
    !! surface type indices. setup_jules must be called first.

    use box_config_mod, only: box_config_type
    use box_const_mod, only: row_length, &
                             rows, model_levels, bl_levels, &
                             nlev_ent_tr_mix, ukca_chem_seg_size, &
                             ukca_mode_seg_size, l_fix_tropopause_level, &
                             l_enable_diag_um, l_ukca_persist_off, &
                             l_ukca_emissions_off, &
                             l_ukca_asad_columns, l_ukca_asad_full, &
                             i_strat_lbc_source, &
                             l_ukca_enable_seadms_ems, l_environ_z_top
    use photol_api_mod, only: photol_off, photol_strat_only, photol_2d, &
                              photol_fastjx
    use box_jules_mod, only: npft, i_brd_leaf, i_brd_leaf_dec, &
                             i_brd_leaf_eg_trop, i_brd_leaf_eg_temp, &
                             i_ndl_leaf, i_ndl_leaf_dec, &
                             i_ndl_leaf_eg, i_c3_grass, i_c3_crop, &
                             i_c3_pasture, i_c4_grass, &
                             i_c4_crop, i_c4_pasture, i_shrub, &
                             i_shrub_dec, i_shrub_eg, i_urban, &
                             i_lake, i_soil, i_ice, i_elev_ice
    use ukca_api_mod, only: ukca_setup, ukca_maxlen_message, &
                            ukca_maxlen_procname
    use ereport_mod, only: ereport

    !> The box model configuration
    type(box_config_type), intent(in) :: cfg
    !> Error code returned by ukca_setup
    integer :: err_code
    !> Error message returned by ukca_setup
    character(len=ukca_maxlen_message) :: error_message
    !> Routine reporting the error, returned by ukca_setup
    character(len=ukca_maxlen_procname) :: error_routine
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: err_msg

    err_code = 0

    call ukca_setup( &
      error_code=err_code, &
      row_length=row_length, &
      rows=rows, &
      model_levels=model_levels, &
      bl_levels=bl_levels, &
      nlev_ent_tr_mix=nlev_ent_tr_mix, &
      ntype=cfg%ntype, &
      npft=npft, &
      i_brd_leaf=i_brd_leaf, &
      i_brd_leaf_dec=i_brd_leaf_dec, &
      i_brd_leaf_eg_trop=i_brd_leaf_eg_trop, &
      i_brd_leaf_eg_temp=i_brd_leaf_eg_temp, &
      i_ndl_leaf=i_ndl_leaf, &
      i_ndl_leaf_dec=i_ndl_leaf_dec, &
      i_ndl_leaf_eg=i_ndl_leaf_eg, &
      i_c3_grass=i_c3_grass, &
      i_c3_crop=i_c3_crop, &
      i_c3_pasture=i_c3_pasture, &
      i_c4_grass=i_c4_grass, &
      i_c4_crop=i_c4_crop, &
      i_c4_pasture=i_c4_pasture, &
      i_shrub=i_shrub, &
      i_shrub_dec=i_shrub_dec, &
      i_shrub_eg=i_shrub_eg, &
      i_urban=i_urban, &
      i_lake=i_lake, &
      i_soil=i_soil, &
      i_ice=i_ice, &
      i_elev_ice=i_elev_ice, &
      i_ukca_chem=cfg%i_ukca_chem, &
      !fixed_tropopause_level=fixed_tropopause_level, &
      i_ageair_reset_method=cfg%i_ageair_reset_method, &
      max_ageair_reset_level=cfg%max_ageair_reset_level, &
      !i_error_method=cfg%i_error_method, &
      i_ukca_chem_version=cfg%i_ukca_chem_version, &
      nrsteps=cfg%nrsteps, &
      chem_timestep=cfg%chem_timestep, &
      dts0=cfg%dts0, &
      nit=cfg%nit, &
      i_ukca_quasinewton_start=cfg%i_ukca_quasinewton_start, &
      i_ukca_quasinewton_end=cfg%i_ukca_quasinewton_end, &
      ukca_chem_seg_size=ukca_chem_seg_size, &
      !nlev_above_trop_o3_env=nlev_above_trop_o3_env, &
      !nlev_ch4_stratloss=nlev_ch4_stratloss, &
      i_ukca_topboundary=cfg%i_ukca_topboundary, &
      i_ukca_hetconfig=cfg%i_ukca_hetconfig, &
      i_inferno_emi=cfg%i_inferno_emi, &
      i_ukca_dms_flux=cfg%i_ukca_dms_flux, &
      i_ukca_light_param=cfg%i_ukca_light_param, &
      i_strat_lbc_source=i_strat_lbc_source, &
      !i_primss_method=cfg%i_primss_method, &
      !env_log_step=cfg%env_log_step, &
      i_mode_nzts=cfg%i_mode_nzts, &
      ukca_mode_seg_size=ukca_mode_seg_size, &
      i_mode_setup=cfg%i_mode_setup, &
      i_mode_bln_param_method=cfg%i_mode_bln_param_method, &
      i_mode_nucscav=cfg%i_mode_nucscav, &
      i_ukca_activation_scheme=cfg%i_ukca_activation_scheme, &
      i_ukca_nwbins=cfg%i_ukca_nwbins, &
      i_ukca_tune_bc=cfg%i_ukca_tune_bc, &
      i_photol_scheme=cfg%i_photol_scheme, &
      i_photol_scheme_off=photol_off, &
      i_photol_scheme_strat_only=photol_strat_only, &
      i_photol_scheme_2d=photol_2d, &
      i_photol_scheme_fastjx=photol_fastjx, &
      dzsoil_layer1=cfg%dzsoil_layer1, &
      timestep=cfg%timestep, &
      max_ageair_reset_height=cfg%max_ageair_reset_height, &
      max_z_for_offline_chem=cfg%max_z_for_offline_chem, &
      soa_yield_scaling_mt=cfg%soa_yield_scaling_mt, &
      soa_yield_scaling_isop=cfg%soa_yield_scaling_isop, &
      !dry_depvel_so2_scaling=cfg%dry_depvel_so2_scaling, &
      !fastjx_prescutoff=cfg%fastjx_prescutoff, &
      mode_parfrac=cfg%mode_parfrac, &
      seadms_ems_scaling=cfg%seadms_ems_scaling, &
      sea_salt_ems_scaling=cfg%sea_salt_ems_scaling, &
      marine_pom_ems_scaling=cfg%marine_pom_ems_scaling, &
      lightnox_scale_fac=cfg%lightnox_scale_fac, &
      !anth_so2_ems_scaling=cfg%anth_so2_ems_scaling, &
      mode_activation_dryr=cfg%mode_activation_dryr, &
      !dry_depvel_acc_scaling=cfg%dry_depvel_acc_scaling, &
      !acc_cor_scav_scaling=cfg%acc_cor_scav_scaling, &
      mode_incld_so2_rfrac=cfg%mode_incld_so2_rfrac, &
      biom_aer_ems_scaling=cfg%biom_aer_ems_scaling, &
      !hno3_uptake_coeff=cfg%hno3_uptake_coeff, &
      !ph_fit_coeff_a=cfg%ph_fit_coeff_a, &
      !ph_fit_coeff_b=cfg%ph_fit_coeff_b, &
      !ph_fit_intercept=cfg%ph_fit_intercept, &
      sigwmin=cfg%sigwmin, &
      !sigma_updraught_scaling=cfg%sigma_updraught_scaling, &
      !const_rmol=cfg%const_rmol, &
      !const_tfs=cfg%const_tfs, &
      !const_rho_water=cfg%const_rho_water, &
      !const_rhosea=cfg%const_rhosea, &
      !const_lc=cfg%const_lc, &
      !const_avogadro=cfg%const_avogadro, &
      !const_boltzmann=cfg%const_boltzmann, &
      !const_rho_so4=cfg%const_rho_so4, &
      l_cal360=cfg%l_cal360, &
      l_ukca_chem_aero=cfg%l_ukca_chem_aero, &
      l_ukca_mode=cfg%l_ukca_mode, &
      l_fix_tropopause_level=l_fix_tropopause_level, &
      l_ukca_ageair=cfg%l_ukca_ageair, &
      !l_blankout_invalid_diags=cfg%l_blankout_invalid_diags, &
      l_enable_diag_um=l_enable_diag_um, &
      l_ukca_persist_off=l_ukca_persist_off, &
      l_timer=cfg%l_timer, &
      l_ukca_emissions_off=l_ukca_emissions_off, &
      l_ukca_drydep_off=cfg%l_ukca_drydep_off, &
      l_ukca_wetdep_off=cfg%l_ukca_wetdep_off, &
      !l_ukca_scale_ppe=cfg%l_ukca_scale_ppe, &
      l_ukca_asad_columns=l_ukca_asad_columns, &
      l_ukca_asad_full=l_ukca_asad_full, &
      l_ukca_debug_asad=cfg%l_ukca_debug_asad, &
      l_ukca_intdd=cfg%l_ukca_intdd, &
      l_ukca_ddepo3_ocean=cfg%l_ukca_ddepo3_ocean, &
      l_ukca_ddep_lev1=cfg%l_ukca_ddep_lev1, &
      l_ukca_dry_dep_so2wet=cfg%l_ukca_dry_dep_so2wet, &
      l_deposition_jules=cfg%l_deposition_jules, &
      l_ukca_quasinewton=cfg%l_ukca_quasinewton, &
      l_tracer_lumping=cfg%l_tracer_lumping, &
      l_ukca_ro2_ntp=cfg%l_ukca_ro2_ntp, &
      l_ukca_ro2_perm=cfg%l_ukca_ro2_perm, &
      !l_ukca_intph=cfg%l_ukca_intph, &
      l_ukca_scale_soa_yield_mt=cfg%l_ukca_scale_soa_yield_mt, &
      l_ukca_scale_soa_yield_isop=cfg%l_ukca_scale_soa_yield_isop, &
      l_ukca_het_psc=cfg%l_ukca_het_psc, &
      l_ukca_limit_nat=cfg%l_ukca_limit_nat, &
      l_ukca_sa_clim=cfg%l_ukca_sa_clim, &
      l_ukca_trophet=cfg%l_ukca_trophet, &
      l_ukca_classic_hetchem=cfg%l_ukca_classic_hetchem, &
      l_use_photolysis=cfg%l_use_photolysis, &
      l_ukca_ibvoc=cfg%l_ukca_ibvoc, &
      l_ukca_inferno=cfg%l_ukca_inferno, &
      l_ukca_inferno_ch4=cfg%l_ukca_inferno_ch4, &
      l_ukca_so2ems_expvolc=cfg%l_ukca_so2ems_expvolc, &
      l_ukca_so2ems_plumeria=cfg%l_ukca_so2ems_plumeria, &
      l_ukca_qch4inter=cfg%l_ukca_qch4inter, &
      l_ukca_emsdrvn_ch4=cfg%l_ukca_emsdrvn_ch4, &
      l_ukca_enable_seadms_ems=l_ukca_enable_seadms_ems, &
      l_ukca_scale_seadms_ems=cfg%l_ukca_scale_seadms_ems, &
      l_ukca_linox_scaling=cfg%l_ukca_linox_scaling, &
      l_support_ems_vertprof=cfg%l_support_ems_vertprof, &
      l_support_ems_gridbox_units=cfg%l_support_ems_gridbox_units, &
      !l_suppress_ems=cfg%l_suppress_ems, &
      l_ukca_h2o_feedback=cfg%l_ukca_h2o_feedback, &
      l_ukca_conserve_h=cfg%l_ukca_conserve_h, &
      l_param_conv=cfg%l_param_conv, &
      l_ctile=cfg%l_ctile, &
      l_zon_av_ozone=cfg%l_zon_av_ozone, &
      l_chem_environ_gas_scalars=cfg%l_chem_environ_gas_scalars, &
      l_chem_environ_co2_fld=cfg%l_chem_environ_co2_fld, &
      l_ukca_prescribech4=cfg%l_ukca_prescribech4, &
      l_use_classic_so4=cfg%l_use_classic_so4, &
      l_use_classic_soot=cfg%l_use_classic_soot, &
      l_use_classic_ocff=cfg%l_use_classic_ocff, &
      l_use_classic_biogenic=cfg%l_use_classic_biogenic, &
      l_use_classic_seasalt=cfg%l_use_classic_seasalt, &
      l_use_gridbox_volume=cfg%l_use_gridbox_volume, &
      l_use_gridbox_mass=cfg%l_use_gridbox_mass, &
      !l_environ_rel_humid=cfg%l_environ_rel_humid, &
      l_environ_z_top=l_environ_z_top, &
      !l_fix_ukca_cloud_frac=cfg%l_fix_ukca_cloud_frac, &
      l_fix_improve_drydep=cfg%l_fix_improve_drydep, &
      l_fix_drydep_so2_water=cfg%l_fix_drydep_so2_water, &
      l_fix_ukca_h2dd_x=cfg%l_fix_ukca_h2dd_x, &
      l_fix_ukca_offox_h2o_fac=cfg%l_fix_ukca_offox_h2o_fac, &
      l_fix_ukca_h2so4_ystore=cfg%l_fix_ukca_h2so4_ystore, &
      l_mode_bhn_on=cfg%l_mode_bhn_on, &
      l_mode_bln_on=cfg%l_mode_bln_on, &
      l_ddepaer=cfg%l_ddepaer, &
      !l_aero_rainout=cfg%l_aero_rainout, &
      l_cv_rainout=cfg%l_cv_rainout, &
      !l_impc_scav=cfg%l_impc_scav, &
      !l_dust_mp_slinn_impc_scav=cfg%l_dust_mp_slinn_impc_scav, &
      l_ukca_primss=cfg%l_ukca_primss, &
      l_ukca_primsu=cfg%l_ukca_primsu, &
      l_ukca_primdu=cfg%l_ukca_primdu, &
      l_ukca_primbcoc=cfg%l_ukca_primbcoc, &
      l_ukca_prim_moc=cfg%l_ukca_prim_moc, &
      l_bcoc_bf=cfg%l_bcoc_bf, &
      l_bcoc_bm=cfg%l_bcoc_bm, &
      l_bcoc_ff=cfg%l_bcoc_ff, &
      l_ukca_scale_biom_aer_ems=cfg%l_ukca_scale_biom_aer_ems, &
      l_ukca_fine_no3_prod=cfg%l_ukca_fine_no3_prod, &
      l_ukca_coarse_no3_prod=cfg%l_ukca_coarse_no3_prod, &
      l_no3_prod_in_aero_step=cfg%l_no3_prod_in_aero_step, &
      l_ukca_scale_sea_salt_ems=cfg%l_ukca_scale_sea_salt_ems, &
      l_ukca_scale_marine_pom_ems=cfg%l_ukca_scale_marine_pom_ems, &
      !l_ukca_mp_fragment=cfg%l_ukca_mp_fragment, &
      !l_ukca_mp_fibre=cfg%l_ukca_mp_fibre, &
      l_ukca_radaer=cfg%l_ukca_radaer, &
      l_ntpreq_n_activ_sum=cfg%l_ntpreq_n_activ_sum, &
      l_ntpreq_dryd_nuc_sol=cfg%l_ntpreq_dryd_nuc_sol, &
      l_ukca_sfix=cfg%l_ukca_sfix, &
      l_fix_neg_pvol_wat=cfg%l_fix_neg_pvol_wat, &
      l_fix_ukca_impscav=cfg%l_fix_ukca_impscav, &
      l_fix_nacl_density=cfg%l_fix_nacl_density, &
      l_improve_aero_drydep=cfg%l_improve_aero_drydep, &
      l_fix_ukca_water_content=cfg%l_fix_ukca_water_content, &
      l_fix_ukca_activate_pdf=cfg%l_fix_ukca_activate_pdf, &
      l_fix_ukca_activate_vert_rep=cfg%l_fix_ukca_activate_vert_rep, &
      l_bug_repro_tke_index=cfg%l_bug_repro_tke_index, &
      !l_dust_mp_ageing=cfg%l_dust_mp_ageing, &
      l_fix_ukca_hygroscopicities=cfg%l_fix_ukca_hygroscopicities, &
      !l_skip_const_setup=cfg%l_skip_const_setup, &
      error_message=error_message, error_routine=error_routine)

    if(err_code /= 0) then
      write(err_msg, "(2A)") "Error in ukca_setup: ", trim(error_message)
      call ereport(trim(error_routine), err_code, err_msg)
    endif

  endsubroutine setup_internal_ukca_config

  subroutine read_internal_ukca_config()

    !! Get the ukca internal options needed by the box model. Must be called
    !! after ukca_setup() has been called.

    use ukca_api_mod, only: ukca_get_config, &
                            ukca_errcode_ukca_uninit, ukca_maxlen_message, &
                            ukca_photol_varname_len, &
                            ukca_get_photol_reaction_data
    use ereport_mod, only: ereport

    !> Logical indicating whether the internal configuration is available
    logical :: l_config_available
    !> Error code for reporting internal configuration not available
    integer :: err_code
    !> Pointer to an array containing the photolytic reaction data
    character(len=10), pointer :: ratj_data(:, :)
    !> Pointer to an array containing the names of the photolytic reaction
    !> variables
    character(len=ukca_photol_varname_len), pointer :: ratj_varnames(:)
    !> Subroutine name for error reporting
    character(len=*), parameter :: routine_name = &
                                   "read_internal_ukca_config"
    !> Message for error reporting
    character(len=ukca_maxlen_message) :: err_msg

    err_code = 0

    call ukca_get_config(n_dust_emissions=n_dust_emissions, &
                         l_config_available=l_config_available)

    if(.not. l_config_available) then
      err_code = ukca_errcode_ukca_uninit
      write(err_msg, "(A)") "UKCA internal configuration not available. "// &
        "ukca_setup() must be called first."
      call ereport(mod_name//":"//routine_name, err_code, err_msg)
    endif

    ! Get the number of photolytic reactions
    call ukca_get_photol_reaction_data(ratj_data, ratj_varnames)
    jppj = size(ratj_varnames)

  endsubroutine read_internal_ukca_config

endmodule box_internal_ukca_config_mod
