# FPGA_Pong
Vivado Pong on PYNQ-Z2 with CPU-Controlled Opponent Displayed over HDMI

## Table of Contents

1. [Project Overview](#project-overview)  
2. [Repository Layout](#repository-layout)  
3. [Prerequisites](#prerequisites)  
4. [1. RTL Design](#1-rtl-design)  
   - 1.1 [Verilog Modules](#11-verilog-modules)  
   - 1.2 [Video Pipeline Stages](#12-video-pipeline-stages)  
   - 1.3 [AXI-Lite Control & MMIO](#13-axi-lite-control--mmio)  
5. [2. Simulation & Memory Testing](#2-simulation--memory-testing)  
   - 2.1 [Bitmap (.COE) Initialization](#21-bitmap-coe-initialization)  
   - 2.2 [Overlay & Game Logic Testbench](#22-overlay--game-logic-testbench)  
   - 2.3 [Waveform Inspection & Coverage](#23-waveform-inspection--coverage)  
6. [3. FPGA Integration (Block Diagram)](#3-fpga-integration-block-diagram)  
   - 3.1 [Zynq PS Reset & Clocks](#31-zynq-ps-reset--clocks)  
   - 3.2 [Custom IP: Pong Engines](#32-custom-ip-pong-engines)  
   - 3.3 [BRAM for “GAME OVER” Bitmap](#33-bram-for-game-over-bitmap)  
   - 3.4 [AXI-Lite Interfaces & LEDs](#34-axi-lite-interfaces--leds)  
7. [4. Hardware Bring-Up on PYNQ-Z2](#4-hardware-bring-up-on-pynq-z2)  
   - 4.1 [Constraints & I/O Planning](#41-constraints--io-planning)  
   - 4.2 [Bitstream Generation & Programming](#42-bitstream-generation--programming)  
   - 4.3 [On-Board Verification](#43-on-board-verification)  
8. [5. Test & Debug](#5-test--debug)  
   - 5.1 [Internal Logic Analyzer (ILA)](#51-internal-logic-analyzer-ila)  
   - 5.2 [Common Issues & Resolutions](#52-common-issues--resolutions)  
   - 5.3 [Lessons Learned](#53-lessons-learned)  
9. [6. Final Hardware Report](#6-final-hardware-report)  
   - 6.1 [Power Consumption](#61-power-consumption)  
   - 6.2 [Clocking Summary](#62-clocking-summary)  
   - 6.3 [Resource Utilization & Timing](#63-resource-utilization--timing)  
   - 6.4 [Block Diagram & Schematic](#64-block-diagram--schematic)  

---

## Project Overview

This repository contains a full-HDMI Pong game implemented on the PYNQ-Z2 board using Xilinx Vivado (Verilog/SystemVerilog) and Vitis (C) toolchains.  
- **Video Output:** 1280×720 @60 Hz over HDMI  
- **FPGA Logic:** Ball physics, paddle movement, scoring, “GAME OVER” overlay loaded from a 1280×200 bitmap in Block RAM  
- **CPU-Controlled AI:** Player 2 automated via an ARM-core C application (Vitis) talking over AXI-Lite  
- **Development Flow:**  
  1. RTL → Vivado block design → bitstream  
  2. Export hardware (HDF) → Vitis application → CPU player AI  

---

## Repository Layout

```text
/
├── rtl/                    # Verilog / SystemVerilog sources
│   ├── hdmi_transmit.sv    # TMDS encoder + video-timing controller
│   ├── object.v            # Ball & collision logic
│   ├── paddle.v            # Paddle #1
│   ├── paddle_two.v        # Paddle #2
│   ├── score_board.v       # On-screen score display
│   ├── gameover_bitmap.coe # COE for “GAME OVER” bitmap (1280×200)
│   └── top.v               # Top-level integrating all modules
├── tb/                     # Testbenches
│   ├── tb_overlay_top.v    # ROM + overlay functional testbench
│   └── tb_game_logic.v     # Pong game FSM + display logic tests
├── hw/                     # Vivado block-design & constraints
│   ├── design_1.bd         # Block design (PS, clocking, video)
│   ├── PYNQ-Z2.v2.xdc      # I/O constraints for HDMI, buttons, LEDs
│   └── gameover_bitmap.gen # Block Memory IP generated outputs
├── sw/                     # Vitis application for CPU AI player
│   ├── player2_ai.c        # Bare-metal C code controlling paddle_two
│   └── system_definition.tcl # Hardware export script
├── docs/                   # Schematics, timing reports, screenshots
├── README.md               # ← you are here
└── LICENSE
