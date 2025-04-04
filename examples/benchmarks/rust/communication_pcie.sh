#!/bin/bash
#SBATCH -p fpga
#SBATCH -A hpc-lco-kenter
#SBATCH -J "XRT Com PCIe FPGA Rust"
#SBATCH -t 04:00:00
#SBATCH -C xilinx_u280_xrt2.14
#SBATCH -o results/stream_fpga_%j.log
#SBATCH -e results/stream_fpga_%j.log

module reset
ml lang Rust compiler Clang fpga xilinx/xrt/2.14

num_runs=100
output_file="results/communication_pcie.csv"

mkdir -p "results"
echo "sep=," > $output_file
echo "device,xclbin,kernel,allocation,syncto,run,syncfrom,verify,total" >> $output_file

cargo build

cp ../communication_PCIE.xclbin /dev/shm/communication_PCIE.xclbin

for i in $(seq 1 $num_runs)
do
    xbutil reset --force -d 0000:a1:00.1
    result=$(cargo run --bin communication_pcie)   
    
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9] ]]; then
            echo -n "$line," >> $output_file
        fi
    done <<< "$result"
    echo "" >> $output_file
done

rm /dev/shm/communication_PCIE.xclbin
