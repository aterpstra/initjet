!IDEAL:MODEL_LAYER:INITIALIZATION

!  This MODULE holds the routines which are used to perform various initializations
!  for the individual domains.  

!-----------------------------------------------------------------------

MODULE module_initialize_ideal

   USE module_domain
   USE module_io_domain
   USE module_state_description
   USE module_model_constants
   USE module_bc
   USE module_timing
   USE module_configure
   USE module_init_utilities
   USE module_soil_pre
#ifdef DM_PARALLEL
   USE module_dm
#endif
   CHARACTER (LEN=256) , PRIVATE :: a_message


CONTAINS


!-------------------------------------------------------------------
! this is a wrapper for the solver-specific init_domain routines.
! Also dereferences the grid variables and passes them down as arguments.
! This is crucial, since the lower level routines may do message passing
! and this will get fouled up on machines that insist on passing down
! copies of assumed-shape arrays (by passing down as arguments, the 
! data are treated as assumed-size -- ie. f77 -- arrays and the copying
! business is avoided).  Fie on the F90 designers.  Fie and a pox.

   SUBROUTINE init_domain ( grid )

   IMPLICIT NONE

   !  Input data.
   TYPE (domain), POINTER :: grid 
   !  Local data.
   INTEGER :: idum1, idum2

   CALL set_scalar_indices_from_config ( head_grid%id , idum1, idum2 )

     CALL init_domain_rk( grid &
!
#include "actual_new_args.inc"
!
                        )

   END SUBROUTINE init_domain

!-------------------------------------------------------------------

   SUBROUTINE init_domain_rk ( grid &
!
# include "dummy_new_args.inc"
!
)
   IMPLICIT NONE

   !  Input data.
   TYPE (domain), POINTER :: grid

# include "dummy_decl.inc"

   TYPE (grid_config_rec_type)              :: config_flags

   !  Local data
   INTEGER                             ::                       &
                                  ids, ide, jds, jde, kds, kde, &
                                  ims, ime, jms, jme, kms, kme, &
                                  its, ite, jts, jte, kts, kte, &
                                  i, j, k

   ! Local data

   INTEGER, PARAMETER :: nl_max = 1000
   REAL, DIMENSION(nl_max) :: zk, p_in, theta, rho_local, u, v, qv, pd_in
   INTEGER :: nl_in

   INTEGER :: icm,jcm, ii, im1, jj, jm1, loop, error, fid
   REAL    :: u_mean,v_mean, f0, p_surf, p_level, qvf, z_at_v, z_at_u
   REAL    :: z_scale, xrad, yrad, zrad, rad, delt, cof1, cof2
!   REAL, EXTERNAL :: interp_0
   REAL    :: hm
   REAL    :: pi

!  stuff from original initialization that has been dropped from the Registry 
   REAL    :: vnu, xnu, xnus, dinit0, cbh, p0_temp, t0_temp, zd, zt
   REAL    :: qvf1, qvf2, pd_surf
   INTEGER :: it

   LOGICAL :: moisture_init
   LOGICAL :: stretch_grid, dry_sounding, debug, D3_data
  character (len=256) :: mminlu2

!AT additional parameter for loop over soil-layers
  INTEGER :: l

  

!!!======================================================================
!AT: INPUT_JET PARAMETERS +MG: xice_switch
   INTEGER :: nz_jet,ny_jet,nx_jet   
   REAL :: sst_diff, dz, f_jet

   LOGICAL :: add_seaice
   LOGICAL :: usr_def_etalev

   REAL, allocatable, dimension(:,:)  ::u2D, v2D, rho_loc2D, th2D, z_jet, qv2D, sst2D
   REAL, allocatable, dimension(:)  :: ff_1D
   REAL, allocatable, dimension(:,:,:)::v_jet3D, u_jet3D, rho_loc_jet3D, th_jet3D, qv_jet3D
!!!======================================================================

!  kludge space for initial jet
 !  REAL, DIMENSION(nz_jet, ny_jet) :: u_jet, rho_loc_jet, th_jet, z_jet, rh_jet
 
 !  REAL, DIMENSION(nz_jet, ny_jet) :: u2D, v2D, rho_loc2D, th2D, z_jet, rh2D
 !  REAL, DIMENSION(nz_jet, ny_jet, nx_jet) :: v_jet3D, u_jet3D, rho_loc_jet3D, th_jet3D, rh_jet3D
  
   REAL :: piov2, tp, tp1
   INTEGER :: icen, jcen
   real :: thtmp, ptmp, temp(3)

	!get the settings from the namelist
	CALL nl_get_nz_input(1,nz_jet)
	CALL nl_get_ny_input(1,ny_jet)
	CALL nl_get_nx_input(1,nx_jet)
	CALL nl_get_dz_input(1,dz)
	CALL nl_get_sst_t0_diff(1,sst_diff)
	CALL nl_get_f_jet(1,f_jet)
  CALL nl_get_add_seaice(1,add_seaice)
  CALL nl_get_usr_def_etalev(1,usr_def_etalev)

	!allocate the space for the initial jet
	allocate(u2D(nz_jet,ny_jet))
	allocate(v2D(nz_jet,ny_jet))
	allocate(rho_loc2D(nz_jet,ny_jet))
	allocate(th2D(nz_jet,ny_jet))
	allocate(z_jet(nz_jet,ny_jet))
	allocate(qv2D(nz_jet,ny_jet))
	allocate(v_jet3D(nz_jet,ny_jet,nx_jet))
	allocate(u_jet3D(nz_jet,ny_jet,nx_jet))
	allocate(rho_loc_jet3D(nz_jet,ny_jet,nx_jet))
	allocate(th_jet3D(nz_jet,ny_jet,nx_jet))
	allocate(qv_jet3D(nz_jet,ny_jet,nx_jet))
	allocate(ff_1D(ny_jet))
	allocate(sst2D(ny_jet,nx_jet))

