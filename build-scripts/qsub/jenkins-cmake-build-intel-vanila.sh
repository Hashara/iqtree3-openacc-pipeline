#!/bin/bash

#PBS -l ncpus=8
#PBS -l mem=32GB
#PBS -l jobfs=100GB
#PBS -q normalsr
#PBS -P dx61
#PBS -l walltime=01:00:00
#PBS -l storage=scratch/dx61
#PBS -l wd

###### handle arguments ######

work_dir=$ARG1 # build dir
code_dir=$ARG2 # iqtree2 dir

params=$ARG3

echo "building intel-vanila (normal SR)"

### pre steps #####
module load openmpi/4.1.5 boost/1.84.0 eigen/3.3.7 intel-compiler-llvm/2024.2.1

export OMPI_CC=icx
export OMPI_CXX=icpx

export CC=icx
export CXX=icpx

############

mkdir -p "$work_dir"
cd $work_dir
cmake "$code_dir" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_CXX_COMPILER=icpx \
    -DCMAKE_C_COMPILER=icx \
    -DIQTREE_FLAGS="avx512" \
    -DCMAKE_CXX_FLAGS="-O3 -xSAPPHIRERAPIDS -fno-omit-frame-pointer" \
    -DCMAKE_C_FLAGS="-O3 -xSAPPHIRERAPIDS -fno-omit-frame-pointer" \
    -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld" \
    -DEIGEN3_INCLUDE_DIR=/apps/eigen/3.3.7/include/eigen3 \
    -DUSE_CMAPLE=OFF > $work_dir/compiler.log 2>&1
make -j > $work_dir/build.log 2>&1
