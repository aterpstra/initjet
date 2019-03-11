!-------------------------------------------------------------
! Module for i/o
! input:  from jet.namelist
! output: 1) .bin (binary input file for WRFV3.4)
!         2) .nc 
!         3) .txt 
!
! For more info see the README file
!--------------------------------------------------------------


module io

USE const
USE netcdf

implicit none

!define namelist variables 
integer      :: nx,ny,nz,P_ny,P_nx,U_type,BT_type,RH_type,P_type,bc_vert
real(kind=8) :: Lx,Ly,Lz,f,beta
real(kind=8) :: U_max,U_hgt,U_width,U_top,U_bottom,U_hwe,U_hwp,U_tilt,S_tr,S_st,BT_max,y_llj,nh_llj,h_llj,ny_llj, &
                  H1,H2,H3,H4,A1,A2,H1s,H2s,H3s,H4s,brd_llj,pr_llj,h2_llj,scl, &
		  hor_leng,S_o,S_u,S_h,U_max2, front_slope
integer :: U_shape, &  !Hai: new option 8/2, apply for U_type=99, =1:cos, =2:cos^2,=3:1-r,4:1-r^2
           Z_opt   ! 0: no skew, =1: linear, =2 tanh (z=f(y))
real(kind=8) :: p0,th0,tropo_hgt,N2_tr,N2_st, bc_type
real(kind=8) :: RH_max,RH_min,RH_hgt,RH_shape
real(kind=8) :: P_rad,P_z,P_amp,P_hgt,P_ratio,P_n
real(kind=8) :: N2_vals(6),N2_levs(6)  !Hai: For define N (use with bc_type=1),linear int. between levs
!Hai sst option
integer :: sst_type
real(kind=8) :: sst_diff, sst_scale

character(len=20) :: ifile_uprof
logical   :: debug,wrf_file,nc_file,add_BT,add_moist,add_pert,P_sfc,ext_prof,bouss,rebalance
                     
CONTAINS 

!---------------------------------------------------------------------------
subroutine get_nml()
!reads in the variables from the namelist-file (jet.namelist)
  integer :: ios
  namelist /domain/ nx,ny,nz,Lx,Ly,Lz,f,beta
  namelist /jet/ U_type,U_max,U_hgt,U_width,U_top,U_bottom,U_hwe,U_hwp,U_tilt,front_slope, &
                    S_tr,S_st,&
                    add_BT,BT_type,BT_max,y_llj,nh_llj,h_llj,ny_llj,&
                    H1,H2,H3,H4,A1,A2,H1s,H2s,H3s,H4s,ifile_uprof,brd_llj,pr_llj,h2_llj,scl,&
        hor_leng,S_o,S_u,S_h,U_max2, front_slope, U_shape, Z_opt
!Hai: front_slope is used for U_type=99 only, which will specify a curved jet center,
!     in combination with asymmetric jet, hopefully we can recreate the front similarity
  namelist /stab/ bc_type,p0,th0,tropo_hgt,N2_tr,N2_st,bc_vert,bouss,N2_vals,N2_levs
  namelist /moist/ add_moist,RH_type,RH_max,RH_min,RH_hgt,RH_shape
  namelist /pert/ add_pert,P_type,P_rad,P_z,P_amp,P_nx,P_ny,P_hgt,P_ratio,P_sfc,P_n,rebalance
  namelist /prog/ debug,wrf_file,nc_file,ext_prof
  namelist /sst/ sst_type,sst_diff,sst_scale

  !set defaults (will be overwritten by namelist if set)
  bouss=.false.
  add_BT=.false.
  beta=0.
  debug=.false.
  sst_type=0
  bc_vert=0
  rebalance=.true.


  !open the namelist file
  open(unit=20,file='namelist.initJET',status='old',iostat=ios)
    if (ios /= 0) then
       print*,'ERROR: could not open namelist file'
       stop
    end if
    
  !read the data
  read(unit=20,nml=prog)
  read(unit=20,nml=domain)
  read(unit=20,nml=jet)
  read(unit=20,nml=sst)
  read(unit=20,nml=stab)
  read(unit=20,nml=moist)
  read(unit=20,nml=pert)
  close(20)
