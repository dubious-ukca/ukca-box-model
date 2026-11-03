module box_socrates_mod

  !! Module for storing constants for the UKCA box model that are stored in
  !! the socrates model for the operational runs. To reduce the number of
  !! dependencies on socrates, we store the constants here in the box model
  !! and set them to the same values as in socrates.

  implicit none

  public

  !> Parametrization for moist aerosols
  integer, parameter :: ip_aerosol_param_moist = 2
  !> Aerosols for the sulphur cycle - Accumulation mode sulphate
  integer, parameter :: ip_accum_sulphate = 10
  !> Aitken mode sulphate
  integer, parameter :: ip_aitken_sulphate = 11

endmodule box_socrates_mod