!also need to deallocate one day...!!

   SELECT CASE ( model_data_order )
         CASE ( DATA_ORDER_ZXY )
   kds = grid%sd31 ; kde = grid%ed31 ;
   ids = grid%sd32 ; ide = grid%ed32 ;
   jds = grid%sd33 ; jde = grid%ed33 ;

   kms = grid%sm31 ; kme = grid%em31 ;
   ims = grid%sm32 ; ime = grid%em32 ;
   jms = grid%sm33 ; jme = grid%em33 ;

   kts = grid%sp31 ; kte = grid%ep31 ;   ! note that tile is entire patch
   its = grid%sp32 ; ite = grid%ep32 ;   ! note that tile is entire patch
   jts = grid%sp33 ; jte = grid%ep33 ;   ! note that tile is entire patch
         CASE ( DATA_ORDER_XYZ )
   ids = grid%sd31 ; ide = grid%ed31 ;
   jds = grid%sd32 ; jde = grid%ed32 ;
   kds = grid%sd33 ; kde = grid%ed33 ;

   ims = grid%sm31 ; ime = grid%em31 ;
   jms = grid%sm32 ; jme = grid%em32 ;
   kms = grid%sm33 ; kme = grid%em33 ;

   its = grid%sp31 ; ite = grid%ep31 ;   ! note that tile is entire patch
   jts = grid%sp32 ; jte = grid%ep32 ;   ! note that tile is entire patch
   kts = grid%sp33 ; kte = grid%ep33 ;   ! note that tile is entire patch
         CASE ( DATA_ORDER_XZY )
   ids = grid%sd31 ; ide = grid%ed31 ;
   kds = grid%sd32 ; kde = grid%ed32 ;
   jds = grid%sd33 ; jde = grid%ed33 ;

   ims = grid%sm31 ; ime = grid%em31 ;
   kms = grid%sm32 ; kme = grid%em32 ;
   jms = grid%sm33 ; jme = grid%em33 ;

   its = grid%sp31 ; ite = grid%ep31 ;   ! note that tile is entire patch
   kts = grid%sp32 ; kte = grid%ep32 ;   ! note that tile is entire patch
   jts = grid%sp33 ; jte = grid%ep33 ;   ! note that tile is entire patch

   END SELECT

   piov2 = 2.*atan(1.0)
   icen = ide/4
   jcen = jde/2

   stretch_grid = .false.
   delt = 0.
   z_scale = .50
   pi = 2.*asin(1.0)
   write(a_message,*) ' pi is ',pi
   call wrf_message(a_message)


   CALL model_to_grid_config_rec ( grid%id , model_config_rec , config_flags )

! here we check to see if the boundary conditions are set properly

   CALL boundary_condition_check( config_flags, bdyzone, error, grid%id )

   moisture_init = .true.

    grid%itimestep=0

#ifdef DM_PARALLEL
   CALL wrf_dm_bcast_bytes( icm , IWORDSIZE )
   CALL wrf_dm_bcast_bytes( jcm , IWORDSIZE )
#endif

!AT: we add the USGS for using LSM/PBL schemes
    mminlu2 = ' '
    mminlu2(1:4) = 'USGS'
    CALL nl_set_mminlu(1, mminlu2)
!    CALL nl_set_mminlu(1,'    ')
	CALL nl_set_iswater(1,16)
!    CALL nl_set_iswater(1,0)
	  CALL nl_set_isice(1,3)
! Need to change the lat,lon settings if using a radiation scheme
    CALL nl_set_cen_lat(1,70.)
   ! CALL nl_set_cen_lat(1,45.)
    CALL nl_set_cen_lon(1,0.)
    CALL nl_set_truelat1(1,0.)
    CALL nl_set_truelat2(1,0.)
    CALL nl_set_moad_cen_lat (1,0.)
    CALL nl_set_stand_lon (1,0.)
    CALL nl_set_pole_lon (1,0.)
    CALL nl_set_pole_lat (1,90.)
    CALL nl_set_map_proj(1,0)
    CALL nl_get_iswater(1,grid%iswater)

!  here we initialize data we currently is not initialized 
!  in the input data

    DO j = jts, jte
      DO i = its, ite

         grid%ht(i,j)       = 0.
         grid%msftx(i,j)    = 1.
         grid%msfty(i,j)    = 1.
         grid%msfux(i,j)    = 1.
         grid%msfuy(i,j)    = 1.
         grid%msfvx(i,j)    = 1.
         grid%msfvx_inv(i,j)= 1.
         grid%msfvy(i,j)    = 1.
         grid%sina(i,j)     = 0.
         grid%cosa(i,j)     = 1.
         grid%e(i,j)        = 0.
         grid%f(i,j)        = f_jet	!1.36e-04!1.0e-4!	!AT coriolis at 70N
!AT: ocean configuration
		! grid%xland(i,j)    = 2.    !land=1, water=2
		! grid%lu_index(i,j) = 16       !16=water body (18?? for land)
      END DO
   END DO

    DO j = jts, jte
    DO k = kts, kte
      DO i = its, ite
         grid%ww(i,k,j)     = 0.
      END DO
   END DO
   END DO

   grid%step_number = 0

