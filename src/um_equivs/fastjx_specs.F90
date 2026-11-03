module fastjx_specs

  implicit none

  public

  integer, parameter :: photol_jlabel_len = 7
  integer, parameter :: x_ = 100  ! Max no. of cross sections to be read

  ! Array containing labels for photolysed species as read from file
  character(LEN=photol_jlabel_len) :: titlej(x_)

endmodule fastjx_specs
