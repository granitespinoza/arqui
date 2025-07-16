# fpu

```mermaid
flowchart TD
    fp_a([fp_a]) --> fpu_module((fpu))
    fp_b([fp_b]) --> fpu_module
    fp_control([fp_control]) --> fpu_module
    fpu_module --> fp_result([fp_result])
```
