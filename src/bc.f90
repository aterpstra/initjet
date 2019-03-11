!-------------------------------------------------------------
! Module containing boudary conditions calculations and defining the jet
!	
! For more info see the README file
!--------------------------------------------------------------


module bc

USE const 
USE io
USE init

implicit none



CONTAINS 

!------------------------------------------------------------------------------
subroutine get_bc_vert(p_vert,rho_vert)
	!calculates vertical profile of pressure 
	real(kind=8), dimension(nz), intent(out) :: p_vert,rho_vert
	real(kind=8), dimension(nz)				 :: th_vert,t_vert
        real(kind=8), dimension(nz) :: N2
        integer :: max_stops
 

	!lower reference values
	th_vert(1)=th0
	p_vert(1)=p0
	t_vert(1) = th_vert(1)*( (p_vert(1)/p0)**(Rd/cp))
  rho_vert(1) = p_vert(1)/(Rd*t_vert(1)) 
  !if(debug) call  write(blabla)
 

        !helper-loop for calculating N2 bc-type==1
        max_stops=1
        do i=2,6
           if (N2_levs(i)<N2_levs(i-1)) then
              max_stops=i-1
              exit
           end if
        enddo
        !if(debug) call write(blabla...values)



        !Determine static stability at vertical boundary (N2)
        !====================================================
        do k=1,nz
          z=(k-1)*dz

          !bc-type==0: old implementation for determining N2 
          !------------------------------------------------- 
          if(bc_type.eq.0)then
            if (z.le.tropo_hgt) then
               N2(k)=N2_tr**2.
            else
               N2(k)=N2_st**2.
            endif
          endif

          !bc-type==1: N2_levs !Hai Determine N2
          !---------------------------------------
          if (bc_type.eq.1) then !if(debug) call write(blabla...values)

            if (z.le.N2_levs(1)) then
                N2(k)=N2_vals(1)
            elseif (z.gt.N2_levs(max_stops)) then
                N2(k)=N2_vals(max_stops)
            else
              do i=1,max_stops-1
                 if ((z.gt.N2_levs(i)).and.(z.le.N2_levs(i+1)))then
                    N2(k) = N2_vals(i) + (N2_vals(i+1)-N2_vals(i))*(z-N2_levs(i))/(N2_levs(i+1)-N2_levs(i))
                 endif
              enddo
            endif
          endif
          !if(debug) call write(blabla...N2-values)
        enddo



	!use bruntvaisala (N2) to derive theta
	!calculate pressure using equation of state and definition of theta
	do k=2,nz
		z=(k-1)*dz
      th_vert(k)=th_vert(k-1)*exp((N2(k)*dz)/g) !Hai
		  !calculate pressure, temperature and density
		  p_vert(k) = ( p_vert(k-1)**(Rd/cp) - ((Rd/cp)*g*p00**(Rd/cp)*dz) / &
				( Rd*0.5* ( th_vert(k)+th_vert(k-1) ) ) )**(1./(Rd/cp))
       
      t_vert(k) = th_vert(k)* ((p_vert(k)/p0)**(Rd/cp))
      rho_vert(k) = p_vert(k)/ (Rd*t_vert(k))
	enddo

  if(debug) call print_profile_bc(th_vert,p_vert,rho_vert,dz)
	
end subroutine get_bc_vert
!------------------------------------------------------------------------------



