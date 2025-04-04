#!/bin/bash
#SBATCH -p fpga
#SBATCH -A hpc-lco-kenter
#SBATCH -J "XRT Stream FPGA Julia"
#SBATCH -C xilinx_u280_xrt2.14
#SBATCH -t 06:00:00
#SBATCH -o results/stream_fpga_%j.log
#SBATCH -e results/stream_fpga_%j.log

module reset
ml lang JuliaHPC/1.10.4 fpga xilinx/xrt/2.14

num_runs=100
output_file="results/stream_fpga_hw_sync_buffers.csv"

mkdir -p "results"
echo "sep=," > $output_file
echo "xclbin,kernel,allocation,run,verify,total" >> $output_file

cp ../../../../stream/build_hw/stream.xclbin /dev/shm/stream.xclbin

for i in $(seq 1 $num_runs)
do
    xbutil reset --force -d 0000:a1:00.1
    result=$(julia stream_fpga_hw_sync_buffers.jl)

    while IFS= read -r line; do
        if [[ $line =~ ^[0-9] ]]; then
            echo -n "$line," >> $output_file
        fi
    done <<< "$result"
    echo "" >> $output_file
done

rm /dev/shm/stream.xclbin
