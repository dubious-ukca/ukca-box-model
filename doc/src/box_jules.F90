module box_jules_mod

  !! Module for storing constants for the UKCA box model that are stored in
  !! the Jules model for the operational runs. To reduce the number of
  !! dependencies on Jules, we store the constants here in the box model
  !! and set them to the same values as in Jules.
  !!
  !! Note the values of each constant are dependent on the number of land types
  !! (ntype), which is a configuration option set by the user. setup_jules()
  !! must therefore be called.

  use ukca_missing_data_mod, only: imdi

  implicit none

  public

  ! TODO - frac_types is a jules variable - need to have something in here for
  ! it

  !> Module name for error reporting
  character(len=*), parameter, private :: mod_name = "box_jules_mod"

  !> number of land types
  integer, protected :: ntype = imdi

  !> No. of elevated ice types in the 27 surface type configuration
  integer, parameter :: n_elev_ice = 10
  !> Array of indices for the elevated ice types in the 27 surface type
  !> configuration
  integer, dimension(:), allocatable, protected :: i_elev_ice

  !> Number of plant functional types considered in interactive dry deposition
  integer, protected :: npft = imdi
  !> Number of non-vegetation surface types
  integer, protected :: nnvg = imdi

  !> Index of surface type 'broad-leaf tree'
  integer, protected :: i_brd_leaf = imdi
  !> Index of surface type 'broad-leaf dec tree'
  integer, protected :: i_brd_leaf_dec = imdi
  !> Index of surface type 'broad-leaf eg trop tree'
  integer, protected :: i_brd_leaf_eg_trop = imdi
  !> Index of surface type 'broad-leaf eg temp tree'
  integer, protected :: i_brd_leaf_eg_temp = imdi
  !> Index of surface type 'needle-leaf tree'
  integer, protected :: i_ndl_leaf = imdi
  !> Index of surface type 'needle-leaf dec tree'
  integer, protected :: i_ndl_leaf_dec = imdi
  !> Index of surface type 'needle-leaf eg tree'
  integer, protected :: i_ndl_leaf_eg = imdi
  !> Index of surface type 'c3 grass'
  integer, protected :: i_c3_grass = imdi
  !> Index of surface type 'c3 crop'
  integer, protected :: i_c3_crop = imdi
  !> Index of surface type 'c3 pasture'
  integer, protected :: i_c3_pasture = imdi
  !> Index of surface type 'c4 grass'
  integer, protected :: i_c4_grass = imdi
  !> Index of surface type 'c4 crop'
  integer, protected :: i_c4_crop = imdi
  !> Index of surface type 'c4 pasture'
  integer, protected :: i_c4_pasture = imdi
  !> Index of surface type 'shrub'
  integer, protected :: i_shrub = imdi
  !> Index of surface type 'shrub dec'
  integer, protected :: i_shrub_dec = imdi
  !> Index of surface type 'shrub eg'
  integer, protected :: i_shrub_eg = imdi
  !> Index of surface type 'urban'
  integer, protected :: i_urban = imdi
  !> Index of surface type 'lake'
  integer, protected :: i_lake = imdi
  !> Index of surface type 'soil'
  integer, protected :: i_soil = imdi
  !> Index of surface type 'ice'
  integer, protected :: i_ice = imdi

contains

  subroutine setup_jules(ntype_in)

    !! Set up the constants related to the Jules model for use by the UKCA box
    !! model. Takes number of land types (ntype) to determine constant values.

    use ereport_mod, only: ereport
    use ukca_api_mod, only: ukca_errcode_value_invalid, ukca_maxlen_message

    !> Number of land types (surface types) for the box model configuration
    integer, intent(in) :: ntype_in
    !> Name of the routine for error reporting
    character(len=*), parameter :: routine_name = "setup_jules"
    !> Error message for error reporting
    character(len=ukca_maxlen_message) :: error_message
    !> Error code for error reporting
    integer :: errcode
    !> loop index for creation of i_elev_ice array
    integer ::  i

    errcode = 0
    ntype = ntype_in

    select case(ntype)
    case(9)
      npft = 5
      nnvg = 4
      i_brd_leaf = 1
      i_ndl_leaf = 2
      i_c3_grass = 3
      i_c4_grass = 4
      i_shrub = 5
      i_urban = 6
      i_lake = 7
      i_soil = 8
      i_ice = 9
    case(13)
      npft = 9
      nnvg = 4
      i_brd_leaf = 1
      i_brd_leaf_dec = 2
      i_brd_leaf_eg_trop = 3
      i_ndl_leaf_dec = 4
      i_ndl_leaf_eg = 5
      i_c3_grass = 6
      i_c4_grass = 7
      i_shrub_dec = 8
      i_shrub_eg = 9
      i_urban = 10
      i_lake = 11
      i_soil = 12
      i_ice = 13
    case(17)
      npft = 13
      nnvg = 4
      i_brd_leaf_dec = 1
      i_brd_leaf_eg_trop = 2
      i_brd_leaf_eg_temp = 3
      i_ndl_leaf_dec = 4
      i_ndl_leaf_eg = 5
      i_c3_grass = 6
      i_c3_crop = 7
      i_c3_pasture = 8
      i_c4_grass = 9
      i_c4_crop = 10
      i_c4_pasture = 11
      i_shrub_dec = 12
      i_shrub_eg = 13
      i_urban = 14
      i_lake = 15
      i_soil = 16
      i_ice = 17
    case(27)
      nnvg = 14
      npft = 13
      i_brd_leaf_dec = 1
      i_brd_leaf_eg_trop = 2
      i_brd_leaf_eg_temp = 3
      i_ndl_leaf_dec = 4
      i_ndl_leaf_eg = 5
      i_c3_grass = 6
      i_c3_crop = 7
      i_c3_pasture = 8
      i_c4_grass = 9
      i_c4_crop = 10
      i_c4_pasture = 11
      i_shrub_dec = 12
      i_shrub_eg = 13
      i_urban = 14
      i_lake = 15
      i_soil = 16
      i_ice = 17
      ! dependent on n_elev_ice
      i_elev_ice = [(i, i=18, 17 + n_elev_ice)]
    case default
      write(error_message, '(A,I0,A)') 'Unsupported ntype value: ', ntype, &
        '. Supported values are: 9, 13, 17, 27'
      errcode = ukca_errcode_value_invalid
      call ereport(mod_name//":"//routine_name, errcode, &
                   error_message)
    endselect

  endsubroutine setup_jules

endmodule box_jules_mod
