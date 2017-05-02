ORG 10
/N <= 1 ? HLT
  LDA N
  SZA
  CME
  CMA
  ADD TWO
  SZE
  HLT
/ M = N-1
L0,
  LDA N
  BSA DC
  STA M
/ M == 1 ? RES = N, HLT : goto L2
L1,
  LDA M
  BSA DC
  SZA
  BUN L2
  LDA N
  STA RES
  HLT
/ P = N / M, Q = N % M, Q == 0 ? N--, goto L0 : goto L3
L2,
  LDA N
  STA X
  LDA M
  STA Y
  BSA LD
  LDA Q
  SZA
  BUN L3
  LDA N
  BSA DC
  STA N
  BUN L0
/ M--, goto L1
L3,
  LDA M
  BSA DC
  STA M
  BUN L1
/P = 0, Q = 0, C = -16
LD,
  HEX 0
  CLA
  STA P
  STA Q
  LDA CINIT
  STA C
/ P<<= 1, [Q,X] <<= 1
LD0,
  CLE
  LDA P
  CIL
  STA P
  LDA X
  CIL
  STA X
  LDA Q
  CIL
  STA Q
/ Q >= Y ? goto LD1 : goto LD2
  LDA Y
  CLE
  SZA
  CME
  CMA
  INC
  ADD Q
  SZE
  BUN LD1
  BUN LD2
/ Q -= Y, P++
LD1,
  STA Q
  LDA P
  INC
  STA P
/ ++C == 0 ? HLT : goto LD0
LD2,
  ISZ C
  BUN LD0
  BUN LD I
/AC = AC-1
DC,
  HEX 0
  CMA
  INC
  INC
  CMA
  INC
  BUN DC I
/ data
CINIT, DEC -16
TWO, DEC 2
RES, DEC 0
N, DEC 65535
M, DEC 0
X, DEC 0
Y, DEC 0
P, DEC 0
Q,  DEC 0
C, DEC 0
END