!------------------------------------------------------------------------------
subroutine fill_matrix(A,B,uu_jet,p_vert,ff)
	!fill the matrix given bc
	real(kind=8), intent(in)	:: ff(ny)
	real(kind=8), intent(in)	:: uu_jet(ny,nz),p_vert(nz)
	real(kind=8), intent(out) 	:: A(ny*nz,ny*nz),B(ny*nz)	         



	!fill the A and B matrix (excluding boundaries)
  	do j=2,ny-1
    	do k=2,nz-1
        B((k-1)*ny+j)= 0.d0

        A((k-1)*ny+j,(k-1-1)*ny+j)   = uu_jet(j,k)/(2.d0*dz)			
        A((k-1)*ny+j,(k-1+1)*ny+j)   = uu_jet(j,k)/(-2.d0*dz)			
        A((k-1)*ny+j,(k-1)  *ny+j-1) = g/(-2.d0*ff(j)*dy)                  
        A((k-1)*ny+j,(k-1)  *ny+j+1) = g/(2.d0*ff(j)*dy)                   
    	enddo
	enddo

	!boundary conditions
	!===================
	if(bc_vert==0)then 	!south side

		!bottom z=1
    	do j=1+1,ny
    	    B(j)=0.d0
    	    if((j.ge.2).and.(j.le.(ny-1)))then
    	    	!horizontal
    	    	A(j,j-1)=g/(-2.d0*ff(j)*dy)  
    	    	A(j,j+1)=g/(2.d0*ff(j)*dy)  
    	    	!vertical
    	    	A(j,2*ny+j)=uu_jet(j,1)/(2.d0*dz)
    	    	A(j,ny+j)=-4.0d0*uu_jet(j,1)/(2.d0*dz)
    	    	A(j,j)=3.0d0*uu_jet(j,1)/(2.d0*dz)
    	    else
    		    if(j.eq.ny)then
  			      	A(j,j-1)=-1.d0
       			 	A(j,j)=1.d0
     		   endif
        	endif
    	enddo

  		!top z=nz
	    do j=2,ny
    	    B((nz-1)*ny+j)=0.d0
 	       if((j.ge.2).and.(j.le.(ny-1)))then
    	       !horizontal
    	       A((nz-1)*ny+j,(nz-1)*ny+j-1) = g/(-2.d0*ff(j)*dy)  
    	       A((nz-1)*ny+j,(nz-1)*ny+j+1) = g/(2.d0*ff(j)*dy)  
    	       !vertical
    	       A((nz-1)*ny+j,(nz-1-2)*ny+j)=-uu_jet(j,nz)/(2.d0*dz)
    	       A((nz-1)*ny+j,(nz-1-1)*ny+j)=4.0d0*uu_jet(j,nz)/(2.d0*dz)
    	       A((nz-1)*ny+j,(nz-1)*ny+j)=-3.0d0*uu_jet(j,nz)/(2.d0*dz)
    	    else
    	        if(j.eq.ny)then
    	            A((nz-1)*ny+j,(nz-1)*ny+j)=1.d0
    	            A((nz-1)*ny+j,(nz-1)*ny+j-1)=-1.d0
        	    endif
        	endif
    	enddo

		!right y=ny
	    do k=2,nz-1
	        B(k*ny)=0.d0
	        A(k*ny,k*ny)=-1.d0
	        A(k*ny,k*ny-1)=1.d0
	    enddo

		!left y=1
	    do k=1,nz
	        B((k-1)*ny+1) = p_vert(k)
	        A((k-1)*ny+1,(k-1)*ny+1)=1.d0
	    enddo

	else !north side

		!bottom z=1
   		do j=1,ny-1
        	B(j)=0.
    	    if((j.ge.2).and.(j.le.(ny-1)))then
    	    	!horizontal
    	    	A(j,j-1)=g/(-2*ff(j)*dy)  
    	    	A(j,j+1)=g/(2*ff(j)*dy)  
    	    	!vertical
    	    	A(j,2*ny+j)=uu_jet(j,1)/(2*dz)
    	    	A(j,ny+j)=-4.0d0*uu_jet(j,1)/(2*dz)
    	    	A(j,j)=3.0d0*uu_jet(j,1)/(2*dz)
    	    else
    		    if(j.eq.1)then
  			      	A(j,j+1)=-1.d0
       			 	A(j,j)=1.d0
     		   endif
        	endif
    	enddo

		!top z=nz
    	do j=1,ny-1
        	B((nz-1)*ny+j)=0.
        	if((j.ge.2).and.(j.le.(ny-1)))then
        	   !horizontal
    	       A((nz-1)*ny+j,(nz-1)*ny+j-1) = g/(-2*ff(j)*dy)  
    	       A((nz-1)*ny+j,(nz-1)*ny+j+1) = g/(2*ff(j)*dy)  
    	       !vertical
    	       A((nz-1)*ny+j,(nz-1-2)*ny+j)=-uu_jet(j,nz)/(2*dz)
    	       A((nz-1)*ny+j,(nz-1-1)*ny+j)=4.0d0*uu_jet(j,nz)/(2*dz)
    	       A((nz-1)*ny+j,(nz-1)*ny+j)=-3.0d0*uu_jet(j,nz)/(2*dz)
        	else
        	    if(j.eq.1)then
        	        A((nz-1)*ny+j,(nz-1)*ny+j)=1.d0
        	        A((nz-1)*ny+j,(nz-1)*ny+j+1)=-1.d0
        	    endif
        	endif
    	enddo

		!right y=ny
    	do k=1,nz
        	B(k*ny)=p_vert(k)
	        A(k*ny,k*ny)=1.d0
        enddo 

        !left y=1
        do k=1,nz
            B((k-1)*ny+1) = 0.d0
            A((k-1)*ny+1,(k-1)*ny+1)=1.d0
            A((k-1)*ny+1,(k-1)*ny+2)=-1.d0
        enddo 

	endif	!endif  BOUNDARY CONDITIONS
end subroutine fill_matrix
!------------------------------------------------------------------------------

!------------------------------------------------------------------------------
subroutine get_bs_vert(p_vert,th_vert,rho_vert)
    !calculates vertical profile of basic-state for p,th,rho (boussinesq)
    real(kind=8), dimension(nz), intent(out) :: p_vert
    real(kind=8), dimension(nz), intent(out) :: th_vert
    real(kind=8), dimension(nz), intent(out) :: rho_vert

    !lower reference values
    th_vert(1)=th0
    p_vert(1)=p0
    rho_vert(1)=p0/(Rd*th0)

    !use bruntvaisala to derive theta
    !calculate pressure using equation of state and definition of theta
    do k=2,nz
        z=(k-1)*dz
        if(z.le.tropo_hgt)then
            th_vert(k)=th_vert(k-1)*exp((N2_tr**2*dz)/g)
        else
            th_vert(k)=th_vert(k-1)*exp((N2_st**2*dz)/g)
        endif
        !calculate pressure
        p_vert(k) = ( p_vert(k-1)**(Rd/cp) - ((Rd/cp)*g*p00**(Rd/cp)*dz) / &
                ( Rd*0.5* ( th_vert(k)+th_vert(k-1) ) ) )**(1./(Rd/cp))
        !calculate density
        rho_vert(k)=p_vert(k)/(Rd*th_vert(k)*p_vert(k)**(Rd/cp)*p00**(-Rd/cp))
    enddo

  if(debug) call print_profile_bc(th_vert,th_vert,rho_vert,dz)
    
end subroutine get_bs_vert
!------------------------------------------------------------------------------



end module bc
