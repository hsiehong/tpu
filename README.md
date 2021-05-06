IC2021 Project1 - TPU(hsiehong)
###### tags: `aic2021` 

## [Project Description](https://hackmd.io/@hsieh22/aic2021-tpu_spec)

* In this project, I implement a systolic array to do `m*k` * `k*n` matrix multiplication, where the constraint of `m`, `k`, `n` are `1 < m, k, n < 10`
     
    
## Project Architecture
* Overview of this project, mainly I implement the TPU part to do matrix multiply operation.
    ![](https://i.imgur.com/W87ljZL.png)
    
* Overview Architecture of `TPU` module

    ![](https://i.imgur.com/XL78H1c.jpg)
    
    
    
* Overview Architecture of `PE` module
* notice that I accumulate partial sum in other buffer, not store in `PE`，the jobs `PE` will do are that multiple and transfer input data to next `PE`
    ![](https://i.imgur.com/XKLxSK3.jpg)
    
    
    
## Data preprocess flow & Data flow
* Take a example for two matrix multiplication `A` and `B`, `A` is `9*9` and `B` is `9*9`, the red frame and number on matrix is the input order.
* `A` : ![](https://i.imgur.com/8mZGtrR.png)
    
*  `B` : ![](https://i.imgur.com/M1yWLiu.png)
    
* Because the design of systolic array is 4*4, we can do at most 4 rows in a round, that is limited by the size of systolic array, at the same time I read whole column each round, which is limited by `k`, so I set it to the max size `9`, if the input matrix is less than 9, the remaining value will be padded 0.
    
* In my design, I read `4*9` input each round and store them, at the same time I read input, I will adjust them to suitable format, so when I read done the input, I can easily feed the adjusted array to my PE.
* Take example for first round, the input array will be adjusted to a parallelogram array, the padding zeros are required in order to let the item meet in the correct time and position.
* After (k+7) cycle(include a delay cycle), each round will get the correct value, then write back to global buffer.
    
    ![](https://i.imgur.com/kzvmrJL.png)
    
* Because I want to make the output index contiguous, according to the rule of matrix multiplication, I fixed the buffer of matrix `b` until all rows in matrix `a` has benn calculate, so the content of next round should be:
    
    ![](https://i.imgur.com/2R6UQCb.png)
    
* There is still one row not be calculated, the unsufficient rows will be padded 0, so the next round should be
    ![](https://i.imgur.com/9KUVSpT.png)
    
* Then I do the same action to matrix `b`, until the all operation is done.
    
## Function simulation result
* `m*k` * `k*n`
    
    
    
* ![](https://i.imgur.com/RBm9wyg.png)
    
* ![](https://i.imgur.com/WsFmAiw.png)
    
* ![](https://i.imgur.com/GVsFG4j.png)
    
* ![](https://i.imgur.com/SAkymPb.png)
    ![](https://i.imgur.com/PnSZFrc.png)
    
* ![](https://i.imgur.com/S95aZ2j.png)
    
* ![](https://i.imgur.com/nxEpLSY.png)
    
* ![](https://i.imgur.com/WUGUxTe.png)
    
* ![](https://i.imgur.com/cFx838X.png)
    
    
    
## Synthesis result
    
### Area information
    ![](https://i.imgur.com/xmmjdfE.png)
    
### Timing information
    ![](https://i.imgur.com/hWd8mVT.png)
    
### Constraint file
tpu.sdc    
    
    set cycle  15        ;#clock period defined by designer
    
    create_clock -period $cycle [get_ports  clk]
    set_dont_touch_network      [get_clocks clk]
    set_clock_uncertainty  0.1  [get_clocks clk]
    set_clock_latency      0.5  [get_clocks clk]
    set_ideal_network           [get_ports clk]
    
    set_input_delay  5      -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
    set_output_delay 0.5    -clock clk [all_outputs] 
    set_load         0.1     [all_outputs]
    set_drive        1     [all_inputs]
    
    set_operating_conditions  -max slow  -min fast
    set_wire_load_model -name tsmc13_wl10 -library slow                        
    
    set_max_fanout 20 [all_inputs]
    
    
## Attachments
* src
    * define.v : definition file
    * global_buffer.v : declaration of buffer and memory
    * top.v : the top module
    * **tpu.v** : mainly file, implement TPU and PE module here.
* tb
    * input
        * the matrix test set
    * matmul.py : generate matrix a, matrix b and golden.
    * top_tn : testbentch