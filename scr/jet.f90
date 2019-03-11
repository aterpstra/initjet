!-------------------------------------------------------------
! Module defining the jet
!	
! For more info see the README file
!--------------------------------------------------------------


module jet

USE const 
USE io
USE init 

implicit none

CONTAINS 


!------------------------------------------------------------------------------
subroutine get_jet(uu_jet)
	!get the windspeed at jet-location elsewhere uu=0
	real(kind=8), intent(out) :: uu_jet(ny,nz)
	real(kind=8)	:: bc_h1,bc_h2,bt_uu
	real(kind=8),dimension(nz)	:: u_prof
        
        real(kind=8), dimension(ny)  :: Z_diff  !Coordinate transformation to manipulate N2 at the tropopause        
        real :: A, B,ry
  
        Z_diff=0
        if (Z_opt==1) then
          A = (U_hgt-tropo_hgt)*1.5
          if (U_type==100) then
            B = U_width/2.
          else
            B = (U_hwe+U_hwp)/2.
          endif
          do j=1,ny
            ry = (j-1)*dy-Ly/2.
            Z_diff(j) = A*tanh(-ry/B)
            write(*,*)j,":",Z_diff(j),ry,A,B
          enddo
        endif
	!obtain external wind-profile if desired
	if(ext_prof)then
		call read_nc(ifile_uprof,u_prof)
	endif

	!determine boundaries
	bc_h1=(Ly-U_width)/2
	bc_h2=((Ly-U_width)/2)+U_width

	!obtain windspeed
        if (U_type .ne. 99) then
	do k=1,nz
	    do j=1,ny
	        z=(k-1)*dz - Z_diff(j)
		y=(j-1)*dy
              !  write(*,*)"::",j,k,y,z,dy,dz
                if (U_tilt.ne.0)  call rotate(U_tilt,y,z)
               ! write(*,*)"==>",y,z
		!add a jet
		if(y.lt.bc_h1 .or. y.gt.bc_h2)then	!set to zero outside jet-width
			uu_jet(j,k)=0.d0
		else
			if(ext_prof)then
				call calc_jet_ext(uu_jet(j,k),y-bc_h1,k,u_prof)
			else
				call calc_jet(uu_jet(j,k),y-bc_h1,z)
			endif
			!add barotropic shear
			if(add_BT)then
				call add_barotropic(bt_uu,y-bc_h1,z)
				uu_jet(j,k)=uu_jet(j,k)+bt_uu
			endif
		endif
		enddo
	enddo
        endif
        
        if ((U_type==99) .or. (U_type==100)) then
        do k=1,nz
            do j=1,ny
	        z=(k-1)*dz - Z_diff(j)
                if (k==1) write(*,*)j,"->",z
                y=(j-1)*dy                 
                if (U_tilt.ne.0)  call rotate(U_tilt,y,z)
		!add a jet
                call calc_jet(uu_jet(j,k),y,z)
            enddo
        enddo
        endif
	if(debug) call print_profile_j(uu_jet,dz)

end subroutine get_jet
!------------------------------------------------------------------------------


