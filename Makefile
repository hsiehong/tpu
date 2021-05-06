#==============================================================================#
# AIC2021 Project1 - TPU Design                                                #
# file: Makefile                                                               #
# description: Makefile for TPU testbench                                      #
# authors: kaikai (deekai9139@gmail.com)                                       #
#          suhan  (jjs93126@gmail.com)                                         #
#==============================================================================#

#------------------------------------------------------------------------------#
# Change your own verilog compiler.                                            #
#------------------------------------------------------------------------------#
#VERILOG=irun
VERILOG=ncverilog
#VERILOG=iverilog

#------------------------------------------------------------------------------#
# Directories Declarations                                                     #
#------------------------------------------------------------------------------#
CUR_DIR=$(PWD)
TB_DIR=tb
BUILD_DIR=build
SRC_DIR=src
INC_DIR=inc

test1:
	#cd $(TB_DIR) && python3 matmul.py inputs1
	$(VERILOG) tb/top_tb.v \
    +incdir+$(PWD)/$(SRC_DIR)+$(PWD)/$(TB_DIR)+$(PWD)/$(BUILD_DIR)/input1 +define+test1 \
	+access+r +nc64bit


test2:
	#cd $(TB_DIR) && python3 matmul.py inputs2
	$(VERILOG) tb/top_tb.v \
    +incdir+$(PWD)/$(SRC_DIR)+$(PWD)/$(TB_DIR)+$(PWD)/$(BUILD_DIR)/input2 +define+test2	\
	+access+r +nc64bit

test3:
	#cd $(TB_DIR) && python3 matmul.py inputs3
	$(VERILOG) tb/top_tb.v \
    +incdir+$(PWD)/$(SRC_DIR)+$(PWD)/$(TB_DIR)+$(PWD)/$(BUILD_DIR)/input3 +define+test3	\
	+access+r +nc64bit

monster:
	#cd $(TB_DIR) && python3 matmul.py monster
	$(VERILOG) tb/top_tb.v \
    +incdir+$(PWD)/$(SRC_DIR)+$(PWD)/$(TB_DIR)+$(PWD)/$(BUILD_DIR)/monster +define+monster	\
	+access+r +nc64bit

others:
	$(VERILOG) tb/top_tb.v \
    +incdir+$(PWD)/$(SRC_DIR)+$(PWD)/$(TB_DIR)+$(PWD)/$(BUILD_DIR) +define+monster	\
	+access+r +nc64bit

clean:
	rm -rf build
