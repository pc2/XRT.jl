#!/bin/bash
#SBATCH -p fpga
#SBATCH -A hpc-lco-kenter
#SBATCH -J "XRT Stream FPGA C"
#SBATCH -C xilinx_u280_xrt2.14
#SBATCH -t 06:00:00
#SBATCH -o results/stream_fpga_%j.log
#SBATCH -e results/stream_fpga_%j.log

module reset
ml fpga xilinx/xrt/2.14

num_runs=100
output_file="results/stream_fpga_hw.csv"

mkdir -p "results"
echo "sep=," > $output_file
echo "device,xclbin,kernel,allocation,syncto,run,syncfrom,verify,total" >> $output_file

mkdir -p "build"
gcc -g -std=c11 -I$XILINX_XRT/include -L$XILINX_XRT/lib -o build/stream_fpga_hw.out stream_fpga_hw.c -lxrt_coreutil -pthread

cp ../../../stream/build_hw/stream.xclbin /dev/shm/stream.xclbin

for i in $(seq 1 $num_runs)
do
    xbutil reset --force -d 0000:a1:00.1
    result=$(./build/stream_fpga_hw.out)   

    while IFS= read -r line; do
        if [[ $line =~ ^[0-9] ]]; then
            echo -n "$line," >> $output_file
        fi
    done <<< "$result"
    echo "" >> $output_file
done

rm /dev/shm/stream.xclbin
