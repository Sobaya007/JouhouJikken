 ORG 10
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
  HLT
/ data
X, DEC 65535
Y, DEC 65535
P, DEC 0
Q,  DEC 0
C, DEC -16
END
