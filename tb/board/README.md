# RiP pseudo core

The main purpose of the RiP pseudo core is to determine if PS-PL communication is successfully established on an actual FPGA board.
Hence, it does not provide any meaningful functionality.

Here, we assume, but not limited to, a design where the core is implemented on PL (programmable logic) of UltraScale+ FPGA boards, driven from PS (processing system) using PYNQ and AXI GPIO, and exchanges data with PS via CMA (contiguous memory allocator) region.

## IP hierarchy

```
rip_pseudo_core_wrapper_wrapper (rip_pseudo_core_wrapper_wrapper.v)
 └- rip_pseudo_core_wrapper (rip_pseudo_core_wrapper.sv)
     ├- rip_pseudo_core (rip_pseudo_core.sv)
     └- rip_pseudo_core_mmu (rip_pseudo_core_mmu.sv)
```

`rip_pseudo_core` uses AXI master (`rip_axi_master`) directly, while `rip_pseudo_core_mmu` uses MMU (`rip_memory_management_unit`). Both modules have same I/O ports and they can be easily switched.

`rip_pseudo_core_wrapper` serves to connect SystemVerilog interface signals to normal I/O signals. Then, `rip_pseudo_core_wrapper_wrapper` wraps it to provide Verilog HDL module top.
