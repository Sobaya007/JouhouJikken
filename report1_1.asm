ORG 10
/ Y == 0 ? HLT : goto LY
L0,
  CLE
  LDA Y
  SZA
  BUN LY
  HLT
/ Y >>= 1, E == 0 ? goto LX : goto LP
LY,
  CIR
  STA Y
  SZE
  BUN LP
/ [Z,X] <<= 1, goto L0
LX, 
  LDA X
  CIL
  STA X
  LDA Z
  CIL
  STA Z
  BUN L0
/ [Q,P] += [Z,X]
LP,
  LDA X
  ADD P
  STA P
  LDA Z
  SZE
  INC
  ADD Q
  STA Q
  CLE
  BUN LX
/ data
X, DEC 65535
Y, DEC 65535
Z, DEC 0
P, DEC 0
Q, DEC 0
END
