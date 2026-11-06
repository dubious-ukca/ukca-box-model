# ============================================================================
# Build UKCA library from submodule
# ============================================================================

if(BUILD_UKCA_LIBRARY)

add_library(ukca_standalone
  ${CMAKE_SOURCE_DIR}/src/ereport_mod.F90
  ${CMAKE_SOURCE_DIR}/src/um_equivs/conversions_mod.F90
  ${CMAKE_SOURCE_DIR}/src/um_equivs/fastjx_inphot_mod.F90
  ${CMAKE_SOURCE_DIR}/src/um_equivs/fastjx_specs.F90
  ${CMAKE_SOURCE_DIR}/src/um_equivs/missing_data_mod.F90
  ${CMAKE_SOURCE_DIR}/src/um_equivs/planet_constants_mod.F90
  ${CMAKE_SOURCE_DIR}/src/um_equivs/setup_namelist.F90
  ${CMAKE_SOURCE_DIR}/src/um_equivs/um_parcore.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/asad_chem_flux_diags.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/asad_diags_output_ctl_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/asad_flux_dat.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/get_nmvoc_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/get_noy_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_diags_output_ctl_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_emdiags_struct_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_emiss_diags_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_emiss_diags_mode_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_mode_diags_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_offline_oxidants_diags_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_pm_diags_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_raq_diags_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_tracer_vars.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/diagnostics/ukca_update_emdiagstruct_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/common_mode_setup_interface_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_config_constants_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_config_specification_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_constants_setup_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_diagnostics_init_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_diagnostics_master_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_diagnostics_output_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_diagnostics_requests_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_diagnostics_set_ptrs_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_diagnostics_type_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_emiss_api_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_environment_check_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_environment_diags_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_environment_fields_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_environment_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_environment_rdim_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_environment_req_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_fieldname_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_mode_setup_interface_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_ntp_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_pr_inputs_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_tracers_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/interface/ukca_api_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/misc/ukca_missing_data_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/misc/ukca_types_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_age_air_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_config_defs_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_humidity_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_iniasad.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_init.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_main1-ukca_main1.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_setup_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_solang.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_step_control_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_step_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_time_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/core/top_level/ukca_tropopause.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/legacy/errormessagelength_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/legacy/parkind1.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/legacy/ukca_um_legacy_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/legacy/umprintmgr.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/legacy/yomhook.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_config_specification_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_constants_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_environment_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_setup_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_ctl_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_calc_ozonecol_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_fieldname_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_api_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_step_control.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/photolysis/interface/photol_check_environment_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/control/shared/ukca_error_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/activation/ukca_abdulrazzak_ghan.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/activation/ukca_activ_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/activation/ukca_activate.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/activation/ukca_cdnc_jones_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/activation/ukca_cloudproc.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/activation/ukca_fixeds.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/deposition/ukca_dcoff_par_av_k.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/deposition/ukca_ddepaer_coeff_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/deposition/ukca_ddepaer_incl_sedi_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/deposition/ukca_ddepaer_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/deposition/ukca_impc_scav.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/deposition/ukca_impc_scav_dust_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/deposition/ukca_rainout.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/deposition/ukca_vgrav_av_k.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_aero_ctl.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_aero_step.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_ageing.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_binapara_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_calc_coag_kernel.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_calc_drydiam.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_calcminmaxgc.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_calcminmaxndmdt.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_calcnucrate.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_check_md_nd.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_check_radaer_coupling_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_coag_coff_v.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_coagwithnucl.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_coarse_no3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_cond_coff_v.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_conden.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_drydiam_field_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_fine_no3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_mode_check_artefacts_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_mode_setup.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_mode_tracer_maps_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_mode_verbose_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_remode.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_setup_indices.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_solvecoagnucl_v.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_vapour.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_volume_mode.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_water_content_v.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/aerosols/glomap/ukca_wetox.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_bedriv.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_bimol.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_cdrive.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_cinit.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_diffun.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_findreaction.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_ftoy.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_fuljac.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_fyfixr.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_fyinit.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_fyself.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_hetero.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_impact.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_inicnt.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_inicnt_col_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_inijac.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_inimpct.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_inix.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_inrats.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_jac.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_posthet.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_prls.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_setsteady.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_sparse_vars.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_spimpmjp.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_spmjpdriv.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_steady.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_totnud.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/asad_trimol.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/ukca_drydep.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/ukca_inddep.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/ukca_inwdep.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/ukca_photol.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/asad/ukca_wetdep.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/deposition/ukca_aerod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/deposition/ukca_be_drydep.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/deposition/ukca_be_wetdep.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/deposition/ukca_ddcalc.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/deposition/ukca_ddepctl.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/deposition/ukca_ddepo3_ocean_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/deposition/ukca_ddeprt.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/deposition/ukca_surfddr.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/deposition/ukca_wdeprt.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/get_molmass_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_calc_cloud_ph_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_ch4_stratloss.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chem1_dat.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chem_aer.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chem_defs_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chem_diags_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chem_master.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chem_offline.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chem_raq.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chem_raqaero_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemco.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemco_raq.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemco_raq_init_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemistry_cleanup.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemistry_ctl.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemistry_ctl_BE_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemistry_ctl_col_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemistry_ctl_full_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemistry_ctl_tropraq_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_chemistry_setup.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_conserve_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_constants.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_cspecies.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_deriv.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_deriv_aero.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_deriv_raq.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_deriv_raqaero_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_diurnal_oxidant.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_fdiss.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_fdiss_constant_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_fracdiss.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_hetero_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_sediment.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_setup_chem_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_stratf.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_top_boundary.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_transform_halogen.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/chemistry/ukca_trop_hetchem.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_add_emiss_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_aer_no3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_calc_rho_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_day_of_week_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_diurnal_isop_ems.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_dms_flux_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_emiss_ctl_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_emiss_factors.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_emiss_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_emiss_mode_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_emiss_struct_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_ingridg.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_light.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_light_ctl.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_prim_du_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_prim_moc.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_prim_ss.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_prod_no3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_scenario_common.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_scenario_ctl_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_scenario_prescribed.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/core/emissions/ukca_scenario_wmoa1.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/tropospheric/photol_curve_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/tropospheric/ukca_phot2d.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/tropospheric/ukca_flupj.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/fastjx_data.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/ukca_fastjx.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/fastjx_solar2.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/photol_solflux_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/fastjx_photoj.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/fastjx_extral.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/fastjx_set_aer.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/fastjx_sphere.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/fastjx_opmie.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/fastjx_jratet.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/fastjx/fastjx_miesct.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/ukca_um_dissoc_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/ukca_um_strat_photol_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/inijtab_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/ukca_tbjs_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/fill_spectra_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/ukca_crossec_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/scatcs_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/setzen_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/settab_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/lymana_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsn2o5_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsn2o_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsccl4_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsf11_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsf12_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsf22_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsmc_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/quanto12_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acso3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acscnit_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsh2o2_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsbrcl_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsno2_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acscos_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsmena_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acshno3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsdbrm_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acscs2_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsh2so4_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsso3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acsno_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acssr_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/cso2o3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/ei2_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/ei3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/invert_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/calcjs_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/ukca_stdto3_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/isrchfgt_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acso3w_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/acssrw_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/ei1_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/ludcmp_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/lubksb_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photolib/ukca_parpho_mod.F90
  ${CMAKE_SOURCE_DIR}/ukca/src/science/photolysis/stratospheric/photol_solang_mod.F90
  )

