# mem

```mermaid
flowchart TD
    clk --> mem_module((mem))
    we --> mem_module
    a([a]) --> mem_module
    wd([wd]) --> mem_module
    mem_module --> rd([rd])
```
