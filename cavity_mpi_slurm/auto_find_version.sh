#!/bin/sh
#SBATCH --output=cavity.log
#SBATCH --job-name=cavity
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=All
##SBATCH --ntasks-per-node=12
##SBATCH --exclude=node23
#SBATCH --export=ALL
#SBATCH --get-user-env=L

echo hostname: $(hostname)
echo date: $(date)
# ensure 'module' command is defined (for clusters that don't preload it)
if ! type module &>/dev/null; then
    if [ -f /usr/share/Modules/init/bash ]; then
        source /usr/share/Modules/init/bash
    elif [ -f /etc/profile.d/modules.sh ]; then
        source /etc/profile.d/modules.sh
    fi
fi

module load mpi
echo "which mpiexec: $(which mpiexec)"

# === Dynamically detect OpenFOAM version ===
foam_base="/usr/lib/openfoam"
if [ -d "$foam_base" ]; then
    # Pick the latest installed version (e.g. openfoam2406, openfoam2312, etc.)
    foam_dir=$(ls -d $foam_base/openfoam* 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$foam_dir" ] && [ -f "$foam_dir/etc/bashrc" ]; then
        echo "[INFO] Detected OpenFOAM version: $(basename $foam_dir)"
        source "$foam_dir/etc/bashrc"
    else
        echo "[ERROR] No valid OpenFOAM bashrc found in $foam_base."
        exit 1
    fi
else
    echo "[ERROR] OpenFOAM base directory not found: $foam_base"
    exit 1
fi

# === Clean up and prepare ===
rm -rf processor*

# for parallel computing, ensure decomposeParDict matches core count
sed -i "s/numberOfSubdomains [0-9]\+/numberOfSubdomains $(nproc)/" system/decomposeParDict

# === Run OpenFOAM in parallel ===
decomposePar -force
mpiexec -np $(nproc) icoFoam -parallel
reconstructPar

# === Clean up ===
rm -rf processor*

# for ParaView visualization
touch paraview.foam
