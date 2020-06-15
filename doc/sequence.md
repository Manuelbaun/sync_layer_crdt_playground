```sequence
A->B: sends encoded state
B->A: sends encoded state
Note over A,B: Compares state A & B

B->B: retrive atoms \nsince diverging time
A->A: retrive atoms \nsince diverging time

B->A: sends state response\n (encoded Atoms)
A->B: sends state response\n (encoded Atoms)

A->A: applies incoming atoms
B->B: applies incoming atoms
```