# datapath

```mermaid
flowchart TD
    subgraph datapath
        clk --> dp
        reset --> dp
        ReadData --> dp
        PCWrite --> dp
        NextPC --> dp
        Branch --> dp
        RegWrite --> dp
        IRWrite --> dp
        AdrSrc --> dp
        RegSrc --> dp
        ALUSrcA --> dp
        ALUSrcB --> dp
        ResultSrc --> dp
        ImmSrc --> dp
        ALUControl --> dp
        PCS --> dp
        WAsel --> dp
        ResultWEn --> dp
        AandBWrite --> dp
        RA2Sel --> dp
        FPUOp --> dp
        dp(datapath)
        dp --> Adr
        dp --> WriteData
        dp --> Instr
        dp --> ALUFlags
    end
    dp --> flopenr_pc(flopenr)
    dp --> regfile_sub(regfile)
    dp --> alu_sub(alu)
    dp --> fpu_sub(fpu)
    dp --> extend_sub(extend_rotational)
    dp --> adder_sub(adder)
    dp --> mux2_sub(mux2)
    dp --> mux3_sub(mux3)
```
