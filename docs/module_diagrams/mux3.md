# mux3

```mermaid
flowchart TD
    classDef main fill:#FFDDC1,stroke:#333,stroke-width:2px
    classDef sub fill:#BBE1FA,stroke:#333
    d0([d0]) --> mux3_module((mux3))
    d1([d1]) --> mux3_module
    d2([d2]) --> mux3_module
    s([s[1:0]]) --> mux3_module
    mux3_module --> y([y])
    class mux3_module main
```
