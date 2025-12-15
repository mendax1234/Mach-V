---
icon: material/book-open-variant
---

# Resoures & Utilities

This section contains utility guides and extra information regarding the Hydra-V software stack.

## Offline Access

This documentation supports exporting the entire site as a single, consolidated PDF for offline reading. This is powered by the [`mkdocs-print-site-plugin`](https://timvink.github.io/mkdocs-print-site-plugin/index.html).

### Export to PDF

Currently, there is no direct download button in the navigation bar. You can generate the PDF manually by following these steps:

1. Access the Print View: Navigate to the consolidated print view by appending `print_page/` to the base URL of the documentation. For example, go to `https://mendax1234.github.io/Hydra-V/print_page/`.
2. Print to PDF: Once the page loads (it may take a moment to render all chapters):
    1. Open your browser's print dialog (`Ctrl + P` on Windows/Linux or `Cmd + P` on macOS).
    2. Set the **Destination** to **"Save as PDF"**.
    3. Click **Save**.

!!! tip "Formatting"
    For the best layout, ensure **Background graphics** is checked in your browser's print settings to preserve syntax highlighting and admonition colors.

## Useful Links

The success of Hydra-V cannot be achieved without the help of many open-source projects and resources. Here are some useful links that you may find helpful when working with Hydra-V:

<div class="grid cards" markdown>

- :material-speedometer:{ .lg .middle } __CoreMark Benchmark__

    ---

    Official CoreMark benchmark by EEMBC, widely used to evaluate embedded
    processor performance.

    [:octicons-arrow-right-24: Visit EEMBC](https://www.eembc.org/coremark/)

- :material-chip:{ .lg .middle } __CoreMark on Bare-Metal Systems__

    ---

    CoreMark running on bare-bone RISC-V systems, including build scripts
    and platform-specific adaptations.

    [:octicons-arrow-right-24: View on GitHub](https://github.com/yutyan0119/rv32I-TangNano9K/tree/main/Coremark)

- :material-tools:{ .lg .middle } __Pre-built RISC-V GNU Toolchain__

    ---

    Pre-compiled RISC-V GCC toolchain for rapid development without
    building from source.

    [:octicons-arrow-right-24: Download Toolchain](https://github.com/stnolting/riscv-gcc-prebuilt)

</div>
