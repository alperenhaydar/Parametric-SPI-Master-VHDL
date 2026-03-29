# Parametric-SPI-Master-VHDL
Parametric SPI Master implemented in VHDL with FSM-based control, configurable clock divider, and full simulation testbench.

📌 Overview

This project presents the design and simulation of a parametric SPI Master in VHDL. The architecture is based on a finite state machine (FSM) and supports configurable parameters such as data width and clock divider.

The functionality of the SPI Master is verified using a loopback-based testbench, where transmitted data is internally routed back to the receiver.

<img width="1111" height="647" alt="image" src="https://github.com/user-attachments/assets/a362bffb-2aea-44ab-8884-cbec9617c0a1" />


⚙️ Features

FSM-based control (IDLE – TRANSFER – CLEANUP)

Configurable SPI clock (clock divider)

Full-duplex communication (MOSI & MISO)

Shift register-based data transmission

Bit counter for transfer control

Chip Select (CS) signal management

Parametric data width support

Loopback-based simulation verification

🧠 Architecture


FSM (Control Unit) → Controls SPI transaction flow

Clock Divider → Generates SPI clock from system clock

TX Shift Register → Sends data over MOSI

RX Shift Register → Receives data from MISO

Bit Counter → Tracks number of transmitted bits

CS Control → Manages chip select signal

🔄 SPI Communication

Master generates SPI clock (SCLK)

Data is transmitted via MOSI and received via MISO

Communication is full-duplex

🧪 Simulation & Verification

A loopback-based testbench is used for verification:

Generates system clock and reset signals

Sends predefined test data (TX)

Routes MOSI directly to MISO (loopback)

Verifies received data using assertions

✔ Simulation results confirm that transmitted and received data match exactly, validating correct operation of the SPI Master.

📈 Notes

Loopback testing verifies internal data flow and timing consistency

External SPI slave integration can be considered as future work for full system validation

<img width="1043" height="410" alt="image" src="https://github.com/user-attachments/assets/e27424c7-f4b1-49ae-a5fe-192f82f64663" />

