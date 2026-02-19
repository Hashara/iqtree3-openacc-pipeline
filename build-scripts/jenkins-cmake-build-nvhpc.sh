#!/bin/bash

work_dir=$1 # build dir
code_dir=$2 # iqtree2 dir

params=$3


###### handle arguments ######

#work_dir=$1 # build dir
#code_dir=$2 # iqtree2 dir
#
#params=$


### pre steps #####
module load openmpi/4.1.5 boost/1.84.0 nvhpc-compilers/24.7

export PATH="$NVHPC_CUDA_HOME/bin:$PATH"

export OMPI_CC=nvc
export OMPI_CXX=nvc++

export CC=nvc
export CXX=nvc++

export NVHPC_CUDA_HOME=/apps/nvidia-hpc-sdk/24.7/Linux_x86_64/24.7/cuda
export CUDACXX=nvcc

export LDFLAGS="-L/apps/nvidia-hpc-sdk/24.7/Linux_x86_64/24.7/compilers/lib"
export CPPFLAGS="-I/apps/nvidia-hpc-sdk/24.7/Linux_x86_64/24.7/compilers/include"


############

echo "building nvhpc-vanila"

mkdir -p "$work_dir"
cd $work_dir
cmake -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" \
      -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen-3.4.0 -DUSE_CMAPLE=OFF -DUSE_CUDA=ON $code_dir
make -j > $work_dir/build.log 2>&1


