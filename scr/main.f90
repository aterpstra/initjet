!-------------------------------------------------------------
! Main program for generating initial conditions 
!   for the idealized baroclinic wave test-case in WRFV3.4
!
! For more info see the README file and/or documentation.
! 
!	Annick Terpstra, 2013
!--------------------------------------------------------------

program main

USE const
USE io
USE init 
USE bc
USE jet
USE moist 
USE pert
USE func

implicit none

!fields for initial conditions
real(kind=8), allocatable, dimension(:,:,:) :: tt,ttv,rho,pp,uu,vv,rh,qq,th,thv    
real(kind=8), allocatable, dimension(:) :: ff !Hai:ff is the array of coriolis

!extra fields for user info
real(kind=8), allocatable, dimension(:,:) :: zz, sst

!fields for calculations of jet
real(kind=8), allocatable, dimension(:,:)   :: coeff,uu_jet,pp_jet,th_jet,rho_jet
real(kind=8), allocatable, dimension(:)     :: soll, ipiv
real(kind=8), allocatable, dimension(:)     :: p_vert,th_vert,rho_vert
integer :: info



!-------------------------------------------------------------------
call get_nml()		!read the namelist
call domainspec()	!calculate some domain specifics
call consistcheck()	!check initialization
!--------------------------------------------------------------------





if(.not.bouss)then
!*************************
!**** FULL TW-balance ****
!*************************
if(debug) print*,"method: full TW-balance"
!allocate space for calculations
allocate(uu_jet(ny,nz),pp_jet(ny,nz))
allocate(ff(ny), sst(nx,ny))
allocate(soll(ny*nz),coeff(ny*nz,ny*nz))
allocate(p_vert(nz),rho_vert(nz))	!vertical pressure profile
allocate(ipiv(ny*nz))	!extra array for pivoting...


!-------------------------------------------------------------------
call calc_corr(ff)!get coriolis 
call get_jet(uu_jet)	!obtain windfield
call get_bc_vert(p_vert,rho_vert)	!get the vertical boundary condition
call fill_matrix(coeff,soll,uu_jet,p_vert,ff)	!fill the matrix
call dgesv(ny*nz, 1, coeff, ny*nz, ipiv, soll, ny*nz, info)	!solve for pressure (LAPACK)
!----------------------------------------------------------------------

!***PRESSURE***
!retrieve pressure
do k=1,nz
	do j=1,ny
		pp_jet(j,k)=soll((k-1)*ny+j)
	enddo
enddo

if(debug) call print_profile_m(pp_jet,uu_jet,dz)

!clean up 
deallocate(soll,coeff,ipiv,p_vert)
allocate(pp(nx,ny,nz),uu(nx,ny,nz),rho(nx,ny,nz),tt(nx,ny,nz),th(nx,ny,nz))

!fill the 3D-fields for pp and uu
pp(1,:,:)=pp_jet(:,:)
uu(1,:,:)=uu_jet(:,:)
deallocate(pp_jet,uu_jet)

!***DENSITY***
! calculate density using hydrostatic equation
do k=2,nz-1
	do j=1,ny
		rho(1,j,k)=(pp(1,j,k+1)-pp(1,j,k-1))/(-2*dz*g)
	enddo
enddo

!density at top and bottom
!linear extrapolation, assumption: rho_surface=rho(j,2)+ 2*(rho(j,1.5)-rho(j,2))
do j=1,ny 
   	!bottom
   	rho(1,j,1)=(3D0*pp(1,j,1)-4D0*pp(1,j,2)+pp(1,j,3))/(2D0*dz*g)
	!top
	rho(1,j,nz)=(pp(1,j,nz-1)-pp(1,j,nz))/(dz*g)
	rho(1,j,nz)=rho(1,j,nz-1) + 2D0*(rho(1,j,nz)-rho(1,j,nz-1))   
enddo


!***TEMPERATURE***
!calculate temperature and potential temperature
tt(1,:,:)=pp(1,:,:)/(Rd*rho(1,:,:))
th(1,:,:)=tt(1,:,:)*(p00/pp(1,:,:))**(Rd/cp)




else	!create initial conditions using Boussinesq-approximation
if(debug) print*,"method: boussinesq"
!***************************
!**** BOUSSINESQ-APPROX ****
!***************************

!There could be/was some Boussinesq-way of creating intial conditions here.
!Too big of a mess. If needed please refrain to older versions, and implement clean version.

endif	!endif from choices: full TW-balance / Boussinesq-approx







!**************************************************************
!(1) **** MOISTURE***
!mind you: this automatically changes (potential) temperature in virtual (pot.) temp.
allocate(rh(nx,ny,nz))
if(add_moist)then
	call get_RH(rh(1,:,:))
else
	rh(1,:,:)=0.d0	!set to 0 if dry
endif


!**************************************************************
!(2) **** Meridional winds
allocate(vv(nx,ny,nz)) 
vv(1,:,:)=0.d0 !set vv to 0 initially


!-------------------------------------------------------------------
if(debug) call print_sounding(uu(1,:,:),pp(1,:,:),rho(1,:,:),tt(1,:,:),th(1,:,:),rh(1,:,:),dz)
!convert to 3D fields
call make_3D(pp,uu,rho,tt,th,rh,vv)


!**************************************************************
!(3) **** SST
call get_sst(sst,tt(:,:,1))
	if(debug) call print_corr_and_sst(sst,ff)

!**************************************************************
!(4) ****PERTURBATION*** 
if(add_pert) call get_pert(tt,th,uu,vv,rho,pp)






!-------------------------------------------------------------------
!generate output files
!first create the entire 3D-fields
allocate(thv(nx,ny,nz),ttv(nx,ny,nz),qq(nx,ny,nz),zz(ny,nz))
call calc_all_3D(tt,ttv,th,thv,qq,rh,pp,zz)


!write output for WRF
if(wrf_file) call write_wrf(uu,vv,th,rho,qq,ff,pp,sst)

!write output as .nc
if(nc_file) call write_nc(uu(P_nx,:,:),pp(P_nx,:,:),rho(P_nx,:,:),tt(P_nx,:,:),rh(P_nx,:,:), &
                          th(P_nx,:,:),thv(P_nx,:,:),ttv(P_nx,:,:),qq(P_nx,:,:),zz,ff,sst)


if(debug) call print_sounding2(uu(P_nx,:,:),pp(P_nx,:,:),rho(P_nx,:,:),tt(P_nx,:,:),&
	                       rh(P_nx,:,:),th(P_nx,:,:),thv(P_nx,:,:),ttv(P_nx,:,:),qq(P_nx,:,:),zz)


if(debug) print'(/A14)',"... done ..."




end program main
