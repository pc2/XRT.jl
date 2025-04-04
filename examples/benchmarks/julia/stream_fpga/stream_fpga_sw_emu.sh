#!/bin/bash
#SBATCH -p normal
#SBATCH -A hpc-lco-kenter
#SBATCH -J "XRT Stream FPGA Julia"
#SBATCH -t 06:00:00
#SBATCH -N 1
#SBATCH -o results/stream_fpga_%j.log
#SBATCH -e results/stream_fpga_%j.log

export XCL_EMULATION_MODE=sw_emu

module reset
ml lang JuliaHPC/1.10.4 fpga xilinx/xrt/2.14

num_runs=100
output_file="results/stream_fpga_sw_emu.csv"

mkdir -p "results"
echo "sep=," > $output_file
echo "xclbin,kernel,allocation,syncto,run,syncfrom,verify,total" >> $output_file

cp ../../../stream/build_sw_emu/stream.xclbin /dev/shm/stream.xclbin

for i in $(seq 1 $num_runs)
do
    result=$(julia stream_fpga_sw_emu.jl)

    while IFS= read -r line; do
        if [[ $line =~ ^[0-9] ]]; then
            echo -n "$line," >> $output_file
        fi
    done <<< "$result"
    echo "" >> $output_file
done

rm /dev/shm/stream.xclbin