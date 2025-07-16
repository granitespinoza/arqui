# decode

```mermaid
flowchart TD
    classDef main fill:#FFDDC1,stroke:#333,stroke-width:2px
    classDef sub fill:#BBE1FA,stroke:#333
    Instr([Instr]) --> decode_module((decode))
    clk --> decode_module
    reset --> decode_module
    decode_module --> mainfsm_sub(mainfsm)
    decode_module --> {FlagW,PCS,NextPC,RegW,MemW,IRWrite,AdrSrc,ResultSrc,ALUSrcA,ALUSrcB,ImmSrc,RegSrc,ALUControl,Branch,WAsel,ResultWEn,AandBWrite,RA2Sel,FPUOp}
    class decode_module main
    class mainfsm_sub sub
```
