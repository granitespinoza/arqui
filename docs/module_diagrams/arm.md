# arm

```mermaid
flowchart TD
    clk --> arm_module((arm))
    reset --> arm_module
    ReadData([ReadData]) --> arm_module
    arm_module --> controller_sub(controller)
    arm_module --> datapath_sub(datapath)
    controller_sub --> datapath_sub
    datapath_sub --> controller_sub
    arm_module --> MemWrite
    arm_module --> Adr
    arm_module --> WriteData
```