!------------------------------------------------------------------------------
subroutine calc_jet(uu,y,z)
	!calculate the windspeed
	real(kind=8),intent(out)	:: uu
	real(kind=8),intent(in)		:: y,z

	real(kind=8)	:: z_jet, hh_tr, hh_st, &
			    U_vert,U_horz,in_sin,hor_border,hh_o,hh_u,in_sin_p1 !MG:for jet 8
       
        real(kind=8) :: ry,rz,r
        !Hai Jet center shape (jetc = az^2+bz),a=-1/(2*Slope*H),b=1/Slope, slope is define at z=0
        real(kind=8) :: a,b,jetc  
        real(kind=8) :: Wy, Wz

	!1) Polvani&Esler(2007) jet
	!--------------------------
	if(U_type==1)then
			uu = U_max*(sin(pi*(sin(pi*y/(2*U_width))**2))**3)*& !horizontal
					((z/U_hgt)*exp(-1*((z/U_hgt)**2-1)/2))	 !vertical
	endif


	!2) sin-jet with separte shear in troposphere/stratosphere
	!--------------------------
	if(U_type==2)then
		if(z.gt.U_bottom .and. z.lt.U_top)then
			if(U_bottom.lt.0)then
				z_jet=U_top+abs(U_bottom) !vertical extend of the jet [m]
			else
				z_jet=U_top-U_bottom
			endif
			hh_tr=U_hgt-U_bottom			!jet vertical length scale in troposphere
			hh_st=U_bottom+z_jet-U_hgt	!jet vertical length scale in stratosphere
			if(z.gt.U_hgt)then
			!stratosphere
				uu = U_max*(sin(pi*(sin(pi*y/(2*U_width))**2))**3)*& !horizontal
				sin(pi/2*((U_bottom+z_jet-z)/hh_st))**S_st	 !vertical
			else
			!troposphere
				uu = U_max*(sin(pi*(sin(pi*y/(2*U_width))**2))**3)*&	!horizontal
				sin(pi/2*((z-U_bottom)/hh_tr))**S_tr	!vertical
			endif
		else
			uu=0.0		
		endif
	endif


	!3) low level jet (for ice-edge jet simulations Stefan, oid)
	!-----------------------------------------------------------
	if(U_type==3)then
		uu= U_max*exp(-0.5*(abs(y-(U_width/2))/y_llj)**nh_llj) *&!horizontal dependence
							exp(-0.5*(z/(h_llj))**ny_llj)			!vertical dependence			
	endif

	!4) reversed shear (4 segments)
	!--------------------------------------------------------
	if(U_type==4)then
		if(z.lt.H2)then	!different amplitudes 
			uu= A1*(sin(pi*(sin(pi*y/(2*U_width))**2))**3)	!horizontal
		else
			uu= A2*(sin(pi*(sin(pi*y/(2*U_width))**2))**3)	!horizontal
		endif
				if(z.lt.H1)then!part1
					uu=uu*   (cos( 0.5*pi* (z/H1)-pi/2     ))**H1s
				elseif(z.lt.H2)then!part2
					uu=uu*   (cos( 0.5*pi*((z-H1)/(H2-H1)) ))**H2s
				elseif(z.lt.H3)then!part3
					uu=uu* (-1)*(cos( 0.5*pi*((z-H2)/(H3-H2)) -pi/2 ))**H3s
				elseif(z.lt.H4)then!part4
					uu=uu* (-1)*(cos( 0.5*pi*((z-H3)/(H4-H3)) ))**H4s
				else !above jet --> u=0
					uu=0.d0
				endif
	endif

	!5) reversed shear (2 segments)
	!--------------------------------------------------------
	if(U_type==5)then
			uu= A1*(sin(pi*(sin(pi*y/(2*U_width))**2))**3)	!horizontal
			if(z.lt.H1)then!part1
				uu=uu*   (cos( 0.5*pi* (z/H1)-pi/2     ))**H1s
			elseif(z.lt.H2)then!part2
				uu=uu*   (cos( 0.5*pi*((z-H1)/(H2-H1)) ))**H2s
			else !above jet --> u=0
				uu=0.d0
			endif
	endif

	!6) reversed shear (single segment)
	!--------------------------------------------------------
	if(U_type==6)then
			uu= A1*(sin(pi*(sin(pi*y/(2*U_width))**2))**3)	!horizontal
			if(z.lt.H1)then
				uu=uu* (cos( 0.5*pi*((z)/(H1)) ))**H1s 
				
			else !above jet --> u=0
				uu=0.d0
			endif
	endif

	!8) low level jet (from jet type 2, sin jet with separate shear above and below the maximum, matthias)
	!-----------------------------------------------------------
	if(U_type==8)then
		if(z.gt.U_bottom .and. z.lt.U_top)then              
                	z_jet= U_top-U_bottom ! vertical extent of the jet

                	hh_u=brd_llj-U_bottom       	!jet vertical length scale in troposphere
                	hh_o=U_bottom+z_jet-brd_llj 	!jet vertical length scale in stratosphere
                
		        !Calculation of U_vert (vertical part of uu)
		        if(z.gt.brd_llj)then !above wind maximum
                    		U_vert= (sin(pi/2*((U_top-z)/hh_o)))**S_o	
                	else !below wind maximum
                    		U_vert= (sin(pi/2*((z-U_bottom)/hh_u)))**S_u
                	endif
                
                	!Calculation of U_horz (horizontal part of uu)
                	in_sin= (sin(0.5*pi*y/(U_width-hor_leng)))**2
                	if(in_sin.gt.0.5 .and. y.lt.hor_border)then !Plateau
                    		U_horz= 1
                    
                	elseif(in_sin.gt. 0.5 .and. y.ge.hor_border)then !decreasing side of the jet at northern edge
                    		U_horz= (sin(pi*(sin(pi*(y-hor_leng)/(2*(U_width-hor_leng))))**2))**S_h
                	else ! increasing side of the jet at southern edge
                    		U_horz= (sin(pi*in_sin))**S_h
			endif               
                	!Calculation of uu               
                		uu= U_max*U_vert*U_horz

			! get hor_border for the horizontal homogen part
                	in_sin_p1= sin(pi*(y+dy)/(2*(U_width-hor_leng)))**2
			if(in_sin.le.0.5 .and. in_sin_p1.gt.0.5)then
                        	hor_border= y+hor_leng
                    	endif
            	else
                	uu=0.0
            	endif	
	endif

