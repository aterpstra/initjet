!-------------------------------------------------------------
! Module for creating perturbation
!	
! For more info see the README file and/or documentation.
!--------------------------------------------------------------


module pert 

USE const 
USE io
USE init

implicit none


CONTAINS 

!------------------------------------------------------------------------------
subroutine get_pert(tt,th,uu,vv,rho,pp)
	!gets the perturbation and than balances the other fields
	real(kind=8),intent(inout),dimension(nx,ny,nz) :: uu,vv,tt,rho,pp,th

	real(kind=8) :: pp_temp(nx,ny,nz)

	call create_pert(tt)
	
	!*** rebalance ***
	if(rebalance)then!balance the perturbation
	!integrate pressure downward		(abs. error =0.d0)
	do k=nz-1,2,-1			
		do j=1,ny
			do i=1,nx
				pp(i,j,k-1)=pp(i,j,k+1)+((2*dz*pp(i,j,k)*g)/(Rd*tt(i,j,k))) 
			enddo
		enddo	
	enddo
	!adjust the density 			(abs. error <1.d-15)
	rho=pp/(Rd*tt)
	!adjust the potential temperature 	(abs. error =0.d0)
	th=tt*(p00/pp)**(Rd/cp)
	!approximate windfields using geostrophic approximation
	do k=1,nz			       !(abs. error <1.d-10)
		do j=2,ny-1
			do i=2,nx-1
				uu(i,j,k)=(-1/(rho(i,j,k)*f)) *	&
						((pp(i,j+1,k)-pp(i,j-1,k))/(2*dy))
				vv(i,j,k)=(1/(rho(i,j,k)*f)) *	&
						((pp(i+1,j,k)-pp(i-1,j,k))/(2*dx))
	 		enddo
	 	enddo
	enddo	
	else
		!only adjust the potential temperature 
		print*,"--> unbalanced perturbation <---"	
		th=tt*(p00/pp)**(Rd/cp)
	endif!balance the perturbation
end subroutine get_pert
!------------------------------------------------------------------------------


!------------------------------------------------------------------------------
subroutine create_pert(tt)
	!define temperature anomaly
	real(kind=8),intent(inout),dimension(nx,ny,nz) :: tt
	real(kind=8)	:: tanom,radius
	integer :: hgt

	!perturbation height
	hgt=int(P_hgt/dz)+1
	print*,"----------------HGT------------",hgt
	do k=1,nz
	z=((k-1)*dz)/P_z
    		do j=1,ny
    		y=((j-P_ny-1)*dy)/P_rad
        		do i=1,nx
        	   	x=((i-P_nx-1)*dx)/P_rad
           	
    			!1) gausian perturbation
			!-----------------------
			if(P_type==1)then	
				tanom=P_amp*(exp(-0.5*(x*x+y*y+z*z)))
			endif

			!2) local perturbation
			!---------------------
			if(P_type==2)then
				radius=sqrt(x*x+y*y)
				if(radius.lt.1.and.z.lt.1)then
					tanom=P_amp*(cos(pi*0.5*radius)**P_n)* &
								cos(pi*0.5*z)**2
				endif 
			endif

			!update temperature
			if(P_sfc)then	!surface
				tt(i,j,k)=tt(i,j,k)+tanom
			else		!upper level
				if(P_type==1.and.(k+hgt.le.nz.and.-k+hgt.ge.1))then
					tt(i,j,k+hgt)=tt(i,j,k+hgt)+(P_ratio*tanom)
					tt(i,j,-k+hgt)=tt(i,j,-k+hgt)-tanom
				endif
				if(P_type==2.and.(radius.lt.1.and.z.lt.1))then	
					tt(i,j,k+hgt)=tt(i,j,k+hgt)+(P_ratio*tanom)
					tt(i,j,-k+hgt)=tt(i,j,-k+hgt)-tanom
				endif
			endif

			enddo
		enddo
	enddo
end subroutine create_pert
!------------------------------------------------------------------------------


end module pert
