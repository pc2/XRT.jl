
### FPGA Kernel Synthesis/Emulation Options
# Select the FPGA target platform for synthesis
# PLATFORM ?= xilinx_u280_xdma_201920_3
PLATFORM ?= xilinx_u280_gen3x16_xdma_1_202211_1
# Choose the synthesis target (hw, hw_emu, sw_emu)
TARGET ?= hw
# FPGA kernel sources
KERNEL_SRC ?= stream_kernel.cpp

# Use .xsa file ending if QDMA shell is used
ifneq (,$(findstring _xdma_,$(PLATFORM)))
	BITSTREAM_FILE_ENDING = xclbin
else
	BITSTREAM_FILE_ENDING = xsa
endif

### FPGA Kernels and Measurement Library
# Name of the FPGA kernel
KERNEL_NAME ?= stream_calc
# Build directory used for synthesis and compiling host code
BUILD_DIR ?= build_$(TARGET)
# Name of the bitstream (only used for synthesis)
XCLBIN=$(BUILD_DIR)/stream.$(BITSTREAM_FILE_ENDING)
KERNEL_OBJ = $(patsubst %.cpp, $(BUILD_DIR)/%.xo, $(notdir $(KERNEL_SRC)))

CONFIGFILE_LINK ?= link_stream.cfg
CONFIG = --config $(CONFIGFILE_LINK)



.PHONY: all bitstream

# Build FPGA bitstream and library by default
all: bitstream

$(KERNEL_OBJ): $(KERNEL_SRC)
	mkdir -p $(BUILD_DIR)
	v++ -t $(TARGET) --compile --kernel_frequency 500 --platform $(PLATFORM) --save-temps -k $(KERNEL_NAME) --temp_dir $(BUILD_DIR) -o $@ $^

$(XCLBIN): $(KERNEL_OBJ)
	v++ --link -t $(TARGET) --kernel_frequency 500 --platform $(PLATFORM) --save-temps --temp_dir $(BUILD_DIR) $(CONFIG) -o $@ $^

bitstream: $(XCLBIN)