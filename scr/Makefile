# Makefile for initJET code 
#---------------------------------
FC=gfortran

#IOINCS = -I/usr/local/include 				#@uwhpsc
IOINCS = -I/usr/include		 			#@skd-cyclone/debian9
#IOINCS =  -I/opt/local/include		 			#Mac os
#IOINCS = -I/usr/local/netcdf-3.6.3/include			#@mac
#IOLIBS = -L/usr/local/lib -lnetcdff -lnetcdf 		#@uwhpsc
#IOLIBS = -L/usr/lib -lnetcdf -lnetcdff -lhdf5 -lhdf5_hl	#@skd-cyclone
IOLIBS = -L/usr/lib -lnetcdf -lnetcdff 		#@debian9
#IOLIBS = -L/opt/local/lib -lnetcdf -lnetcdff 		#mac
#IOLIBS = -L/usr/local/netcdf-3.6.3/lib -lnetcdf -lnetcdff	#@mac
LFLAGS = -llapack
#LFLAGS = -lblas -llapack

CPPFLAGS=-I/opt/local/include

OBJECTS = const.o io.o init.o bc.o jet.o moist.o pert.o func.o main.o 
MODULES = const.mod io.mod init.mod bc.mod jet.mod moist.mod pert.mod func.mod
.PHONY: clean 

#create initial conditions
initial_conditions: main.exe
	./main.exe 

#compile .f90 files
main.exe: $(MODULES) $(OBJECTS)
	$(FC) $(OBJECTS) $(LFLAGS) $(IOLIBS) -o main.exe 

#link the .o files
%.o: %.f90
	$(FC) -c $< $(IOINCS)

%.mod: %.f90 
	$(FC) -c $< $(IOINCS)

#clean up 
clean:
	rm -f $(OBJECTS) $(MODULES) main.exe

