# controller

```mermaid
flowchart TD
    Instr([Instr]) --> controller_module((controller))
    clk --> controller_module
    reset --> controller_module
    ALUFlags --> controller_module
    controller_module --> decode_sub(decode)
    controller_module --> condlogic_sub(condlogic)
    decode_sub --> condlogic_sub
    controller_module --> {PCWrite,MemWrite,RegWrite,IRWrite,AdrSrc,RegSrc,ALUSrcA,ALUSrcB,ResultSrc,ImmSrc,ALUControl,PCS,NextPC,Branch,WAsel,ResultWEn,AandBWrite,RA2Sel,FPUOp}
```
