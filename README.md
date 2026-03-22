# Parametric-SPI-Master-VHDL
Parametric SPI Master implemented in VHDL with FSM-based control, configurable clock divider, and full simulation testbench.

📌 Overview

This project implements a parametric SPI Master in VHDL.
The design is based on an FSM architecture and supports configurable clock generation and data width.
Simulation and verification are performed using a custom testbench.

⚙️ Features

FSM-based control (IDLE – LOAD – TRANSFER – DONE)

Configurable SPI clock (clock divider)

Full-duplex communication (MOSI & MISO)

Shift register-based data transfer

Bit counter for transfer control

Chip Select (CS) management

Parametric data width support

Simulation testbench with verification (assert)


🧠 Architecture

The design consists of the following main blocks:

FSM (Control Unit) → Manages SPI transaction flow

Clock Divider → Generates SPI clock from system clock

TX Shift Register → Sends data over MOSI

RX Shift Register → Receives data from MISO

Bit Counter → Tracks transmitted bits

CS Control → Handles slave selection


🔄 SPI Communication

Master-driven clock (SCLK)

Data is transmitted via MOSI and received via MISO

Communication is full-duplex

Current implementation tested in SPI Mode 0


🧪 Simulation & Verification

A dedicated testbench is implemented to verify functionality:

Generates system clock and reset

Sends test data (TX)

Simulates slave behavior (MISO)

Validates received data using assert

✔ Simulation confirms correct data transmission and reception.
