!-------------------------------------------------------------
! Module containing (atmospheric) constants
!	
! For more info see the README file
!--------------------------------------------------------------


module const

implicit none


! constants (match with WRF)
!==========================================================================	
real (kind=8) :: Rd=287.04d0		!gas constant of dry air
real (kind=8) :: Rv=461.6d0			!gas constant of water vapor
real (kind=8) :: g=9.81d0          	!gravitational constant
real (kind=8) :: pi=3.14159265358d0	!ratio circumference/diameter for circle
real (kind=8) :: cp=1004.5d0		!heat capacity at constant pressure for dry air
real (kind=8) :: cv=717.46d0        !heat capacity at constant volume for dry air
real (kind=8) :: cpv=1846.4d0		!heat capacity at constant pressure of water vapor
real (kind=8) :: cpl=4190.d0        !heat capacity of liquid water
real (kind=8) :: cpi=2106.d0		!heat capacity of ice
real (kind=8) :: e0=611.2d0			!reference vapor pressure
real (kind=8) :: Lv=2.5d6			!latent heat of vaporization at 0degC
real (kind=8) :: Li=2.85d6			!latent heat of sublimation 
real (kind=8) :: T0=273.15d0        !reference temperature 
real (kind=8) :: p00 = 1.0d5		!reference pressure	


end module const

