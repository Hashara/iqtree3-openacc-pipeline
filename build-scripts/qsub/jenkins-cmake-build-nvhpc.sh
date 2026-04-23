#!/bin/bash

#PBS -l ncpus=4
#PBS -l mem=48GB
#PBS -l jobfs=100GB
#PBS -q normal
#PBS -P dx61
#PBS -l walltime=01:00:00
#PBS -l storage=scratch/dx61
#PBS -l wd

###### handle arguments ######

work_dir=$ARG1 # build dir
code_dir=$ARG2 # iqtree2 dir

params=$ARG3
gpu_arch=$ARG4 # GPU architecture (e.g. cc70, cc80, cc90). Empty = multi-arch default

###### handle arguments ######

#work_dir=$1 # build dir
#code_dir=$2 # iqtree2 dir
#
#params=$3

if [ "$params" == "CUDA" ]; then
    echo "building nvhpc-cuda"
    cmake_params="-DUSE_CUDA=ON"
elif [ "$params" == "OPENACC_PROFILE" ]; then
    echo "building nvhpc-OpenACC with profiling"
    cmake_params="-DUSE_OPENACC=ON -DUSE_OPENACC_PROFILE=ON"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENACC_DEBUG" ]; then
    echo "building nvhpc-OpenACC with debug build"
    cmake_params="-DUSE_OPENACC=ON -DCMAKE_BUILD_TYPE=Debug"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENACC_DEBUG_PROFILE" ]; then
    echo "building nvhpc-OpenACC with debug build and profiling"
    cmake_params="-DUSE_OPENACC=ON -DUSE_OPENACC_PROFILE=ON -DCMAKE_BUILD_TYPE=Debug"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENACC" ]; then
    echo "building nvhpc-OpenACC"
    cmake_params="-DUSE_OPENACC=ON"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
else
    echo "building nvhpc-vanila"
    cmake_params="-DUSE_CUDA=OFF"
fi


### pre steps #####
module load openmpi/4.1.5 boost/1.84.0 nvhpc-compilers/24.7 cuda/12.5.1

export OMPI_CC=nvc
export OMPI_CXX=nvc++

export CC=nvc
export CXX=nvc++

export CUDACXX=nvcc

export LDFLAGS="-L/apps/nvidia-hpc-sdk/24.7/Linux_x86_64/24.7/compilers/lib"
export CPPFLAGS="-I/apps/nvidia-hpc-sdk/24.7/Linux_x86_64/24.7/compilers/include"


############


echo "building nvhpc-cuda"

mkdir -p "$work_dir"
cd $work_dir
#cmake -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen-3.4.0 -DUSE_CMAPLE=OFF -DUSE_CUDA=ON $code_dir
if [ "$params" == "CUDA" ]; then
cmake -S "$code_dir" -B "$work_dir" \
  -DCMAKE_C_COMPILER=nvc \
  -DCMAKE_CXX_COMPILER=nvc++ \
  -DCMAKE_CUDA_COMPILER="$(command -v nvcc)" \
  -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
  -DCUDAToolkit_ROOT="$(dirname "$(dirname "$(command -v nvcc)")")" \
  -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen-3.4.0 \
  -DUSE_CMAPLE=OFF \
  $cmake_params > $work_dir/compiler.log 2>&1
elif [ "$params" == "OPENACC" ] || [ "$params" == "OPENACC_PROFILE" ] || [ "$params" == "OPENACC_DEBUG" ] || [ "$params" == "OPENACC_DEBUG_PROFILE" ]; then
    cmake -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen-3.4.0 -DUSE_CMAPLE=OFF ${cmake_params} $code_dir > $work_dir/compiler.log 2>&1
fi
make -j > $work_dir/build.log 2>&1