end subroutine get_nml
!---------------------------------------------------------------------------


!---------------------------------------------------------------------------
subroutine write_wrf(uu,vv,th,rho,qq,ff,pp,sst)
  ! generate unformated fortran file 
  ! used as input for WRF ideal.exe,
  real(kind=8), intent(in), dimension(nx,ny,nz) :: uu,vv,th,rho,qq,pp
  real(kind=8), intent(in), dimension(nx,ny) :: sst
  real(kind=8), intent(in), dimension(ny) :: ff
  
  if(debug)then
    print*,''
    print*,'--- WRITING OUTPUT .bin ---' 
  endif

  OPEN(unit=17, file='input_jet_3D', &
        form='unformatted',status='replace',convert='swap')  !for gfortran compiler
  !OPEN(unit=17, file='input_jet_3D', form='unformatted',status='replace')  !for pgf90 compiler
  write(17)nx,ny,nz
  write(17)real(uu)
  write(17)real(vv)
  write(17)real(th)
  write(17)real(rho)
  write(17)real(qq)
  write(17)real(ff)
  write(17)real(sst)
  write(17)real(pp)
  CLOSE(17)
  end subroutine write_wrf
!---------------------------------------------------------------------------


!---------------------------------------------------------------------------
subroutine write_nc(uu,pp,rho,tt,rh,th,thv,ttv,qq,zz,ff,sst)
!write 2D version of the jet to jet.nc
  real(kind=8),intent(in),dimension(ny,nz) :: uu,pp,rho,tt,rh,th,thv,ttv,qq,zz
  real(kind=8),intent(in),dimension(nx,ny) :: sst
  real(kind=8),intent(in),dimension(ny) :: ff
  character(len=*), parameter :: fname = "initJET.nc"
  integer, parameter          :: ndims=2
  integer                     :: ncid, dimids(ndims),dimny(1),z_dimid,y_dimid, no_dims,x_dimid, dimids2(ndims)
  integer   :: varid_u,varid_p,varid_rho,varid_tt,varid_rh,varid_th,varid_thv,varid_ttv,varid_qq,varid_zz
  integer   :: varid_f, varid_ff,varid_sst,varid_dy, varid_dz,varid_dx
  real(kind=8)::dy,dz,dx

  if(debug)then
    print*,''
    print*,'--- WRITING OUTPUT .NC ---' 
  endif

  !oeps cannot access dy...
  dy=Ly/(ny-1)
  dz=Lz/(nz-1)

  !create netcdf
  call check( nf90_create(fname, NF90_CLOBBER, ncid) )

  !define dimensions
  call check( nf90_def_dim(ncid, "z", nz, z_dimid) )
  call check( nf90_def_dim(ncid, "y", ny, y_dimid) )
  call check( nf90_def_dim(ncid, "x", nx, x_dimid) )

  dimids =  (/ y_dimid, z_dimid /)
  dimids2=  (/ x_dimid, y_dimid /)
  dimny=y_dimid
  !define data
  call check( nf90_def_var(ncid, "f",  NF90_REAL, varid_f) )
  call check( nf90_def_var(ncid, "dx", NF90_REAL, varid_dx) )
  call check( nf90_def_var(ncid, "dy", NF90_REAL, varid_dy) )
  call check( nf90_def_var(ncid, "dz", NF90_REAL, varid_dz) )
  call check( nf90_def_var(ncid, "ff", NF90_REAL, dimny,varid_ff) )
  call check( nf90_def_var(ncid, "sst",NF90_REAL, dimids2,varid_sst) )
  call check( nf90_def_var(ncid, "uu", NF90_REAL, dimids, varid_u) )
  call check( nf90_def_var(ncid, "pp", NF90_REAL, dimids, varid_p) )
  call check( nf90_def_var(ncid, "rho",NF90_REAL, dimids, varid_rho) )
  call check( nf90_def_var(ncid, "tt", NF90_REAL, dimids, varid_tt) )
  call check( nf90_def_var(ncid, "rh", NF90_REAL, dimids, varid_rh) )
  call check( nf90_def_var(ncid, "th", NF90_REAL, dimids, varid_th) )
  call check( nf90_def_var(ncid, "thv",NF90_REAL, dimids, varid_thv) )
  call check( nf90_def_var(ncid, "ttv",NF90_REAL, dimids, varid_ttv) )
  call check( nf90_def_var(ncid, "qq", NF90_REAL, dimids, varid_qq) )
  call check( nf90_def_var(ncid, "zz", NF90_REAL, dimids, varid_zz) )
  call check( nf90_enddef(ncid) )

  !write the data
  call check( nf90_put_var(ncid, varid_f,  f)  )
  call check( nf90_put_var(ncid, varid_ff,  ff)  )
  call check( nf90_put_var(ncid, varid_sst,  sst)  )
  call check( nf90_put_var(ncid, varid_dx, dx) )
  call check( nf90_put_var(ncid, varid_dy, dy) )
  call check( nf90_put_var(ncid, varid_dz, dz) )
  call check( nf90_put_var(ncid, varid_u,  uu) )
  call check( nf90_put_var(ncid, varid_p,  pp) )
  call check( nf90_put_var(ncid, varid_rho,rho))
  call check( nf90_put_var(ncid, varid_tt, tt) )
  call check( nf90_put_var(ncid, varid_rh, rh) )
  call check( nf90_put_var(ncid, varid_th, th) )
  call check( nf90_put_var(ncid, varid_thv,thv))
  call check( nf90_put_var(ncid, varid_ttv,ttv))
  call check( nf90_put_var(ncid, varid_qq, qq) )
  call check( nf90_put_var(ncid, varid_zz, zz) )
  !close the file
  call check( nf90_close(ncid) )