! set up the grid

  IF(usr_def_etalev)THEN !AT: use user defined eta-levels in namelist.input
       print*,"user defined eta-levels" 
     DO k=1, kde
   grid%znw(k) = model_config_rec%eta_levels(k)
     ENDDO
  ELSE
   IF (stretch_grid) THEN ! exponential stretch for eta (nearly constant dz)
     DO k=1, kde
      grid%znw(k) = (exp(-(k-1)/float(kde-1)/z_scale) - exp(-1./z_scale))/ &
                                (1.-exp(-1./z_scale))
     ENDDO
   ELSE
     DO k=1, kde
      grid%znw(k) = 1. - float(k-1)/float(kde-1)
     ENDDO
   ENDIF
  ENDIF

   DO k=1, kde-1
    grid%dnw(k) = grid%znw(k+1) - grid%znw(k)
    grid%rdnw(k) = 1./grid%dnw(k)
    grid%znu(k) = 0.5*(grid%znw(k+1)+grid%znw(k))
   ENDDO

  
   DO k=2, kde-1
    grid%dn(k) = 0.5*(grid%dnw(k)+grid%dnw(k-1))
    grid%rdn(k) = 1./grid%dn(k)
    grid%fnp(k) = .5* grid%dnw(k  )/grid%dn(k)
    grid%fnm(k) = .5* grid%dnw(k-1)/grid%dn(k)
   ENDDO

   cof1 = (2.*grid%dn(2)+grid%dn(3))/(grid%dn(2)+grid%dn(3))*grid%dnw(1)/grid%dn(2) 
   cof2 =     grid%dn(2)        /(grid%dn(2)+grid%dn(3))*grid%dnw(1)/grid%dn(3) 
   grid%cf1  = grid%fnp(2) + cof1
   grid%cf2  = grid%fnm(2) - cof1 - cof2
   grid%cf3  = cof2       

   grid%cfn  = (.5*grid%dnw(kde-1)+grid%dn(kde-1))/grid%dn(kde-1)
   grid%cfn1 = -.5*grid%dnw(kde-1)/grid%dn(kde-1)
   grid%rdx = 1./config_flags%dx
   grid%rdy = 1./config_flags%dy

!  get the sounding from the ascii sounding file, first get dry sounding and 
!  calculate base state

  write(6,*) ' reading input jet sounding '
!  call read_input_jet( u_jet, rho_loc_jet, th_jet, z_jet, nz_jet, ny_jet, rh_jet, dz)
!AT: read 3D input_jet
  call read_input_jet( u_jet3D, v_jet3D, th_jet3D,  rho_loc_jet3D, qv_jet3D,ff_1D, sst2D, z_jet, nz_jet, ny_jet, nx_jet, dz )


!--Hai: update coriolis parameters
 ! write(*,*)"Check",its,ite,jts,jte

    DO j = jts, jte
      DO i = its, ite
         grid%f(i,j)        = ff_1D(j) 
      END DO
   END DO

 ! write(*,*)'j,f'
 ! Do j=jts,jte
 !    write(*,*) j,grid%f(1,j)
 ! Enddo

  write(6,*) ' getting dry sounding for base state '
  write(6,*) ' using middle column in jet sounding, j = ',ny_jet/2
 
  !AT: using middle sounding for basic state 
  !mind you: could be at perturbation location, maybe not a good idea as its used for ptop...
    u2D  = u_jet3D(:,:,nx_jet/2)
    v2D  = v_jet3D(:,:,nx_jet/2)
    th2D = th_jet3D(:,:,nx_jet/2)
    rho_loc2D= rho_loc_jet3D(:,:,nx_jet/2)
    qv2D = qv_jet3D(:,:,nx_jet/2)
    
    
  dry_sounding   = .true.
  debug = .true.  !  this will produce print of the sounding
  D3_data = .true.
 ! CALL get_sounding( zk, p_in, pd_in, theta, rho_local, u, v, qv, dry_sounding, &
  !                    nl_max, nl_in, u_jet, rho_loc_jet, th_jet, z_jet, rh_jet,    &
   !                   nz_jet, ny_jet, ny_jet/2, debug                   )
 
  CALL get_sounding( zk, p_in, pd_in, theta, rho_local, u, v, qv, dry_sounding, &
   nl_max, nl_in, u2D, v2D, th2D, rho_loc2D, & 
   qv2D, z_jet, nz_jet, ny_jet, ny_jet/2, debug, D3_data)
  write(6,*) ' returned from reading sounding, nl_in is ',nl_in

!  find ptop for the desired ztop (ztop is input from the namelist),
!  and find surface pressure

!  For the jet, using the middle column for the base state means that
!  we will be extrapolating above the highest height data to the south
!  of the centerline.

  grid%p_top = interp_0( p_in, zk, config_flags%ztop, nl_in )

  DO j=jts,jte
  DO i=its,ite  ! flat surface
    grid%phb(i,1,j) = 0.
    grid%php(i,1,j) = 0.
    grid%ph0(i,1,j) = 0.
    grid%ht(i,j) = 0.
  ENDDO
  ENDDO

  DO J = jts, jte
  DO I = its, ite

    p_surf = interp_0( p_in, zk, grid%phb(i,1,j)/g, nl_in )
    grid%mub(i,j) = p_surf-grid%p_top

!  this is dry hydrostatic sounding (base state), so given grid%p (coordinate),
!  interp theta (from interp) and compute 1/rho_loc from eqn. of state

    DO K = 1, kte-1
      p_level = grid%znu(k)*(p_surf - grid%p_top) + grid%p_top
      grid%pb(i,k,j) = p_level
      grid%t_init(i,k,j) = interp_0( theta, p_in, p_level, nl_in ) - t0
      grid%alb(i,k,j) = (r_d/p1000mb)*(grid%t_init(i,k,j)+t0)*(grid%pb(i,k,j)/p1000mb)**cvpm
    ENDDO

