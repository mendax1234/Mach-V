# Conventions

This section explains the symbols and conventions used throughout the Mach-V documentation.

## Symbols

The documentation uses visual badges to denote specific hardware states, version requirements, or configuration settings. Please familiarize yourself with the following conventions:

### <!-- md:version --> – Version { data-toc-label="Version" }

The tag symbol denotes the **Mach-V Core Version** required for a specific feature or architectural change. Ensure your hardware description (RTL) matches this version tag to guarantee compatibility.

### <!-- md:feature --> – Optional Feature { #feature data-toc-label="Optional Feature" }

This symbol indicates a hardware module (such as the Branch Predictor or FPU) that is not included in the core by default. These features must be explicitly enabled via Verilog defines (e.g., `` `define ENABLE_FPU``) in your configuration file.

### <!-- md:plugin --> – External IP / Plugin { #plugin data-toc-label="External IP" }

This symbol refers to **External IP Cores** (like Xilinx Clock Wizards or AMD Multipliers) or software plugins used in the project. These components may require specific vendor licenses or additional synthesis libraries.

### <!-- md:experimental --> – Experimental { #experimental data-toc-label="Experimental" }

Features marked with the flask symbol are currently being tested on the FPGA and may be unstable. The timing closure or logic correctness for these features is not yet guaranteed in all corner cases.

### <!-- md:default --> – Default Value { #default data-toc-label="Default Value" }

Indicates the **default reset value** of a hardware register or a configuration parameter if not otherwise specified by the software bootloader.
