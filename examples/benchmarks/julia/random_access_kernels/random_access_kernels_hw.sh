#!/bin/bash
#SBATCH -p fpga
#SBATCH -A hpc-lco-kenter
#SBATCH -J "XRT RandomAccessKernels FPGA Julia"
#SBATCH -t 06:00:00
#SBATCH -C xilinx_u280_xrt2.14
#SBATCH -o results/stream_fpga_%j.log
#SBATCH -e results/stream_fpga_%j.log

ml lang JuliaHPC/1.10.4 fpga xilinx/xrt/2.14

num_runs=100
output_file="results/random_access_kernels_hw.csv"

mkdir -p "results"
echo "sep=," > $output_file
echo "xclbin,kernel,allocation,syncto,run,syncfrom,verify,total" >> $output_file

cp ../../random_access_kernels_single.xclbin /dev/shm/random_access_kernels_single.xclbin

for i in $(seq 1 $num_runs)
do
    xbutil reset --force -d 0000:a1:00.1
    result=$(julia random_access_kernels_hw.jl)

    while IFS= read -r line; do
        if [[ $line =~ ^[0-9] ]]; then
            echo -n "$line," >> $output_file
        fi
    done <<< "$result"
    echo "" >> $output_file
done

rm /dev/shm/random_access_kernels_single.xclbin
