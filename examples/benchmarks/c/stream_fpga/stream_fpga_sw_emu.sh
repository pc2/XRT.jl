#!/bin/bash
#SBATCH -p normal
#SBATCH -A hpc-lco-kenter
#SBATCH -J "XRT Stream FPGA C"
#SBATCH -N 1
#SBATCH -t 06:00:00
#SBATCH -o results/stream_fpga_%j.log
#SBATCH -e results/stream_fpga_%j.log

export XCL_EMULATION_MODE=sw_emu

module reset
ml fpga xilinx/xrt/2.14

num_runs=100
output_file="results/stream_fpga_sw_emu.csv"

mkdir -p "results"
echo "sep=," > $output_file
echo "device,xclbin,kernel,allocation,syncto,run,syncfrom,verify,total" >> $output_file

mkdir -p "build"
gcc -g -std=c11 -I$XILINX_XRT/include -L$XILINX_XRT/lib -o build/stream_fpga_sw_emu.out stream_fpga_sw_emu.c -lxrt_coreutil -pthread

cp ../../../stream/build_sw_emu/stream.xclbin /dev/shm/stream.xclbin

for i in $(seq 1 $num_runs)
do
    result=$(./build/stream_fpga_sw_emu.out)

    while IFS= read -r line; do
        if [[ $line =~ ^[0-9] ]]; then
            echo -n "$line," >> $output_file
        fi
    done <<< "$result"
    echo "" >> $output_file
done

rm /dev/shm/stream.xclbin
