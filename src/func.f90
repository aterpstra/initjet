!-------------------------------------------------------------
! Module containing some additional subroutines
!	
! For more info see the README file
!--------------------------------------------------------------


module func

USE const 
USE io
USE init
USE moist

implicit none


CONTAINS 


!-------------------------------------------------------------------
subroutine make_3D(pp,uu,rho,tt,th,rh,vv)
!dump the 2D-setup in a 3D-array
	real(kind=8), intent(inout), dimension(nx,ny,nz) :: pp,uu,rho,tt,rh,vv,th
	
	do i=1,nx
		pp(i,:,:)=pp(1,:,:)
		uu(i,:,:)=uu(1,:,:)
		rho(i,:,:)=rho(1,:,:)
		tt(i,:,:)=tt(1,:,:)
		th(i,:,:)=th(1,:,:)
		rh(i,:,:)=rh(1,:,:)
		vv(i,:,:)=vv(1,:,:)
	enddo

end subroutine make_3D
!-------------------------------------------------------------------



!-------------------------------------------------------------------------------
subroutine calc_corr(ff)
!calculate ff, where ff=f in the center of the domain
    real(kind=8),intent(out),dimension(ny) :: ff

    do j=1,ny
        ff(j) = f + beta*dy*(j-(ny+1)/2.)
       ! if (debug) write (blablabla... coriolis values)
    enddo
end subroutine calc_corr
!---------------------------------------------------------------------------------




!------------------------------------------------------------------------------
subroutine get_sst(sst,tt)
!return SST values
  real(kind=8), intent(in), dimension(nx,ny) :: tt
  real(kind=8), intent(out), dimension(nx,ny):: sst
   
    !Set SST to 0.0 (when not used for lower bc)
    if (sst_type.eq.0) then
       sst=0.0
    endif

    !Set SST == lowest level air-temperature with offset => sst_diff
    if (sst_type.eq.1) then
        sst = tt + sst_diff
    endif

  !One can run the model without SST, ie. without lower boundary conditions,
  !Note: interaction with WRF requires that you HAVE to provide SST (which is not used)
end subroutine get_sst
!------------------------------------------------------------------------------







!------------------------------------------------------------------------------
!Hai: calc all variable in 3D
subroutine calc_all_3D(tt,ttv,th,thv,qq,rh,pp,zz)
!calculate the 'correct' variables
        real(kind=8),intent(inout),dimension(nx,ny,nz) :: tt,ttv,th,thv,qq,rh,pp
        real(kind=8),dimension(ny,nz) :: zz
        real(kind=8),dimension(nz)  :: z_vert

        !we actually have the virtual (pot.) temperature
        ttv=tt
        thv=th

        !New method by Hai: iteratively derive qq fom rh and ttv
        do k=1,nz
         do j=1,ny
           do i=1,nx
           call calc_T_w(ttv(i,j,k),rh(i,j,k),pp(i,j,k),tt(i,j,k),qq(i,j,k))
           enddo
         enddo
        enddo

        th=thv/(1+0.61*qq)

  !calculate the height
  do k=1,nz
    z_vert(k)=(k-1)*dz
  enddo
  !same z-profile everywhere
  do j=1,ny
      zz(j,:)=z_vert
  enddo

end subroutine calc_all_3D
!------------------------------------------------------------------------------




end module func