end subroutine write_nc
!---------------------------------------------------------------------------



!---------------------------------------------------------------------------
subroutine read_nc(ifile,prof)
!read in a single vertical profile from ifile .nc
character(len=*),intent(in) :: ifile
real(kind=8),intent(out),dimension(nz) :: prof
integer :: ncid, varid, dimid, nprof

!open netcdf
call check( nf90_open(ifile, NF90_NOWRITE, ncid) )

!get the dimension and allocate prof-array
call check( nf90_inq_dimid(ncid, "ncl1", dimid) ) !assume name of dim is from ncl...
call check( nf90_inquire_dimension(ncid, dimid, len = nprof))
if(.not.nprof==nz)then
  print*,"WARNING: input profile length does not match nz"
end if

!get the var id
call check( nf90_inq_varid(ncid, "prof", varid) )

!read the data.
call check( nf90_get_var(ncid, varid, prof) )

!close the file
call check( nf90_close(ncid) )

end subroutine read_nc
!---------------------------------------------------------------------------




!---------------------------------------------------------------------------
subroutine check(status)
    !checking for status during netcdf io 
    integer, intent(in) :: status
    if(status /= nf90_noerr) then 
      print *, trim(nf90_strerror(status))
      stop "Stopped"
    end if
end subroutine check  
!---------------------------------------------------------------------------


!---------------------------------------------------------------------------
subroutine print_profile_m(pp,uu,dz)
!print center profile of jet and pressure
  real(kind=8),intent(in) :: pp(ny,nz),uu(ny,nz),dz
  real(kind=8) :: z
  integer :: k
  print*," "
  print*,"vertical profile, @center after solving matrix: hgt,pp,uu"
  print*,"---------------------------------------------------------"
  do k=1,nz
    z=(k-1)*dz
    print'(F10.3,F12.3,F8.3)',z,pp(int(ny/2),k),uu(int(ny/2),k)
  enddo
