# condlogic

```mermaid
flowchart TD
    subgraph condlogic
        clk --> cl
        reset --> cl
        Cond --> cl
        ALUFlags --> cl
        FlagW --> cl
        PCS --> cl
        NextPC --> cl
        RegW --> cl
        MemW --> cl
        cl(condlogic)
        cl --> PCWrite
        cl --> RegWrite
        cl --> MemWrite
    end
    cl --> condcheck_sub(condcheck)
    ALUFlags --> flags_regs((flopenr regs))
```
