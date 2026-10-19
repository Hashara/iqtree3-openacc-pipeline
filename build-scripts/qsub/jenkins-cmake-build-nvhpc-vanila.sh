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
    cmake_params="-DUSE_OPENACC=ON -DUSE_OPENACC_PROFILE=ON -DIQTREE_GPU=OFF"
elif [ "$params" == "openacc" ]; then
    echo "building nvhpc-openacc"
    cmake_params="-DUSE_OPENACC=ON -DIQTREE_GPU=OFF"
elif [ "$params" == "iqtree_gpu" ] || [ "$params" == "IQTREE_GPU" ]; then
    echo "building nvhpc-IQTREE_GPU (in-tree CUDA ModelFinder kernels)"
    cmake_params="-DIQTREE_GPU=ON -DUSE_OPENACC=OFF -DUSE_CUDA=OFF"
else
    echo "building nvhpc-vanila"
    cmake_params="-DUSE_OPENACC=OFF -DIQTREE_GPU=OFF"
fi


### pre steps #####
if [ "$params" == "iqtree_gpu" ] || [ "$params" == "IQTREE_GPU" ]; then
    module load openmpi/4.1.5 boost/1.84.0 nvhpc-compilers/24.7 cuda/12.5.1
else
    module load openmpi/4.1.5 boost/1.84.0 nvhpc-compilers/24.7
fi


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
if [ "$params" == "iqtree_gpu" ] || [ "$params" == "IQTREE_GPU" ]; then
    cmake -S "$code_dir" -B "$work_dir" \
      -DCMAKE_C_COMPILER=nvc \
      -DCMAKE_CXX_COMPILER=nvc++ \
      -DCMAKE_CUDA_COMPILER="$(command -v nvcc)" \
      -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
      -DCUDAToolkit_ROOT="$(dirname "$(dirname "$(command -v nvcc)")")" \
      -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen \
      -DUSE_CMAPLE=OFF \
      ${cmake_params}
else
    cmake -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen -DUSE_CMAPLE=OFF ${cmake_params} $code_dir
fi
make -j > $work_dir/build.log 2>&1


