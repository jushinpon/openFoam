#!/bin/sh
#SBATCH --output=openfoam
#SBATCH --job-name=cavity
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=All
##SBATCH --ntasks-per-node=12
##SBATCH --exclude=node23
module load mpi
source /usr/lib/openfoam/openfoam2406/etc/bashrc
rm -r processor*

#for parallel computing, you need to provide the decomposeParDict file
sed -i "s/numberOfSubdomains [0-9]\+/numberOfSubdomains $(nproc)/" system/decomposeParDict

decomposePar -force

mpiexec -np $(nproc) icoFoam -parallel

reconstructPar

rm -r processor*

#for paraview
touch paraview.foam 