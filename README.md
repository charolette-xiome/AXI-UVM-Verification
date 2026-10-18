# AXI-UVM-Verification

> UVM-based verification environment and testbench for AXI protocol designs.

![GitHub stars](https://img.shields.io/github/stars/charolette-xiome/AXI-UVM-Verification?style=for-the-badge&logo=github) ![GitHub forks](https://img.shields.io/github/forks/charolette-xiome/AXI-UVM-Verification?style=for-the-badge&logo=github) ![GitHub issues](https://img.shields.io/github/issues/charolette-xiome/AXI-UVM-Verification?style=for-the-badge&logo=github) ![Last commit](https://img.shields.io/github/last-commit/charolette-xiome/AXI-UVM-Verification?style=for-the-badge&logo=github)

## 📑 Table of Contents

- [Description](#description)
- [Key Features](#key-features)
- [Use Cases](#use-cases)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Contributors](#contributors)
- [Contributing](#contributing)

## 📝 Description

AXI-UVM-Verification provides a verification environment tailored for validating AXI (Advanced eXtensible Interface) protocol implementations. It addresses functional verification requirements by providing a structured layout separating register-transfer level (RTL) components from testbench routines using the Universal Verification Methodology (UVM). The repository is structured into distinct directories for hardware design sources and verification logic. The testbench directory houses verification components designed to drive stimulus and monitor transactions, while the rtl directory contains the target hardware designs under test. This environment serves hardware and verification engineers seeking a standard baseline to simulate, debug, and verify AXI interface behaviors.

## ✨ Key Features

- **🧪 Dedicated UVM Testbench Infrastructure** — Houses testbench verification assets and simulation routines inside a dedicated testbench directory.
- **🔌 AXI Protocol Target Verification** — Focuses on verifying compliance and transaction behavior for AXI bus interface designs.
- **📁 Isolated RTL Design Hierarchy** — Organizes the design under test within an isolated rtl directory separate from testbench code.

## 🎯 Use Cases

- Simulating and validating AXI bus transaction behavior against standard protocol rules.
- Serving as a reference structure for building UVM verification testbenches.
- Debugging functional defects in RTL hardware implementations using simulation.

## ⚡ Quick Start

```bash

# 1. Clone the repository
git clone https://github.com/charolette-xiome/AXI-UVM-Verification.git

# See the Development Setup section below
```

## 📁 Project Structure

```
.
├── rtl
│   ├── axi4.sv
│   └── axi4_memory.sv
└── testbench
    ├── axi_agent.sv
    ├── axi_assertions.sv
    ├── axi_coverage.sv
    ├── axi_driver.sv
    ├── axi_driver_delay.sv
    ├── axi_environment.sv
    ├── axi_interface.sv
    ├── axi_memory_checker.sv
    ├── axi_memory_coverage.sv
    ├── axi_memory_interface.sv
    ├── axi_memory_monitor.sv
    ├── axi_memory_transaction.sv
    ├── axi_monitor.sv
    ├── axi_passive_memory_agent.sv
    ├── axi_reference_model.sv
    ├── axi_scoreboard.sv
    ├── axi_sequence.sv
    ├── axi_sequence_item.sv
    ├── axi_sequencer.sv
    ├── axi_tb_top.sv
    ├── axi_test.sv
    ├── axi_transactions.sv
    └── axi_uvm_package.sv
```

## 👥 Contributors

Thanks to everyone who has contributed to this project:

<p align="left">
<a href="https://github.com/charolette-xiome" title="charolette-xiome"><img src="https://avatars.githubusercontent.com/u/167672969?v=4&s=64" width="64" height="64" alt="charolette-xiome" style="border-radius:50%" /></a>
</p>

[See the full list of contributors →](https://github.com/charolette-xiome/AXI-UVM-Verification/graphs/contributors)

## 👥 Contributing

Contributions are welcome! Here's the standard flow:

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/charolette-xiome/AXI-UVM-Verification.git`
3. **Branch**: `git checkout -b feature/your-feature`
4. **Commit**: `git commit -m 'feat: add some feature'`
5. **Push**: `git push origin feature/your-feature`
6. **Open** a pull request

Please follow the existing code style and include tests for new behavior where applicable.

---

<div align="center">

[![Made with ReadmeBuddy](https://img.shields.io/badge/Made%20with-ReadmeBuddy-8B5CFF?style=for-the-badge&logo=markdown&logoColor=white)](https://readmebuddy.com)

<sub>Generate beautiful READMEs in seconds → <a href="https://readmebuddy.com">readmebuddy.com</a></sub>

</div>
