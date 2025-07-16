# decode

```mermaid
flowchart TD
    Instr([Instr]) --> decode_module((decode))
    clk --> decode_module
    reset --> decode_module
    decode_module --> mainfsm_sub(mainfsm)
    decode_module --> {FlagW,PCS,NextPC,RegW,MemW,IRWrite,AdrSrc,ResultSrc,ALUSrcA,ALUSrcB,ImmSrc,RegSrc,ALUControl,Branch,WAsel,ResultWEn,AandBWrite,RA2Sel,FPUOp}
```
