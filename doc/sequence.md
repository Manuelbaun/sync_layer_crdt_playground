```sequence
A->B: sends encoded state
B->A: sends encoded state
B->B: Compares state A & B
A->A: Compares state A & B
B->B: retrive atoms from diverging time
A->A: retrive atoms from diverging time

B->A: sends state response (encoded Atoms)
A->B: sends state response (encoded Atoms)
A->A: applies incoming atoms
B->B: applies incoming atoms
```