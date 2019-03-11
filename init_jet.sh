#!/bin/sh

dir=$PWD

cd $dir/fort

make

cd $dir/

ncl plt/plt_jet.ncl
ncl plt/wrfinput_vs_initjet.ncl

