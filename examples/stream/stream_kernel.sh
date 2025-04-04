#!/bin/bash
#SBATCH -p normal
#SBATCH -q fpgasynthesis
#SBATCH -t 8:00:00
#SBATCH -n 16
#SBATCH --mem=50g
#SBATCH -o stream_synth_%j.log
#SBATCH -e stream_synth_%j.log
#SBATCH -J stream_synth
 
module reset
module load fpga xilinx/xrt/2.15
 
make all TARGET=hw