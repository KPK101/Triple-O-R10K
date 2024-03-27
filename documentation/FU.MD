## Functional Units
 NUM_FU_ALU 1
 NUM_FU_MULT 1
 NUM_FU_LOAD 1
 NUM_FU_STORE 1
 MULT_STAGES 4



 ## FU Definition

 ```
 typedef enum logic [1:0] {
    ALU,
    LD,
    ST,
    MULT
} FU;
```
