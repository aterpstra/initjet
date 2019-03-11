!-------------------------------------------------------------
! Module containing some initialization subroutines
!	
! For more info see the README file
!--------------------------------------------------------------


module init 

USE const 
USE io

implicit none

real(kind=8)	:: x,y,z
real(kind=8)	:: dx, dy, dz
integer 		:: i,j,k

CONTAINS 

!------------------------------------------------------------------------------
subroutine domainspec()
	!get the domain specifications
	dx = Lx/(nx-1)
	dy = Ly/(ny-1)
	dz = Lz/(nz-1)

	if(debug)then
		print'(A1/,A15/,A15)'," ","grid length (m)","---------------"
		print'(A3,F10.3/,A3,F10.3/,A3,F8.3)',"dx=",dx,"dy=",dy,"dz=",dz
	endif 
end subroutine domainspec
!------------------------------------------------------------------------------


!------------------------------------------------------------------------------
subroutine consistcheck()
	!check if not asked for the impossible
	if(.not.(dx.eq.dy))then
		print*,"WARNING: Horizontal grid-spacing inconsistent"
		print'(A3,F10.3/,A3,F10.3)',"dx=",dx,"dy=",dy
	endif
end subroutine consistcheck
!------------------------------------------------------------------------------


end module init 