end subroutine print_profile_m
!---------------------------------------------------------------------------


!---------------------------------------------------------------------------
subroutine print_profile_j(uu,dz)
!print center profile of jet 
  real(kind=8),intent(in) :: uu(ny,nz),dz
  real(kind=8) :: z
  integer :: k
    print*," "
    print*,"vertical profile, @center from get_jet: hgt,uu"
    print*,"----------------------------------------------"
    do k=1,nz
      z=(k-1)*dz
      print'(F10.3,F10.3,F12.3)',z,uu(int(ny/2),k)
    enddo
end subroutine print_profile_j
!---------------------------------------------------------------------------


!---------------------------------------------------------------------------
subroutine print_profile_bc(th,pp,rho,dz)
!print vertical boundary conditions profile
  real(kind=8),intent(in) :: th(nz),pp(nz),rho(nz),dz
  real(kind=8) :: z
  integer :: k
    print*," "
    print*,"vertical profile from BC: hgt,th,p,rho"
    print*,"----------------------------------"
    do k=1,nz
      z=(k-1)*dz
      print'(F10.3,F10.3,F12.3,F10.4)',z,th(k),pp(k),rho(k)
    enddo
end subroutine print_profile_bc
!---------------------------------------------------------------------------




!---------------------------------------------------------------------------
subroutine print_corr_and_sst(sst,ff)
!print vertical boundary conditions profile
  real(kind=8),intent(in),dimension(nx,ny) :: sst
    real(kind=8),intent(in),dimension(ny) :: ff
  integer :: j
    print*," "
    print*,"horizontal: corriolis, sst"
    print*,"----------------------------------"
    do j=1,ny
      print'(F10.7,F10.3)',ff(j), sst(1,j)
    enddo
end subroutine print_corr_and_sst
!---------------------------------------------------------------------------


!---------------------------------------------------------------------------
subroutine print_sounding(uu,pp,rho,tt,th,rh,dz)
!print vertical boundary conditions profile
  real(kind=8),intent(in),dimension(ny,nz) :: uu,pp,rho,tt,rh,th
  real(kind=8),intent(in) :: dz
  real(kind=8) :: z
  integer :: k
    print*," "
    print*,"sounding, @center,before pert: hgt,pp,rho,ttv,thv,uu,rh"
    print*,"-------------------------------------------------------"
    do k=1,nz
      z=(k-1)*dz
      print'(F10.3,F12.3,F8.3,F10.3,F10.3,F10.3,F10.3)',z,pp(int(ny/2),k),&
          rho(int(ny/2),k),tt(int(ny/2),k),th(int(ny/2),k),uu(int(ny/2),k),rh(int(ny/2),k)
    enddo
end subroutine print_sounding
!---------------------------------------------------------------------------


!---------------------------------------------------------------------------
subroutine print_sounding2(uu,pp,rho,tt,rh,th,thv,ttv,qq,zz)
!print vertical boundary conditions profile
  real(kind=8),intent(in),dimension(ny,nz) :: uu,pp,rho,tt,rh,th,thv,ttv,qq,zz
  integer :: k
    print*," "
    print*,"sounding, @center pert,after pert: hgt,pp,rho,tt,uu,rh,qq,th,thv,ttv"
    print*,"---------------------------------------------------------------------"
    do k=1,nz
      print'(F9.3,F11.3,F6.3,F9.3,F8.3,F7.3,F7.3,F9.3,F9.3,F9.3)',zz(int(ny/2),k),pp(int(ny/2),k),&
          rho(int(ny/2),k),tt(int(ny/2),k),uu(int(ny/2),k),rh(int(ny/2),k),&
            qq(int(ny/2),k),th(int(ny/2),k),thv(int(ny/2),k),ttv(int(ny/2),k)
    enddo
end subroutine print_sounding2
!---------------------------------------------------------------------------


end module io
