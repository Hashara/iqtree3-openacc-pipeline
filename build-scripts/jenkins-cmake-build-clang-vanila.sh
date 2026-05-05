#!/bin/bash

work_dir=$1 # build dir
code_dir=$2 # iqtree2 dir

params=$3

echo "building clang-vanila"
cmake_params="-DUSE_CUDA=OFF"

### pre steps #####
module load openmpi/4.1.5 boost/1.84.0 eigen/3.3.7 llvm/17.0.1

export OMPI_CC=clang
export OMPI_CXX=clang++

export CC=clang
export CXX=clang++

export LDFLAGS="-L/apps/llvm/17.0.1/lib"
export CPPFLAGS="-I/apps/llvm/17.0.1/lib/clang/17/include"


############

echo "building clang-vanila"

mkdir -p "$work_dir"
cd $work_dir
cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_CXX_FLAGS="$LDFLAGS $CPPFLAGS" -DEIGEN3_INCLUDE_DIR=/apps/eigen/3.3.7/include/eigen3 -DUSE_CMAPLE=OFF ${cmake_params} $code_dir > $work_dir/compiler.log 2>&1
make -j |& tee -a $work_dir/build.log
