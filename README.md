# Pong on PYNQ-Z2 (HDMI + CPU-Controlled AI)

A hardware-accelerated implementation of the classic Pong game, built end-to-end in Xilinx Vivado and Vitis for the PYNQ-Z2 board.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Layout](#repository-layout)
3. [Prerequisites](#prerequisites)
4. [1. RTL Design](#1-rtl-design)

   * 1.1 [Verilog/SystemVerilog Modules](#11-verilogsystemverilog-modules)
   * 1.2 [Video Pipeline Stages](#12-video-pipeline-stages)
   * 1.3 [Memory-Mapped I/O](#13-memory-mapped-io)
5. [2. Simulation & Memory Testing](#2-simulation--memory-testing)

   * 2.1 [Bitmap (.COE) Initialization](#21-bitmap-coe-initialization)
   * 2.2 [Overlay & Game Logic Testbench](#22-overlay--game-logic-testbench)
   * 2.3 [Waveform Inspection & Coverage](#23-waveform-inspection--coverage)
6. [3. FPGA Integration (Block Diagram)](#3-fpga-integration-block-diagram)

   * 3.1 [Zynq PS Reset & Clocking](#31-zynq-ps-reset--clocking)
   * 3.2 [Custom IP: Pong Engines](#32-custom-ip-pong-engines)
   * 3.3 [BRAM for “GAME OVER” Bitmap](#33-bram-for-game-over-bitmap)
   * 3.4 [AXI-Lite & LEDs](#34-axi-lite--leds)
7. [4. Hardware Bring-Up on PYNQ-Z2](#4-hardware-bring-up-on-pynq-z2)

   * 4.1 [Constraints & I/O Planning](#41-constraints--io-planning)
   * 4.2 [Bitstream Generation & Programming](#42-bitstream-generation--programming)
   * 4.3 [On-Board Verification](#43-on-board-verification)
8. [5. Test & Debug](#5-test--debug)

   * 5.1 [Internal Logic Analyzer (ILA)](#51-internal-logic-analyzer-ila)
   * 5.2 [Common Issues & Resolutions](#52-common-issues--resolutions)
   * 5.3 [Lessons Learned](#53-lessons-learned)
9. [6. Final Hardware Report](#6-final-hardware-report)

   * 6.1 [Power Consumption](#61-power-consumption)
   * 6.2 [Clocking Summary](#62-clocking-summary)
   * 6.3 [Resource Utilization & Timing](#63-resource-utilization--timing)
   * 6.4 [Block Diagram & Schematic](#64-block-diagram--schematic)

---

## Project Overview

This project implements a full-HDMI Pong game on the PYNQ-Z2 board:

* **Video Output:** 1280×720 @ 60 Hz via a custom TMDS/HDMI transmitter in Verilog/SystemVerilog.
* **FPGA Logic:** Ball physics, paddle control, scoring, “GAME OVER” splash loaded from a 1280×200 bitmap in BRAM.
* **CPU AI Opponent:** Player 2 automated by an ARM core running bare-metal C (Vitis) via AXI-Lite.
* **Workflow:** Vivado RTL → Block Design → Bitstream → Export HDF → Vitis C Application → Hardware.

---

## Repository Layout

```text
/
├── Constraints_File/master.xdc      # Board I/O constraints (HDMI, buttons, LEDs)
├── Gameover_bitmap.coe              # 1-bit COE for 1280×200 “GAME OVER” bitmap
├── gameover_bitmap.xci              # Generated Block RAM IP
├── Images/                          # Reference screenshots & diagrams
├── Verilog/                         # All HDL sources & IP cores
│   ├── hdmi_transmit.sv             # TMDS encoder + video timing
│   ├── tmds_encode.v
│   ├── tmds_oserdes.v
│   ├── video_timing.xci             # Video timing controller IP
│   ├── mmcm_0.xci                   # Clocking Wizard for 74.25 MHz pixel clock
│   ├── object.sv                    # Ball & collision logic
│   ├── paddle.sv                    # Player 1 paddle
│   ├── paddle_two.sv                # Player 2 paddle
│   ├── score_board.sv               # On-screen scoreboard
│   ├── gameover_bitmap.coe          # Bitmap init file
│   └── top.sv                       # Top-level integrating all modules
├── Vitis/                           # Bare-metal ARM application & hardware export
│   ├── CPU_Pong.c                   # Player 2 AI control in C
│   └── design_6_wrapper.xsa         # Hardware export for Vitis/HLS
└── README.md                        # Project documentation (this file)
```

---

## Prerequisites

* **Vivado** 2021.1 or later
* **Vitis** matching the Vivado version
* **PYNQ-Z2** board with HDMI-capable monitor
* Familiarity with Verilog/SystemVerilog, AXI-Lite, and Vivado block designs

---

## 1. RTL Design

### 1.1 Verilog/SystemVerilog Modules

* **`hdmi_transmit.sv`**: TMDS/HDMI encoder & video-timing controller.
* **`object.sv`**: Ball trajectory, bounce, and collision logic.
* **`paddle.sv`** & **`paddle_two.sv`**: Left/right paddle movement.
* **`score_board.sv`**: Renders scores as on-screen bitmaps.
* **`gameover_bitmap`** IP: 1280×200 ROM loaded from `.coe`.
* **`top.sv`**: Integrates all modules, overlays “GAME OVER”, outputs TMDS.

### 1.2 Video Pipeline Stages

1. **Clock Generation**: 100 MHz PS clock → MMCM → 74.25 MHz pixel clock.
2. **Timing Controller**: Generates `hsync`/`vsync`/`active`/`hpos`/`vpos`.
3. **Graphics Engines**: Ball, paddles, scoreboard generate per-pixel RGB buses.
4. **Overlay Mux**: Switches to “GAME OVER” splash when game ends.
5. **TMDS Encoder**: Packs RGB into differential pairs for HDMI.

### 1.3 Memory-Mapped I/O

* **AXI-Lite** registers expose paddle positions, score flags, and `game_over` status.
* **LEDs** indicate winner flags.

---

## 2. Simulation & Memory Testing

### 2.1 Bitmap (.COE) Initialization

* The COE file must list 200 lines × 1280 bits, commas on every line except the last (semicolon).
* Verified via Vivado IP “Init File Preview.”

### 2.2 Overlay & Game Logic Testbench

* **`tb_overlay_top.v`**: Verifies BRAM contents and overlay mapping in simulation.
* **`tb_game_logic.v`**: Simulates paddle hits, scoring, and `game_over` timing.

### 2.3 Waveform Inspection & Coverage

* Use Vivado Simulator or ModelSim to inspect `active`, `hpos`, `vpos`, `bitmap`, and final `pixel` signals.
* Collect coverage on all game states and overlay conditions.

---

## 3. FPGA Integration (Block Diagram)

### 3.1 Zynq PS Reset & Clocking

* **PS** generates `FCLK_0` → MMCM → pixel clock.
* **proc\_sys\_reset** synchronizes resets for PL.

### 3.2 Custom IP: Pong Engines

* Wrapped `object`, `paddle`, `score_board`, and `gameover_bitmap` as reusable IP.
* Connected via AXI-Lite for control and status.

### 3.3 BRAM for “GAME OVER” Bitmap

* Block Memory Generator configured 200×1280 bits with COE initialization.

### 3.4 AXI-Lite & LEDs

* **AXI\_GPIO** for paddle two commands and score flags.
* On-board LEDs display player wins.

---

## 4. Hardware Bring-Up on PYNQ-Z2

### 4.1 Constraints & I/O Planning

* `master.xdc` maps HDMI TMDS, PS clocks, PMOD LEDs, and buttons.
* Use LVCMOS33 standard.

### 4.2 Bitstream Generation & Programming

```bash
# Vivado TCL
open_project pong_hdmi.xpr
launch_runs synth_1
launch_runs impl_1
write_bitstream -force
program_hw_devices
```

### 4.3 On-Board Verification

1. Plug in HDMI cable → 1280×720\@60.
2. Use buttons/CPU to move paddles.
3. Score until “GAME OVER” appears.
4. LEDs indicate winner.

---

## 5. Test & Debug

### 5.1 Internal Logic Analyzer (ILA)

* Probe `bitmap`, `game_over`, and `pixel` nets.
* Trigger on `vpos == GAMEOVER_VSTART` & `game_over == 1`.

### 5.2 Common Issues & Resolutions

* **No HDMI signal**: Check COE formatting (200×1280 bits).
* **Timing fails**: Verify MMCM settings and reset de-assertion.
* **Overlay misaligned**: Confirm `GAMEOVER_VSTART` & `row_addr` logic.

### 5.3 Lessons Learned

* COE parser is silent—always preview before bitstream.
* Register alignment is critical for TMDS timing closure.

---


## 6. Final Hardware Report

### 6.1 Device Floorplan

![FPGA Floorplan](/Images/Device.png)

Placement shows core logic densely packed in the bottom-left quadrant (bank X0Y0), with BRAM and clocking resources along the right edge.

### 6.2 Power Consumption

![Power Analysis](/Images/Power.png)

| Metric              |          Value |
| ------------------- | -------------: |
| Total On-Chip Power |        0.416 W |
| — Dynamic           |        0.304 W |
| — Static            |        0.112 W |
| MMCM                | 0.114 W (37 %) |
| I/O                 | 0.133 W (43 %) |
| BRAM                | 0.048 W (16 %) |
| Clocks              |  0.007 W (2 %) |
| Signals             |  0.001 W (1 %) |
| Logic               |  0.001 W (1 %) |

### 6.3 Resource Utilization

![Utilization Summary](/Images/Utilization.png)

| Resource        | Used |   Total | Util % |
| --------------- | ---: | ------: | -----: |
| Slice LUTs      | 1274 |  53 200 |  2.4 % |
| Slice Registers |  363 | 106 400 | 0.34 % |
| BRAM18K Tiles   |   18 |     140 | 12.9 % |
| OLOGIC          |    8 |     125 |  6.4 % |
| BUFGCTRL        |    2 |      32 |  6.3 % |
| MMCME2\_ADV     |    1 |       4 |   25 % |

### 6.4 Timing Summary

![Timing Summary](/Images/Timing.png)

| Metric                     |    Value |
| -------------------------- | -------: |
| Worst Negative Slack (WNS) | 0.782 ns |
| Worst Hold Slack (WHS)     | 0.046 ns |
| Worst Pulse Width Slack    | 0.511 ns |
| Failing Endpoints          |        0 |

All user-specified timing constraints are met at a 74.25 MHz pixel clock.


### 6.4 Block Diagram & Schematic

See `Images/block_diagram.png` and `Images/schematic.pdf` for the Vivado BD and netlist schematic.

---
