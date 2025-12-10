# NetTap Analyzer  
**Low-Latency FPGA-Based Network Tap & Packet Analyzer**

NetTap Analyzer is a high-performance FPGA-accelerated network tapping and packet-analysis platform designed for extremely low-latency Ethernet capture, filtering, and inline monitoring.  

The system is built on the **PYNQ-Z2 (Zynq-7020)** platform and uses:

- Custom AXI-Stream datapaths  
- A lightweight high-performance DMA engine  
- A modular packet classifier  
- A pluggable FPGA/PS co-design architecture  
- Full reproducible build automation (Make + TCL)

The end goal is to evolve this baseline into a **professional-grade hardware network analyzer**, suitable for roles in:
- FPGA engineering  
- High-speed digital design  
- Embedded systems  
- ASIC/processor design trajectories (Intel/AMD/Apple/Tesla-style roles)

---

## 🔥 Key Features (Current & Planned)
- **FPGA packet tapping datapath** (AXI Stream)
- **Custom DMA engine** (lightweight, PS-controlled)
- **Frame slicing, filtering, classification**
- **ARP/IP/MAC parsing logic**
- **Integrated PS C++ control application**
- **Automated Vivado project creation**
f- **Total reproducible builds using Makefiles**

---

## 🧩 Architecture

```
+-----------------------------------------------------------------------------------+
|  ZYNQ-7020 PROCESSING SYSTEM (HOST)                                               |
|                                                                                   |
|  [Ethernet PHY] <==> [GEM Controller] <==> [DDR3 Memory] <==> [Linux OS / Driver] |
+------------------------------------------+----------------------------------------+
                                           |
                                           | AXI4 High-Performance (HP0)
                                           | (Packet Data Transfer)
+------------------------------------------v----------------------------------------+
|  PROGRAMMABLE LOGIC (FPGA ACCELERATOR)                                            |
|                                                                                   |
|   +----------------------+       +--------------------------------------------+   |
|   |  Custom DMA Engine   |       |  HFT Simulation Mode                       |   |
|   |  (Scatter-Gather)    |       |  (Synthetic Packet Injection)              |   |
|   +----------+-----------+       +----------------------+---------------------+   |
|              |                                          |                         |
|              v AXI-Stream                               v AXI-Stream              |
|   +----------+------------------------------------------+---------------------+   |
|   |                      STREAM ARBITER / MUX                                 |   |
|   +-------------------------------------+-------------------------------------+   |
|                                         |                                         |
|                                         v                                         |
|   +-------------------------------------+-------------------------------------+   |
|   |  PACKET PROCESSING PIPELINE                                               |   |
|   |                                                                           |   |
|   |  [Header Parser] --> [Bloom Filter/Classifier] --> [Statistics Engine]    |   |
|   |       (RTL)                (Cam/Hash)                   (Counters)        |   |
|   +---------------------------------------------------------------------------+   |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

---

## 📂 Repository Structure
```
NetTap-Analyzer
├── docs
├── fpga
│   ├── Makefile
│   └── vivado
├── LICENSE
├── README.md
├── rtl
├── scripts
├── sim
│   ├── cocotb
│   └── testbench_sv
├── sw
│   └── ps_app
└── tools
    └── board_files
        └── pynq-z2
            └── A.0
                ├── board.xml
                ├── part0_pins.xml
                └── preset.xml
```
---

## 🛡️ License (Proprietary – All Rights Reserved)

```
Copyright (c) 2025 Lord Sach  
All Rights Reserved.

This project is proprietary.  
Viewing the source is permitted; copying, redistributing, or using the code  
in any form without explicit written permission is strictly prohibited.
```

---

## 📝 Author  
**Lord Sach**  
Hardware Architect · FPGA Engineer · System Designer

---

## ⭐ Acknowledgements  
Built with passion, precision, and low-latency engineering discipline.