!9) cold-air outbreak jet (from jet type 2, sin jet with separate shear above and below the maximum and global maximum und minimum around the mean zone defined by U_max2, matthias)
	!-----------------------------------------------------------
	if(U_type==9)then
		if(z.gt.U_bottom .and. z.lt.U_top)then              
                	z_jet= U_top-U_bottom ! vertical extent of the jet

                	hh_u=brd_llj-U_bottom       	!jet vertical length scale in troposphere
                	hh_o=U_bottom+z_jet-brd_llj 	!jet vertical length scale in stratosphere
                
		        !Calculation of U_vert (vertical part of uu)
		        if(z.gt.brd_llj)then !above wind maximum
                    		U_vert= (sin(pi/2*((U_top-z)/hh_o)))**S_o	
                	else !below wind maximum
                    		U_vert= (sin(pi/2*((z-U_bottom)/hh_u)))**S_u
                	endif
                
                	!Calculation of U_horz (horizontal part of uu)
                	if(y.le.(0.5*(U_width-hor_leng)))then
                    		in_sin = sin(0.5*pi*y/(0.5*(U_width-hor_leng)))**2
                    		if(in_sin.le.0.5)then
                        		U_horz= U_max*(sin(pi*(in_sin)))**S_h
                    		elseif(in_sin.gt.0.5)then
                        		U_horz= U_max2+(U_max-U_max2)*(sin(pi*(in_sin)))**S_h         
                   		endif
                	elseif(y.gt.(0.5*(U_width+hor_leng-dy)))then
                    		in_sin= (sin(0.5*pi*(y-hor_leng)/(0.5*(U_width-hor_leng)))**2)
                    		if(in_sin.ge.0.5)then
                        		U_horz= U_max2+(U_max+U_max2)*(sin(-pi*(in_sin)))**S_h
                    		elseif(in_sin.lt.0.5)then
                        		U_horz = U_max*(sin(-pi*(in_sin)))**S_h
   				endif
                	else
                    		U_horz=U_max2
                	endif    
           
                	!Calculation of uu               
                	uu= U_vert*U_horz
            	else
                	uu=0.0
            	endif	

	endif