# Set compile options for UKCA
target_compile_options(ukca_standalone PRIVATE ${UKCA_PRECISION_FLAGS} -O0 -fcheck=all,no-bounds -ffpe-trap=invalid,zero,overflow)

install(TARGETS ukca_standalone
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
)

install(DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}/
  DESTINATION include/ukca/mod
  FILES_MATCHING PATTERN "*.mod"
)

endif()

# ============================================================================
# Build box model executable
# ============================================================================

if(BUILD_BOX_MODEL)

# Box model source files (explicitly listed)
set(BOX_MODEL_SOURCES
  box_err_codes.F90
  box_const.F90
  box_config.F90
  box_shell.F90
  ukca_box_model_main.F90
  box_debug.F90
  box_dump.F90
  ukca_internal_dump.F90
  box_jules.F90
  box_internal_ukca_config.F90
  box_socrates.F90
  box_environment.F90
  box_tracers.F90
  box_ntp.F90
  box_time.F90
  box_io.F90
  box_photol.F90
  box_config_validator.F90
  )

# Create box model executable
add_executable(ukca_box_model ${BOX_MODEL_SOURCES})

# Set compile options for box model
target_compile_options(ukca_box_model PRIVATE
  ${UKCA_PRECISION_FLAGS}
  -O0
  -g
  -fcheck=all
  -fbacktrace
  -ffpe-trap=invalid,zero,overflow
  -finit-real=snan
  -finit-integer=-999999
  -finit-logical=true
  -Wall
  -Wextra
  -Warray-temporaries
  -Wimplicit-interface
  -fimplicit-none
  -std=f2008
  -fimplicit-none
  -Wpedantic
  -Werror
  -pedantic-errors
  -Wimplicit-procedure
  -Wcharacter-truncation
  -Wline-truncation
  -Wconversion
  -Wsurprising
  -Warray-temporaries
  -Wunderflow
  -Wintrinsics-std
  -Wno-error=maybe-uninitialized
)

# Link UKCA library to box model
if(UKCA_USE_EXTERNAL_LIBRARY)
  find_library(UKCA_STANDALONE_LIBRARY
    NAMES ukca_standalone
    REQUIRED
  )

  if(NOT UKCA_EXTERNAL_MODULE_DIR)
    message(FATAL_ERROR "UKCA_EXTERNAL_MODULE_DIR must be set when UKCA_USE_EXTERNAL_LIBRARY=ON")
  endif()

  target_include_directories(ukca_box_model
    PRIVATE ${UKCA_EXTERNAL_MODULE_DIR}
  )

  target_link_libraries(ukca_box_model
    PRIVATE ${UKCA_STANDALONE_LIBRARY}
  )
else()
  if(NOT BUILD_UKCA_LIBRARY)
    message(FATAL_ERROR "BUILD_UKCA_LIBRARY must be ON unless UKCA_USE_EXTERNAL_LIBRARY is enabled")
  endif()

  target_link_libraries(ukca_box_model
    PRIVATE ukca_standalone
  )
endif()

install(TARGETS ukca_box_model
  RUNTIME DESTINATION bin
)

install(DIRECTORY
  ${CMAKE_SOURCE_DIR}/examples/
  DESTINATION share/ukca-box-model/examples
)

endif()