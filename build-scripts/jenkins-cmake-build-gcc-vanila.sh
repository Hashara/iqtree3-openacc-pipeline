#!bin/bash

###### handle arguments ######

work_dir=$1 # build dir
code_dir=$2 # iqtree2 dir


### pre steps #####
module load openmpi/4.1.5 boost/1.84.0 eigen/3.3.7 gcc/13.2.0


export OMPI_CC=gcc
export OMPI_CXX=gcc++

export CC=gcc
export CXX=gcc++

export LDFLAGS="-L/apps/nvidia-hpc-sdk/24.7/Linux_x86_64/24.7/compilers/lib"
export CPPFLAGS="-I/apps/nvidia-hpc-sdk/24.7/Linux_x86_64/24.7/compilers/include"


############

echo "building gcc-vanila"

mkdir -p "$work_dir"
cd $work_dir
cmake -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" -DEIGEN3_INCLUDE_DIR=/apps/eigen/3.3.7/include/eigen3 -DUSE_CMAPLE=OFF $code_dir
make -j