!  calc hydrostatic balance (alternatively we could interp the geopotential from the
!  sounding, but this assures that the base state is in exact hydrostatic balance with
!  respect to the model eqns.

    DO k  = 2,kte
      grid%phb(i,k,j) = grid%phb(i,k-1,j) - grid%dnw(k-1)*grid%mub(i,j)*grid%alb(i,k-1,j)
    ENDDO

  ENDDO
  ENDDO

  write(6,*) ' ptop is ',grid%p_top
  write(6,*) ' base state grid%mub(1,1), p_surf is ',grid%mub(1,1),grid%mub(1,1)+grid%p_top

!  calculate full state for each column - this includes moisture.

  write(6,*) ' getting grid%moist sounding for full state '

  dry_sounding = .true.
  IF (config_flags%mp_physics /= 0)  dry_sounding = .false.

  DO J = jts, min(jde-1,jte)

!  get sounding for this point

  debug = .false.  !  this will turn off print of the sounding
!  CALL get_sounding( zk, p_in, pd_in, theta, rho_loc, u, v, qv, dry_sounding, &
 !                     nl_max, nl_in, u_jet, rho_loc_jet, th_jet, z_jet, rh_jet,    &
  !                    nz_jet, ny_jet, j, debug                          )

  DO I = its, min(ide-1,ite)

! IB: get the updated "curtains" from input file for all domain positions:
  th2D = th_jet3D(:,:,i)
  u2D  = u_jet3D(:,:,i)
  rho_loc2D= rho_loc_jet3D(:,:,i)
  v2D  = v_jet3D(:,:,i)
  qv2D = qv_jet3D(:,:,i)
  CALL get_sounding( zk, p_in, pd_in, theta, rho_local, u, v, qv, dry_sounding, &
       nl_max, nl_in, u2D, v2D, th2D, rho_loc2D, qv2D, z_jet,	 &
       nz_jet, ny_jet, j, debug, D3_data			)


!   we could just do the first point in "i" and copy from there, but we'll
!   be lazy and do all the points as if they are all, independent

!   At this point grid%p_top is already set. find the DRY mass in the column 
!   by interpolating the DRY pressure.  

    pd_surf = interp_0( pd_in, zk, grid%phb(i,1,j)/g, nl_in )

!   compute the perturbation mass and the full mass

    grid%mu_1(i,j) = pd_surf-grid%p_top - grid%mub(i,j)
    grid%mu_2(i,j) = grid%mu_1(i,j)
    grid%mu0(i,j) = grid%mu_1(i,j) + grid%mub(i,j)

!   given the dry pressure and coordinate system, interp the potential
!   temperature and qv

    do k=1,kde-1

      p_level = grid%znu(k)*(pd_surf - grid%p_top) + grid%p_top

      grid%moist(i,k,j,P_QV) = interp_0( qv, pd_in, p_level, nl_in )
      grid%t_1(i,k,j)          = interp_0( theta, pd_in, p_level, nl_in ) - t0
      grid%t_2(i,k,j)          = grid%t_1(i,k,j)
      

    enddo

!   integrate the hydrostatic equation (from the RHS of the bigstep
!   vertical momentum equation) down from the top to get grid%p.
!   first from the top of the model to the top pressure

    k = kte-1  ! top level

    qvf1 = 0.5*(grid%moist(i,k,j,P_QV)+grid%moist(i,k,j,P_QV))
    qvf2 = 1./(1.+qvf1)
    qvf1 = qvf1*qvf2

!    grid%p(i,k,j) = - 0.5*grid%mu_1(i,j)/grid%rdnw(k)
    grid%p(i,k,j) = - 0.5*(grid%mu_1(i,j)+qvf1*grid%mub(i,j))/grid%rdnw(k)/qvf2
    qvf = 1. + rvovrd*grid%moist(i,k,j,P_QV)
    grid%alt(i,k,j) = (r_d/p1000mb)*(grid%t_1(i,k,j)+t0)*qvf* &
                (((grid%p(i,k,j)+grid%pb(i,k,j))/p1000mb)**cvpm)
    grid%al(i,k,j) = grid%alt(i,k,j) - grid%alb(i,k,j)

!  down the column

    do k=kte-2,1,-1
      qvf1 = 0.5*(grid%moist(i,k,j,P_QV)+grid%moist(i,k+1,j,P_QV))
      qvf2 = 1./(1.+qvf1)
      qvf1 = qvf1*qvf2
      grid%p(i,k,j) = grid%p(i,k+1,j) - (grid%mu_1(i,j) + qvf1*grid%mub(i,j))/qvf2/grid%rdn(k+1)
      qvf = 1. + rvovrd*grid%moist(i,k,j,P_QV)
      grid%alt(i,k,j) = (r_d/p1000mb)*(grid%t_1(i,k,j)+t0)*qvf* &
                  (((grid%p(i,k,j)+grid%pb(i,k,j))/p1000mb)**cvpm)
      grid%al(i,k,j) = grid%alt(i,k,j) - grid%alb(i,k,j)
    enddo

!  this is the hydrostatic equation used in the model after the
!  small timesteps.  In the model, grid%al (inverse density)
!  is computed from the geopotential.


    grid%ph_1(i,1,j) = 0.
    DO k  = 2,kte
      grid%ph_1(i,k,j) = grid%ph_1(i,k-1,j) - (grid%dnw(k-1))*(       &
                   (grid%mub(i,j)+grid%mu_1(i,j))*grid%al(i,k-1,j)+ &
                    grid%mu_1(i,j)*grid%alb(i,k-1,j)  )
                                                   
      grid%ph_2(i,k,j) = grid%ph_1(i,k,j) 
      grid%ph0(i,k,j) = grid%ph_1(i,k,j) + grid%phb(i,k,j)
    ENDDO

! interp u and v

    DO K = 1, kte
      p_level = grid%znu(k)*(p_surf - grid%p_top) + grid%p_top
      grid%u_1(i,k,j) = interp_0( u, p_in, p_level, nl_in )
      grid%u_2(i,k,j) = grid%u_1(i,k,j)
      grid%v_1(i,k,j) = interp_0( v, p_in, p_level, nl_in )
      grid%v_2(i,k,j) = grid%v_1(i,k,j)
    ENDDO


! AT: Also just set some other surface diagnostic variables for checking the data (now z=0(m))
!	set the 'surface' variables to the surface values of the initialization jet
!	these are updated by the model after the initialization, so this is just for the wrfinput_d01
   grid%psfc(i,j)=p_in(1)
   grid%u10(i,j)=u(1)
   grid%v10(i,j)=v(1)
   grid%q2(i,j)=qv(1)
   grid%th2(i,j)=theta(1)
!   grid%t2(i,j)=theta(1)*(100000.0/p_in(1))**(r_d/cp)/(1+0.61*qv(1))
   grid%t2(i,j)=theta(1)*(100000.0/p_in(1))**(r_d/cp)
  ENDDO
  ENDDO



!  rebalance hydrostatically
 DO J = jts, min(jde-1,jte)
    DO I = its, min(ide-1,ite)
      DO k  = 2,kte
        grid%ph_1(i,k,j) = grid%ph_1(i,k-1,j) - (1./grid%rdnw(k-1))*(       &
                     (grid%mub(i,j)+grid%mu_1(i,j))*grid%al(i,k-1,j)+ &
                      grid%mu_1(i,j)*grid%alb(i,k-1,j)  )
                                                   
        grid%ph_2(i,k,j) = grid%ph_1(i,k,j) 
        grid%ph0(i,k,j) = grid%ph_1(i,k,j) + grid%phb(i,k,j)
      ENDDO
	ENDDO
 ENDDO

 

! set v

!  DO J = jts, jte
!  DO I = its, min(ide-1,ite)

!    DO K = 1, kte
!      grid%v_1(i,k,j) = 0.
!      grid%v_2(i,k,j) = grid%v_1(i,k,j)
!    ENDDO

!  ENDDO
!  ENDDO

!  fill out last i row for u

  DO J = jts, min(jde-1,jte)
  DO I = ite, ite

    DO K = 1, kte
      grid%u_1(i,k,j) = grid%u_1(its,k,j)
      grid%u_2(i,k,j) = grid%u_2(its,k,j)
    ENDDO

  ENDDO
  ENDDO

!  set w

  DO J = jts, min(jde-1,jte)
  DO K = kts, kte
  DO I = its, min(ide-1,ite)
    grid%w_1(i,k,j) = 0.
    grid%w_2(i,k,j) = 0.
  ENDDO
  ENDDO
  ENDDO

!  set a few more things

  DO J = jts, min(jde-1,jte)
  DO K = kts, kte-1
  DO I = its, min(ide-1,ite)
    grid%h_diabatic(i,k,j) = 0.
  ENDDO
  ENDDO
  ENDDO

  DO k=1,kte-1
    grid%t_base(k) = grid%t_1(1,k,1)
    grid%qv_base(k) = grid%moist(1,k,1,P_QV)
    grid%u_base(k) = grid%u_1(1,k,1)
    grid%v_base(k) = grid%v_1(1,k,1)
    !AT For some funny reason grid%z_base is not added to the baroclinic channel, but without it the Raleigh damping is not functioning...
    grid%z_base(k) = 0.5*(grid%phb(1,k,1)+grid%phb(1,k+1,1)+grid%ph_1(1,k,1)+grid%ph_1(1,k+1,1))/g
  ENDDO

!====================================
!Lower Boundary Conditions
!------------------------------------
!   Annick Terpstra, 2013
!
! 1. define SST, based on Tair@surface and offsett (sst_diff)
! 2. define sea-ice(XICE)/ocean(SST) values
!
! 3. based on xland-flag, initialize other variables
! 4. call process_soil_ideal
!    
!------------------------------------


!HAS TO BE CALLED BEFORE PROCESSING THE SOIL!!
!AT: setting the SST and SSTskin
  print*,'setting SST'
  DO J = jts, min(jde-1,jte)
  DO I = its, min(ide-1,ite)	
     grid%xland(i,j)=2. !ocean points
!	   grid%sst(i,j)=grid%t_1(1,1,j)+300+sst_diff!make the SST same as lowest temperature (not at the location of the perturbation) and add/substract a uniform T(air)-SST difference.
	   grid%sst(i,j) = sst2D(j,i)	!Why reverse these values??
      !     if (i.eq.its) then
       !       write(*,*) j,grid%sst(its,j)
        !   endif

	   grid%sstsk(i,j)=grid%sst(i,j) !set the sst-skin temperature
	   grid%tsk(I,J)=grid%sst(I,J) !   => mind you: tsk is NOT updated over water surfaces, instead sstsk is used?
	   grid%tmn(I,J)=grid%tsk(I,J)-0.5	!tmn=soil temp @ lower boundary, probably not called over the ocean but set for possible ice configuration
  ENDDO
  ENDDO
if(add_seaice)then
!AT: setting fractional-seaice
!SEAICE=1/0 (ice/no-ice flag), XICE=0.0-1.0 (fractional seaice)
  print*,'setting SEAICE'
  !AT: Note that these setting result in a constant skin-temperature both over ocean and sea-ice
  DO J = jts, min(jde-1,jte)
  DO I = its, min(ide-1,ite)  
    !if(J.lt.ny_jet/2)then !southern part of domain
      if(I.lt.nx_jet/2)then !western part of domain
      !sea-ice (land)
      grid%xland(i,j)=1   !land
      grid%xice(i,j)=0.7  !set the fractional-sea-ice
      grid%sst(i,j)=271.46 !freezing point of salt-water
      grid%sstsk(i,j)=grid%sst(i,j)
      grid%tsk(I,J)=255.0  
      !grid%tsk(I,J)=grid%t_1(1,1,j)+300  !use for non-constant skin-temperature
      grid%tmn(I,J)=grid%sst(i,j) !bottom of ice= freezing point of salt-water
      else
      !ocean
      grid%xland(i,j)=2.     !water
      grid%sst(i,j)=273.0
      grid%sstsk(i,j)=grid%sst(i,j)
      grid%tsk(I,J)=grid%sst(I,J)
      grid%tmn(I,J)=grid%tsk(I,J)-0.5 
      endif
  ENDDO
  ENDDO
endif


! AT: added for possible use of LSM and PBL parameterizations
   other_masked_fields : SELECT CASE ( model_config_rec%sf_surface_physics(grid%id) )

      CASE (SLABSCHEME)

      CASE (LSMSCHEME)
        !called for Noah LSM
        DO j = jts , MIN(jde-1,jte)
           DO i = its , MIN(ide-1,ite)
              IF (grid%xland(i,j) .lt. 1.5) THEN !over land (ice)
                 grid%lu_index(i,j)=24
                 grid%landmask(i,j)=1.
                 grid%vegfra(i,j) = 0.
                 grid%canwat(i,j) = 0.
                 grid%ivgtyp(i,j) = 24
                 grid%isltyp(i,j) = 24
                 grid%snow(i,j) = 0.
            !MG: set the TSLB (soil temperature) layers to a linar gradient in the ice between TSK and TMN
            !and initialise soil moisture
                DO l = 1 , model_config_rec%num_soil_layers
                    grid%smois(i,l,j)=1.
                  if(l==1)then
                    grid%tslb(i,l,j) = grid%tsk(i,j) !top soil = Tair at surface; bottom soil = Tfreezing
                  else
                    grid%tslb(i,l,j) = grid%tslb(i,l-1,j) + abs(grid%tsk(i,j)-grid%tmn(i,j))/3 
                  endif
                ENDDO
              ELSE !over ocean
                 grid%landmask(i,j)=2.
                 grid%lu_index(i,j)=16 !water bodies
                 grid%vegfra(i,j) = 0.
                 grid%canwat(i,j) = 0.
                 grid%ivgtyp(i,j) = 16
                 grid%isltyp(i,j) = 16
                 grid%xice(i,j) = 0.
                 grid%snow(i,j) = 0.
              ENDIF
           END DO
        END DO

      CASE (RUCLSMSCHEME)

   END SELECT other_masked_fields


! Process the soil; note that there are some things hard-wired into share/module_soil_pre.F
      CALL process_soil_ideal(grid%xland,grid%xice,grid%vegfra,grid%snow,grid%canwat, &
                     grid%ivgtyp,grid%isltyp,grid%tslb,grid%smois, &
                     grid%tsk,grid%tmn,grid%zs,grid%dzs,model_config_rec%num_soil_layers, &
                     model_config_rec%sf_surface_physics(grid%id), &
                                   ids,ide, jds,jde, kds,kde,&
                                   ims,ime, jms,jme, kms,kme,&
                                   its,ite, jts,jte, kts,kte )



  





  RETURN

 END SUBROUTINE init_domain_rk

!---------------------------------------------------------------------

 SUBROUTINE init_module_initialize
 END SUBROUTINE init_module_initialize

!---------------------------------------------------------------------
#if 0
! TEST DRIVER FOR "read_input_jet" and "get_sounding"
  implicit none 
  integer, parameter :: nz_jet=64, ny_jet=80
  real, dimension(nz_jet,ny_jet) :: u_jet, rho_loc_jet, &
                                    th_jet, z_jet

  real, dimension(nz_jet,ny_jet) :: zk,p,p_dry,theta,rho_local,u,v,qv
  logical :: dry, debug
  integer :: j, nl

  call read_input_jet( u_jet, rho_loc_jet, th_jet, qv_jet, z_jet, nz_jet, ny_jet )

  call opngks
  call parray( u_jet, nz_jet, ny_jet)
  call parray( rho_loc_jet, nz_jet, ny_jet)
  call parray( th_jet, nz_jet, ny_jet)
!  call clsgks

!  set up initial jet

  debug = .true.
  dry = .true.
  do j=1,ny_jet

    call get_sounding( zk(:,j),p(:,j),p_dry(:,j),theta(:,j),      &
                       rho_local(:,j),u(:,j), v(:,j),  qv(:,j),        &
                       dry, nz_jet, nl, u_jet, rho_loc_jet, th_jet,  &
                       z_jet, nz_jet, ny_jet, j, debug          )
    debug = .false.

  enddo

  write(6,*) ' lowest level p, th, and rho_local, highest level p '

  do j=1,ny_jet
    write(6,*) j, p(1,j),theta(1,j),rho_local(1,j), p(nz_jet,j)
!    write(6,*) j, p(1,j),theta(1,j)-th_jet(1,j),rho_local(1,j)-rho_loc_jet(1,j)
  enddo

  call parray( p, nz_jet, ny_jet)
  call parray( p_dry, nz_jet, ny_jet)
  call parray( theta, nz_jet, ny_jet)

  call clsgks

  end

!---------------------------------

      subroutine parray(a,m,n)
      dimension a(m,n)
      dimension b(n,m)

    do i=1,m
    do j=1,n
      b(j,i) = a(i,j)
    enddo
    enddo
      
      write(6,'(''  dimensions m,n  '',2i6)')m,n
        call set(.05,.95,.05,.95,0.,1.,0.,1.,1)
        call perim(4,5,4,5)
        call setusv('LW',2000)
!        CALL CONREC(a,m,m,n,cmax,cmin,cinc,-1,-638,-922)
        CALL CONREC(b,n,n,m,0.,0.,0.,-1,-638,-922)
        call frame
      return
      end

! END TEST DRIVER FOR "read_input_jet" and "get_sounding"
#endif

!------------------------------------------------------------------

    !subroutine get_sounding( zk, p, p_dry, theta, rho_local,       &
     !                        u, v, qv, dry, nl_max, nl_in,  &
      !                       u_jet, rho_loc_jet, th_jet, z_jet, rh_jet, &
       !                      nz_jet, ny_jet, j_point, debug )
    
     subroutine get_sounding( zk, p, p_dry, theta, rho_local,       &
                             u, v, qv, dry, nl_max, nl_in,  &
                             u_jet, v_jet,  rho_loc_jet,th_jet, qv_jet, z_jet, &
                             nz_jet, ny_jet, j_point, debug, D3_data )

    
    
    implicit none

    integer nl_max, nl_in
    real zk(nl_max), p(nl_max), theta(nl_max), rho_local(nl_max), &
         u(nl_max), v(nl_max), qv(nl_max), p_dry(nl_max)
    logical dry, p_sound

    integer nz_jet, ny_jet, j_point
    real, dimension(nz_jet, ny_jet) :: u_jet, rho_loc_jet, th_jet, z_jet, qv_jet, v_jet

    integer n
    parameter(n=1000)
    logical debug, D3_data

! input sounding data

    real p_surf, th_surf, qv_surf
    real pi_surf, pi(n)
    real h_input(n), th_input(n), qv_input(n), u_input(n), v_input(n)

! diagnostics

    real rho_loc_surf, p_input(n), rho_loc_input(n)
    real pm_input(n)  !  this are for full moist sounding

! local data

    real r
    parameter (r = r_d)
    integer k, it, nl
    real qvf, qvf1, dz

!  first, read the sounding

!    call read_sounding( p_surf, th_surf, qv_surf, &
!                          h_input, th_input, qv_input, u_input, v_input,n, nl, debug )

!   call calc_jet_sounding( p_surf, th_surf, qv_surf,                             &
 !                          h_input, th_input, qv_input, u_input, v_input,        &
  !                         n, nl, debug, u_jet, rho_loc_jet, th_jet, z_jet, rh_jet, j_point, &
   !                        nz_jet, ny_jet, dry                                  )

	call calc_jet_sounding( p_surf, th_surf, qv_surf,                             &
                           h_input, th_input, qv_input, u_input, v_input,        &
                           n, nl, debug, u_jet,v_jet, rho_loc_jet, th_jet, qv_jet, z_jet, j_point, &
                           nz_jet, ny_jet, dry                                 )


   nl = nz_jet

    if(dry) then
     do k=1,nl
       qv_input(k) = 0.
     enddo
    endif

    if(debug) write(6,*) ' number of input levels = ',nl

      nl_in = nl
      if(nl_in .gt. nl_max ) then
        write(6,*) ' too many levels for input arrays ',nl_in,nl_max
        call wrf_error_fatal ( ' too many levels for input arrays ' )
      end if

!  compute diagnostics,
!  first, convert qv(g/kg) to qv(g/g)
!
!      do k=1,nl
!        qv_input(k) = 0.001*qv_input(k)
!      enddo
!      p_surf = 100.*p_surf  ! convert to pascals

    qvf = 1. + rvovrd*qv_input(1) 
    rho_loc_surf = 1./((r/p1000mb)*th_surf*qvf*((p_surf/p1000mb)**cvpm))
    pi_surf = (p_surf/p1000mb)**(r/cp)

    if(debug) then
      write(6,*) ' surface density is ',rho_loc_surf
      write(6,*) ' surface pi is    ',pi_surf
    end if


!  integrate moist sounding hydrostatically, starting from the
!  specified surface pressure
!  -> first, integrate from surface to lowest level

        qvf = 1. + rvovrd*qv_input(1) 
        qvf1 = 1. + qv_input(1)
        rho_loc_input(1) = rho_loc_surf
        dz = h_input(1)
        do it=1,10
          pm_input(1) = p_surf &
                  - 0.5*dz*(rho_loc_surf+rho_loc_input(1))*g*qvf1
          rho_loc_input(1) = 1./((r/p1000mb)*th_input(1)*qvf*((pm_input(1)/p1000mb)**cvpm))
        enddo

! integrate up the column

        do k=2,nl
          rho_loc_input(k) = rho_loc_input(k-1)
          dz = h_input(k)-h_input(k-1)
          qvf1 = 0.5*(2.+(qv_input(k-1)+qv_input(k)))
          qvf = 1. + rvovrd*qv_input(k)   ! qv is in g/kg here
 
          do it=1,10
            pm_input(k) = pm_input(k-1) &
                    - 0.5*dz*(rho_loc_input(k)+rho_loc_input(k-1))*g*qvf1
            rho_loc_input(k) = 1./((r/p1000mb)*th_input(k)*qvf*((pm_input(k)/p1000mb)**cvpm))
             ! if(j_point.eq.25)print*,k,rho_loc_input(k),pm_input(k)
          enddo
        enddo

!  we have the moist sounding

!  next, compute the dry sounding using p at the highest level from the
!  moist sounding and integrating down.

        p_input(nl) = pm_input(nl)

          do k=nl-1,1,-1
            dz = h_input(k+1)-h_input(k)
            p_input(k) = p_input(k+1) + 0.5*dz*(rho_loc_input(k)+rho_loc_input(k+1))*g
          enddo


        do k=1,nl

          zk(k) = h_input(k)
          p(k) = pm_input(k)
          p_dry(k) = p_input(k)
          theta(k) = th_input(k)
          rho_local(k) = rho_loc_input(k)
          u(k) = u_input(k)
          v(k) = v_input(k)
          qv(k) = qv_input(k)

        enddo
	
     if(D3_data) then
      write(*,*) ' sounding '
      write(*,*) '  k  height(m)  press (Pa)   pd(Pa)   theta (K)  den(kg/m^3)  u(m/s)     v(m/s)    qv(g/g) '
      do k=1,nl
      write(*,'(1x,i3,8(1x,1pe10.3))') k, zk(k), p(k), p_dry(k), theta(k), rho_local(k), u(k), v(k), qv(k)
      enddo
		D3_data=.false.
     end if
	
	
     end subroutine get_sounding

!------------------------------------------------------------------

  !subroutine calc_jet_sounding( p_surf, th_surf, qv_surf,      &
   !                             h, th, qv, u, v, n, nl, debug, &
    !                            u_jet, rho_loc_jet, th_jet, z_jet, rh_jet, &
     !                           jp, nz_jet, ny_jet, dry       )
  
  subroutine calc_jet_sounding( p_surf, th_surf, qv_surf,      &
                                h, th, qv, u, v, n, nl, debug, &
                                u_jet, v_jet, th_jet, rho_loc_jet,  qv_jet, z_jet, &
                                jp, nz_jet, ny_jet, dry    )
  
  
  
  implicit none
  integer :: n, nl, jp, nz_jet, ny_jet

  real, dimension(nz_jet, ny_jet) :: u_jet, rho_loc_jet, th_jet, z_jet, qv_jet, v_jet
  real, dimension(n) :: h,th,qv,u,v
  real :: p_surf, th_surf, qv_surf
  logical :: debug, dry

  real, dimension(1:nz_jet) :: rho_local, rel_hum, p
  integer :: k

!  some local stuff

  real :: tmppi, es, qvs, temperature, thetav, RdoRv

!  get sounding from column jp

   do k=1,nz_jet
     h(k)  = z_jet(k,jp)
     th(k) = th_jet(k,jp)
     qv(k) = qv_jet(k,jp)
     rho_local(k) = rho_loc_jet(k,jp)
     u(k) = u_jet(k,jp)
     v(k) = v_jet(k,jp)
   enddo

   if (dry) then
     do k=1,nz_jet
       qv(k) = 0.
     enddo
   endif

!  next, compute pressure
!	!AT: this is where the tiny differences start, mainly due to real*4 vs real*8 
!   do k=1,nz_jet
!     p(k) = p1000mb*(R_d*rho_local(k)*th(k)/p1000mb)**cpovcv
!   enddo

!Hai:Recalculate pressure
   RdoRv=R_d/R_v
   do k=1,nz_jet
     !thetav=th_jet(k,jp)*(1+0.61*qv(k))
     thetav=th_jet(k,jp)*(qv(k)+RdoRv)/RdoRv/(1+qv(k))
     p(k) = p1000mb*(R_d*rho_local(k)*thetav/p1000mb)**cpovcv
   enddo

!  finally, set the surface data. AT: set the surface data to the input_jet surface data
   p_surf = p(1)!1.5*p(1) - 0.5*p(2)
   th_surf = th(1)!1.5*th(1) - 0.5*th(2)
   qv_surf = qv(1)!1.5*qv(1) - 0.5*qv(2)
   end subroutine calc_jet_sounding

!---------------------------------------------------------------------

 SUBROUTINE read_input_jet( u, v, t, r, qv, ff, sst, zk, nz, ny, nx, dz)
 implicit none

 integer, intent(in) :: nz,ny,nx
 real, intent(in) :: dz
 
 real, dimension(nz,ny), intent(out) :: zk
 real, dimension(nz,ny,nx), intent(out) :: v,u,r,t,qv
 real, dimension(ny), intent(out) :: ff
 real, dimension(ny,nx) :: sst
 integer :: ny_in, nz_in,nx_in,i, j,k
 real, dimension(nx,ny,nz) :: field_in
 real, dimension(nx,ny) :: field_in2d
 real, dimension(ny) :: field_in1d
 
 

! this code assumes it is called on processor 0 only

   OPEN(unit=10, file='input_jet_3D', form='unformatted', status='old' )
   REWIND(10) 
   read(10) nx_in, ny_in,nz_in
   if((ny_in /= ny ) .or. (nz_in /= nz)) then
     write(a_message,*) ' error in input jet dimensions '
     CALL wrf_message (a_message)
     write(a_message,*) ' ny, ny_input, nz, nz_input ', ny, ny_in, nz,nz_in
     CALL wrf_message (a_message)
     write(a_message,*) ' error exit '
     CALL wrf_message (a_message)
     call wrf_error_fatal ( ' error in input jet dimensions ' )
   end if
   read(10) field_in
   do i=1,nx
   do j=1,ny
   do k=1,nz
     u(k,j,i) = field_in(i,j,k)
   enddo
   enddo
   enddo
   
   read(10) field_in
   do i=1,nx
   do j=1,ny
   do k=1,nz
     v(k,j,i) = field_in(i,j,k)
   enddo
   enddo
   enddo
   
   read(10) field_in
    do i=1,nx
    do j=1,ny
    do k=1,nz
     t(k,j,i) = field_in(i,j,k)
    enddo
    enddo
    enddo

   read(10) field_in
   do i=1,nx
   do j=1,ny
   do k=1,nz
     r(k,j,i) = field_in(i,j,k)
   enddo
   enddo
   enddo

 	read(10) field_in
 	 do i=1,nx
   do j=1,ny
   do k=1,nz
     qv(k,j,i) = field_in(i,j,k)
   enddo
   enddo
   enddo

   read(10) field_in1d
   do j=1,ny
    ff(j)=field_in1d(j)
   enddo 


   read(10) field_in2d
   do i=1,nx
   do j=1,ny
     sst(j,i) = field_in2d(i,j)
   enddo
   enddo



   do j=1,ny
   do k=1,nz
   		zk(k,j)=0.+ dz*float(k-1)
    ! zk(k,j) = 125. + 250.*float(k-1)
   enddo
   enddo

 end subroutine read_input_jet

END MODULE module_initialize_ideal
