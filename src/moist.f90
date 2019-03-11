!-------------------------------------------------------------
! Module for calculating moisture related things
!	
! For more info see the README file and/or documentation.
!--------------------------------------------------------------


module moist

USE const 
USE io
USE init
implicit none

CONTAINS 

!------------------------------------------------------------------------------
subroutine get_RH(rh)
	!create relative humidity profile
	real(kind=8),intent(inout)	:: rh(ny,nz)
	real(kind=8)	:: rh_prof(nz)

	call get_rh_vert(rh_prof)

    !same rh-profile everywhere
    do j=1,ny
    	rh(j,:)=rh_prof
    enddo

end subroutine get_RH
!------------------------------------------------------------------------------


!------------------------------------------------------------------------------
subroutine get_rh_vert(rh_prof)
	!create relative humidity profile
	real(kind=8),intent(out)	:: rh_prof(nz)
	real(kind=8)				:: dRHdz

  	if(rh_type==1)then  !create a linear profile
		dRHdz=(RH_max-RH_min)/RH_hgt
		do k=1,nz
			z=(k-1)*dz
				if(z.lt.RH_hgt)then
					rh_prof(k)=RH_max-dRHdz*z
				else
					rh_prof(k)=RH_min
				endif
			enddo
    endif

   if(rh_type==2)then !create log rh profile
        do k=1,nz
            z=(k-1)*dz
            rh_prof(k)=RH_max*exp(-0.5*(z/RH_hgt)**RH_shape)
        enddo
    endif
end subroutine get_rh_vert
!------------------------------------------------------------------------------



!------------------------------------------------------------------------------
subroutine get_qs(pp,tt,qs)
!get saturation mixing ratio		
	real(kind=8),intent(in),dimension(nx,ny,nz)	:: pp,tt
	real(kind=8),intent(out),dimension(nx,ny,nz)	:: qs

	do k=1,nz
		do j=1,ny
      do i=1,nx
		    qs(i,j,k)=((Rd/Rv)*e_s(tt(i,j,k)))/(pp(i,j,k)-e_s(tt(i,j,k)))
      enddo
		enddo
	enddo

end subroutine get_qs
!------------------------------------------------------------------------------



!-------------------------------------------------------
function e_s(T)
!returns the saturation vapor pressure given temperature
!Hai: change to Buck's equation. 
	real(kind=8), intent(in) :: T
	real(kind=8)	:: e_s, Tc
	!old version of e_s estimation (inferior)
	!if(T.gt.T0)then
	!	e_s=e0*exp(17.67*(T-T0)/(T-29.65))
	!else
	!	e_s=e0*exp(21.8745584*(T-T0)/(T-7.66))
	!endif
 
  !Buck's equation (superior)
        Tc = T - 273.15
        e_s = 611.21*exp((18.678 - Tc/234.5)*(Tc/(257.14+Tc))) 
end function e_s
!-------------------------------------------------------

!-------------------------------------------------------
function relhum(T,w,p)
	!calc. Relative humidity [HAI]
  real(kind=8) , intent(in) :: T,w,p
  real(kind=8)  :: es,ws
  real(kind=8)  :: relhum
  relhum=0.
  es = e_s(T)
  ws = (Rd/Rv)*(es/(p-es))
  relhum = w/ws
end function relhum
!-------------------------------------------------------

!------------------------------------------------------- 
function mixrat(T,rh,p)
	!calc. mixing ratio [HAI]
  real(kind=8) , intent(in) :: T,rh,p
  real(kind=8) :: mixrat
  real(kind=8)  :: es,ws
  es = e_s(T)
  ws = (Rd/Rv)*(es/(p-es))
  mixrat = rh*ws
end function mixrat
!-------------------------------------------------------



!-------------------------------------------------------
subroutine calc_T_w(Tv,RH,p,T,w)
!Hai: Use bisection method to get Temperature and mixing ratio from Tv and RH
	real(kind=8), intent(in) :: Tv, RH, p
	real(kind=8), intent(out) :: T,w
        real(kind=8), parameter :: eps=1e-5  ! threhold for error, 1e-5 --> error of 0.00001 degree
        real(kind=8) :: delta,Told
        integer :: i
        T = Tv !First guess
        delta=999 
        i=1
        do while(delta .gt. eps)
           w = mixrat(T,RH,p)
           Told = T  
!           T = 0.5*(T + Tv/(1+0.61*w) )
!           T =  Tv/(1+0.61*w)   ! It's actually faster
           T = Tv*(Rd/Rv)*(1+w)/(w+(Rd/Rv))
           delta = abs(T-Told)
!           write(*,*)i,T,w,delta,relhum(T,w,p)
!           i=i+1
        end do
end subroutine calc_T_w
!-------------------------------------------------------





end module moist
