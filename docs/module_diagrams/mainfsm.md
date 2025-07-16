# mainfsm

```mermaid
flowchart TD
    classDef main fill:#FFDDC1,stroke:#333,stroke-width:2px
    classDef sub fill:#BBE1FA,stroke:#333
    clk --> fsm((mainfsm))
    reset --> fsm
    Op([Op]) --> fsm
    Funct([Funct]) --> fsm
    is_mul64 --> fsm
    is_mul32 --> fsm
    is_compare_op --> fsm
    is_fp_op --> fsm
    fsm --> {IRWrite,AdrSrc,ALUSrcA,ALUSrcB,ResultSrc,NextPC,RegW,MemW,Branch,ALUOp,WAsel,ResultWEn,AandBWrite,RA2Sel,FPUOp}
    class fsm main
```
