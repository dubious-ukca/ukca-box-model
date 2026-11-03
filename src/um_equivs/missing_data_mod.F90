! Module made for replicating the missing_data_mod typically found
! within the UM for use inside the new UKCA box model.
!
!
!
! Data module containing missing data indicies
!
! Migrated from include file c_mdi.h
!
! Code Owner: Please refer to the UM file CodeOwners.txt
! This file belongs in section: top_level
!
! Code Description:
!   Language: FORTRAN 90
!

module missing_data_mod

  implicit none

  public

  ! PP missing data indicator (-1.0E+30)
  real, parameter    :: rmdi_pp = -1.0e+30

  ! Old real missing data indicator (-32768.0)
  real, parameter    :: rmdi_old = -32768.0

  ! New real missing data indicator (-2**30)
  real, parameter    :: rmdi = -32768.0 * 32768.0

  ! Integer missing data indicator
  integer, parameter :: imdi = -32768

endmodule missing_data_mod
