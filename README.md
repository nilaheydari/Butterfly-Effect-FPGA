<div align="center">

# 🦋 Butterfly Effect
### A VGA-Based Arcade Game on Spartan-6 FPGA

![VHDL](https://img.shields.io/badge/Language-VHDL-007ACC?style=for-the-badge)
![FPGA](https://img.shields.io/badge/FPGA-Spartan--6-28A745?style=for-the-badge)
![Xilinx](https://img.shields.io/badge/Tool-Xilinx_ISE-E01B24?style=for-the-badge)

**Digital Systems CAD Project**

</div>

---

## 📖 Overview

**Butterfly Effect** is a hardware-based arcade game developed in **VHDL** using **Xilinx ISE** and implemented on a **Spartan-6 FPGA**.

The player shoots colored balls toward a moving chain, aiming to match colors and eliminate balls before the chain reaches the end of its path.

The project combines VGA graphics, collision detection, game logic, special shooting abilities, and seven-segment display output.

---

## ✨ Features

- VGA graphics at **640 × 480** resolution
- Moving chain of up to **12 colored balls**
- Three shooting directions
- Collision detection and color matching
- Special shooting abilities and reward system
- Win and lose states
- Four-digit seven-segment display

---

## 🎮 Game Mechanics

The game generates ball colors using an **LFSR** and moves the chain along a predefined path.

Players can shoot in three directions and use the following shooting modes:

| Mode | Function |
|---|---|
| Normal | Shoots a colored ball to eliminate matching groups of at least three |
| Bomb 1 | Removes the target ball and its immediate neighbors |
| Bomb 3 | Removes up to three balls preceding the target |

Special abilities are unlocked by eliminating balls.

**Winning condition:** Reach an elimination count of 8.

**Losing condition:** The leading ball reaches the end of the path.

---

## 🏗️ Hardware Architecture

| Module | Description |
|---|---|
| `TopLevel.vhd` | Game logic, controls, collision detection, graphics, and seven-segment output |
| `VGA_controller.vhd` | VGA synchronization and pixel coordinate generation |

### VGA Configuration

| Parameter | Value |
|---|---|
| Resolution | 640 × 480 |
| Clock | 24 MHz |
| Horizontal Total | 800 pixels |
| Vertical Total | 525 lines |
| Color Output | 6-bit RGB |
| Refresh Rate | Approximately 57.14 Hz |

---

## 🎥 Gameplay Demo

<div align="center">

<img src="videos/gameplay.gif" alt="Butterfly Effect Gameplay" width="650">

</div>

---

## 📸 Hardware Results

### Gameplay

<div align="center">
<img src="images/gameplay.png" alt="Gameplay" width="650">
</div>

### Winning State

<div align="center">
<img src="images/win.png" alt="Winning State" width="650">
</div>

### Losing State

<div align="center">
<img src="images/lose.png" alt="Losing State" width="650">
</div>

---

## 🕹️ Controls

The game uses four active-low push buttons.

| Button | Function |
|---|---|
| PB(0) | Shoot Ball |
| PB(1) | Aim Left |
| PB(2) | Aim Right |
| PB(3) | Aim Straight |

---

## 📂 Project Structure

```text
Butterfly-Effect-FPGA/
├── TopLevel.vhd
├── VGA_controller.vhd
├── images/
│   ├── gameplay.png
│   ├── win.png
│   └── lose.png
├── videos/
│   └── gameplay.gif
└── README.md
```

---

## 🛠️ Hardware and Software

- **FPGA:** Xilinx Spartan-6
- **Language:** VHDL
- **Development Tool:** Xilinx ISE
- **Display:** VGA
- **Input:** Push Buttons
- **Additional Output:** Four-Digit Seven-Segment Display

---

<div align="center">

**🦋 Butterfly Effect**

*Digital Systems CAD — VHDL & FPGA Project*

</div>
