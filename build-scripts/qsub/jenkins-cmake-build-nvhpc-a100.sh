#!/bin/bash

#PBS -l ncpus=16
#PBS -l ngpus=1
#PBS -l mem=64GB
#PBS -l jobfs=100GB
#PBS -q dgxa100
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

if [ "$params" == "CUDA" ]; then
    echo "building nvhpc-cuda"
    cmake_params="-DUSE_CUDA=ON"
elif [ "$params" == "IQTREE_GPU" ]; then
    echo "building nvhpc-IQTREE_GPU (CUDA JOLT + OpenACC GPU likelihood)"
    cmake_params="-DIQTREE_GPU=ON -DUSE_OPENACC=ON -DUSE_CUDA=OFF"
    if [ -n "$gpu_arch" ]; then
        # OpenACC GPU likelihood needs GPU_ARCH (ccNN); the in-tree CUDA JOLT kernels need
        # CMAKE_CUDA_ARCHITECTURES (NN). cc70->70 V100, cc80->80 A100, cc90->90 H200.
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch} -DCMAKE_CUDA_ARCHITECTURES=${gpu_arch#cc}"
        echo "GPU arch: ${gpu_arch} (OpenACC likelihood) + ${gpu_arch#cc} (CUDA JOLT)"
    else
        echo "GPU arch: default"
    fi
elif [ "$params" == "OPENACC_PROFILE" ]; then
    echo "building nvhpc-OpenACC with profiling"
    cmake_params="-DUSE_OPENACC=ON -DUSE_OPENACC_PROFILE=ON -DIQTREE_GPU=OFF"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENACC_DEBUG" ]; then
    echo "building nvhpc-OpenACC with debug build"
    cmake_params="-DUSE_OPENACC=ON -DCMAKE_BUILD_TYPE=Debug -DIQTREE_GPU=OFF"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENACC_DEBUG_PROFILE" ]; then
    echo "building nvhpc-OpenACC with debug build and profiling"
    cmake_params="-DUSE_OPENACC=ON -DUSE_OPENACC_PROFILE=ON -DCMAKE_BUILD_TYPE=Debug -DIQTREE_GPU=OFF"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENACC" ]; then
    echo "building nvhpc-OpenACC"
    cmake_params="-DUSE_OPENACC=ON -DIQTREE_GPU=OFF"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENMP_GPU_PROFILE" ]; then
    echo "building nvhpc-OpenMP GPU with profiling"
    cmake_params="-DUSE_OPENMP_GPU=ON -DUSE_OPENMP_GPU_PROFILE=ON"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENMP_GPU_DEBUG" ]; then
    echo "building nvhpc-OpenMP GPU with debug build"
    cmake_params="-DUSE_OPENMP_GPU=ON -DCMAKE_BUILD_TYPE=Debug"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENMP_GPU_DEBUG_PROFILE" ]; then
    echo "building nvhpc-OpenMP GPU with debug build and profiling"
    cmake_params="-DUSE_OPENMP_GPU=ON -DUSE_OPENMP_GPU_PROFILE=ON -DCMAKE_BUILD_TYPE=Debug"
    if [ -n "$gpu_arch" ]; then
        cmake_params="${cmake_params} -DGPU_ARCH=${gpu_arch}"
        echo "GPU_ARCH: ${gpu_arch} (single-arch build)"
    else
        echo "GPU_ARCH: default (cc70,cc80,cc90)"
    fi
elif [ "$params" == "OPENMP_GPU" ]; then
    echo "building nvhpc-OpenMP GPU"
    cmake_params="-DUSE_OPENMP_GPU=ON"
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


echo "building on dgxa100 queue (A100)"

mkdir -p "$work_dir"
cd $work_dir
if [ "$params" == "CUDA" ] || [ "$params" == "IQTREE_GPU" ]; then
module load gcc/12.2.0                  # CUDA 12.5 .cu host compiler (system g++ 8.5 is too old)
[ -n "$CUDA_HOME" ] && export NVHPC_CUDA_HOME="$CUDA_HOME"   # align nvc++ -acc CUDA with the nvcc toolkit (combined build)
cmake -S "$code_dir" -B "$work_dir" \
  -DCMAKE_C_COMPILER=nvc \
  -DCMAKE_CXX_COMPILER=nvc++ \
  -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" \
  -DCMAKE_CUDA_COMPILER="$(command -v nvcc)" \
  -DCMAKE_CUDA_HOST_COMPILER="$(command -v g++)" \
  -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
  -DCUDAToolkit_ROOT="$(dirname "$(dirname "$(command -v nvcc)")")" \
  -DTHREADS_PREFER_PTHREAD_FLAG=ON \
  -DCMAKE_THREAD_LIBS_INIT=-lpthread \
  -DCMAKE_HAVE_THREADS_LIBRARY=1 \
  -DCMAKE_USE_PTHREADS_INIT=1 \
  -DCMAKE_USE_WIN32_THREADS_INIT=0 \
  -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen-3.4.0 \
  -DUSE_CMAPLE=OFF \
  $cmake_params > $work_dir/compiler.log 2>&1
elif [ "$params" == "OPENACC" ] || [ "$params" == "OPENACC_PROFILE" ] || [ "$params" == "OPENACC_DEBUG" ] || [ "$params" == "OPENACC_DEBUG_PROFILE" ]; then
    cmake -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen-3.4.0 -DUSE_CMAPLE=OFF ${cmake_params} $code_dir > $work_dir/compiler.log 2>&1
elif [ "$params" == "OPENMP_GPU" ] || [ "$params" == "OPENMP_GPU_PROFILE" ] || [ "$params" == "OPENMP_GPU_DEBUG" ] || [ "$params" == "OPENMP_GPU_DEBUG_PROFILE" ]; then
    cmake -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" -DEIGEN3_INCLUDE_DIR=/scratch/dx61/sa0557/iqtree2/eigen-3.4.0 -DUSE_CMAPLE=OFF ${cmake_params} $code_dir > $work_dir/compiler.log 2>&1
fi
make -j > $work_dir/build.log 2>&1
