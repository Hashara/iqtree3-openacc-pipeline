#!/bin/bash

#PBS -l ncpus=48
#PBS -l mem=190GB
#PBS -l jobfs=40GB
#PBS -q normal
#PBS -P dx61
#PBS -l walltime=01:00:00
#PBS -l storage=scratch/dx61
#PBS -l wd

###### handle arguments ######

work_dir=$ARG1 # build dir
code_dir=$ARG2 # iqtree2 dir

params=$ARG3

###### handle arguments ######

#work_dir=$1 # build dir
#code_dir=$2 # iqtree2 dir
#
#params=$3

if [ "$params" == "openacc-profile" ]; then
    echo "building nvhpc-openacc with profiling"
    cmake_params="-DUSE_OPENACC=ON -DUSE_OPENACC_PROFILE=ON"
elif [ "$params" == "openacc" ]; then
    echo "building nvhpc-openacc"
    cmake_params="-DUSE_OPENACC=ON"
else
    echo "building nvhpc-vanila"
    cmake_params="-DUSE_OPENACC=OFF"
fi


### pre steps #####
module load openmpi/4.1.5 boost/1.84.0 nvhpc-compilers/24.7


export OMPI_CC=nvc
export OMPI_CXX=nvc++

export CC=nvc
export CXX=nvc++
export CUDACXX=nvcc

export LDFLAGS="-L/apps/nvidia-hpc-sdk/24.7/Linux_x86_64/24.7/compilers/lib"
export CPPFLAGS="-I/apps/nvidia-hpc-sdk/24.7/Linux_x86_64/24.7/compilers/include"


############

echo "building nvhpc-vanila"

mkdir -p "$work_dir"
cd $work_dir
cmake -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen -DUSE_CMAPLE=OFF ${cmake_params} $code_dir
make -j > $work_dir/build.log 2>&1


