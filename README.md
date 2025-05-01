# Building a Hardware Neural Network Accelerator from Scratch with an FPGA

**Saurabh Jayaram**  
*Follow · 7 min read · Aug 25, 2024*

**At the time of this project, the best AI model was GPT-4, which was pretty bad at Verilog. I'm sure as of April 2025, reasoning models such as o4 would have make this project a lot easier.**
**Full technical writeup:** https://medium.com/@sunny.jyrm/building-a-hardware-neural-network-accelerator-from-scratch-with-an-fpga-f2d67c163f20  
**Camera and VGA interfaces forked from:** https://github.com/LIU-Zisen/Basys3-Camera

---

## Table of Contents

1. [Internal Hardware Architecture](#internal-hardware-architecture)  
2. [Core Matrix Multiplier — Systolic Array](#core-matrix-multiplier—systolic-array)  
   - [MAC Module](#mac-module)  
   - [Matrix-Multiply (MM) Module](#matrix-multiply-mm-module)  
3. [Storing and Bussing Weights](#storing-and-bussing-weights)  
4. [Assembling the Network](#assembling-the-network)  
5. [ArgMax Circuit](#argmax-circuit)  
6. [Physical Testing Apparatus](#physical-testing-apparatus)  
7. [Timing Evaluation](#timing-evaluation)  
8. [M2 CPU Comparison](#m2-cpu-comparison)  
9. [Reflection](#reflection)  
10. [Sources](#sources)  

---

## Internal Hardware Architecture

In this article, I’m going to dive into a month’s-long journey to build a neural network accelerator from scratch on an FPGA. The core of the design is a systolic array architecture, which is a popular design for accelerating matrix multiplication (more details below). Exact timing simulations in Vivado revealed that this implementation carries out the required matrix multiplication for running inference **32.2× faster** than C++ on an M2 CPU (Apple clang 14.0.3). All code is available on GitHub: [sun-jay/FPGA-Hardware-NN-Accelerator](https://github.com/sun-jay/FPGA-Hardware-NN-Accelerator).

---

## Core Matrix Multiplier — Systolic Array

The systolic array architecture is already found in many neural network accelerators—including Google’s TPU and Tesla’s Full Self-Driving chip. It leverages the simple, repetitive nature of matrix multiplication and maximizes datapoint reuse. It can carry out an \(n \times n\) matrix multiplication in \(O(n)\) time, at the cost of \(O(n^2)\) hardware area.

![Systolic Array Architecture](https://www.mdpi.com/2079-9292/9/2/338)

### MAC Module

The fundamental unit is the **multiply–accumulate (MAC)** module. Each clock cycle it receives two inputs, multiplies them, adds to a running sum, and forwards the inputs to its neighbors:

```verilog
// Module MAC (chainMod)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        numOutSide <= {bit_res{1'b0}};
        numOutTop  <= {bit_res{1'b0}};
        sum        <= {bit_res{1'b0}};
    end else begin
        // pass A and B on
        numOutSide <= numInSide;
        numOutTop  <= numInTop;

        // multiply and accumulate
        product    = numInSide * numInTop;
        sum        <= sum + (product >>> frac_bits); // fixed-point adjustment
    end
end
