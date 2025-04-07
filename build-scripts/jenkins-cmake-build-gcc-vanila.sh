#!/bin/bash


work_dir=$1 # build dir
code_dir=$2 # iqtree2 dir

params=$3
custom_flags=$4

if [ "$params" == "openacc" ]; then
    echo "building gcc-openacc"
    cmake_params="-DUSE_OPENACC=ON"
else
    echo "building gcc-vanila"
    cmake_params="-DUSE_OPENACC=OFF"
fi

### pre steps #####
module load openmpi/4.1.5 boost/1.84.0 eigen/3.3.7 gcc/13.2.0


export OMPI_CC=gcc
export OMPI_CXX=g++

export CC=gcc
export CXX=g++

export LDFLAGS="-L/apps/gcc/13.2.0/lib"
export CPPFLAGS="-I/apps/gcc/13.2.0/include"


############

echo "building gcc-vanila"

mkdir -p "$work_dir"
cd $work_dir
cmake -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" -DEIGEN3_INCLUDE_DIR=/apps/eigen/3.3.7/include/eigen3 -DUSE_CMAPLE=OFF ${cmake_params} ${custom_flags} $code_dir
make -j |& tee -a $work_dir/build.log