!99: By Bui Hoang Hai, Nov, 2017
!parameter needs:   
! U_hgt, U_top, U_bottom (already)
! U_hwe (halfwide in the equatorial side, in m, e.g. 3000e3)
! U_hwp  (halfwide in the polar side, in m, e.g. 1500e3)
! U_tilt  (tilt of the jet, in degree. e.g. 10)
        if (U_type==99 .or. U_type==100) then
           if (front_slope.ne.0) then
              a=-1./(2*front_slope*U_hgt)
              b=1/front_slope
              jetc = a*z**2. + b*z
           else
              jetc = 0.
           end if

           if (y<=Ly/2+jetc) then
              ry = (y - Ly/2 - jetc)/U_hwe
           else
              ry = (y - Ly/2 - jetc)/U_hwp
           endif
           
           
           if (z<=U_hgt) then
              rz = ( z - U_hgt)/(U_hgt-U_bottom)
           else
              rz = ( z - U_hgt)/(U_top-U_hgt)
           endif

           if (U_type==99) then
            r = sqrt(ry**2 + rz**2)
            if (r>=1) then
              uu = 0.
            else
              if (U_shape.eq.1) then
                uu = U_max*cos(r*pi/2)**1
              else if (U_shape.eq.2) then
                uu = U_max*cos(r*pi/2)**2
              else if (U_shape.eq.3) then
                uu = U_max*(1-r)
              else if (U_shape.eq.4) then
                uu = U_max*cos(1-r**2)
              else
                write(*,*)"Unkown U_shape:",U_shape
                stop
              endif  
            endif 
           else if (U_type==100) then
            Wy=0.
            Wz=0.
            if (ry<=1. .and. ry>=-1.) then 
               Wy = cos(ry*pi/2)**2
            endif
            if (rz<=1. .and. rz>0.) then 
!               Wz = 1-abs(rz)**S_st
               Wz = cos(rz*pi/2)**S_st
            else if (rz>=-1. .and. rz<=0.) then
!               Wz = cos(rz*pi/2)**S_tr
               Wz = 1-abs(rz)**S_tr
            endif
            if (z==0.) write(*,*)y,ry,"Wy",Wy
            if (y==0.) write(*,*)z,rz,"Wz",Wz

            uu = U_max*Wy*Wz

           endif !100
         
        endif
end subroutine calc_jet
!------------------------------------------------------------------------------


subroutine rotate(alpha,y,z)
	!--Hai: rotate the coordinate
	! helper for creating jet 
   real(kind=8) :: y,z,alpha,z_tmp
   real(kind=8) :: y_c, z_c  !center of rotation
   z_tmp = z-U_hgt
   dy = z_tmp*tan(alpha*pi/180.)
   y = y + dy
end subroutine

!------------------------------------------------------------------------------
subroutine calc_jet_ext(uu,y,z,u_prof)
	!calculate the windspeed
	real(kind=8),intent(out)	:: uu
	real(kind=8),intent(in)		:: y
	integer,intent(in)			:: z
	real(kind=8),dimension(nz)	:: u_prof

	real(kind=8)	:: z_jet, hh_tr, hh_st

	!calc windspeed using external vertical profile
			uu = U_max*(sin(pi*(sin(pi*y/(2*U_width))**2))**3)*& !horizontal
					u_prof(z)

end subroutine calc_jet_ext

!------------------------------------------------------------------------------
subroutine add_barotropic(uu,y,z)
! calculate sinusiodial barotropic shear, decreases above jet height
	real(kind=8), intent(in) :: y,z
	real(kind=8), intent(out):: uu
	!barotropic shear
	if(BT_type==1)then
		uu= BT_max*dy*sin(2*pi*(y/U_width))* &		!horizontal dependence
			exp(-0.5*(z/(1.5*U_hgt))**4)		!vertical dependence
	endif
end subroutine add_barotropic
!------------------------------------------------------------------------------




end module jet 
