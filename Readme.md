# UART Protocol in Verilog
    This is a simple UART (Universal Asynchronous Receiver-Transmitter) design that includes both a Transmitter (Tx) and Receiver (Rx). 

    It also includes a loopback testbench where the Tx sends data directly to the Rx to verify that the code works correctly. 


## Files included:
* `src/uart_tx.v` - Sends the serial data.
* `src/uart_rx.v` - Receives the serial data.
* `src/baud_rate_gen.v` - Generates the clock ticks for the baud rate.
* `tb/tb_uart_tx.v` - Testbench that tests ONLY the transmitter.
* `tb/tb_uart_loopback.v` - Testbench that tests both Tx and Rx working together.


## How to run the simulations
This project was simulated using Icarus Verilog and GTKWave. Make sure you create a `sim/` folder in your project before running these.

### 1. Testing just the Transmitter
**Compile:**
```bash
iverilog -o sim/tb_uart_tx.out src/uart_tx.v src/baud_rate_gen.v tb/tb_uart_tx.v
```
**Run & View:**
```bash
vvp sim/tb_uart_tx.out
gtkwave sim/tb_uart_tx.vcd 
```

### 2. Testing the Full Loopback (Tx + Rx)
**Compile:**
```bash
iverilog -o sim/tb_uart_loopback.out src/uart_tx.v src/uart_rx.v src/baud_rate_gen.v tb/tb_uart_loopback.v
```
**Run & View:**
```bash
vvp sim/tb_uart_loopback.out
gtkwave sim/tb_uart_loopback.vcd
```


## Directory Structure

uart-protocol-engine/
├── src/
│   ├── baud_rate_gen.v    # Generates 1x and 16x baud ticks
│   ├── uart_tx.v          # Transmitter module
│   └── uart_rx.v          # Receiver module with oversampling
├── tb/
│   └── tb_uart_loopback.v # End-to-end simulation testbench
├── .gitignore
├── README.md
└── waveform.png           #Simulation Waveform

