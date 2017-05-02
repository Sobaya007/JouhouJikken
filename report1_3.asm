ORG 10
/ CNT = -INPUT.length-1
  CLA
  ADD IPT I
  CMA
  STA CNT
/ ++CNT == 0 ? LO : goto L1
L0, 
  ISZ CNT
  BUN L1
  BUN LO
/ IPT++
L1,
  ISZ IPT
/ X <<= 4
  LDA X
  CIL
  CIL
  CIL
  CIL
  STA X
/ AC = INPUT
  CLA
  ADD IPT I
/ input > 'F' goto LE
  CMA
  INC
  ADD F
  SPA
  BUN LE
/ input >= 'A' goto LA
  LDA A
  CMA
  INC
  ADD IPT I
  SNA
  BUN LA
/ input < '0' goto LE
  LDA ZERO
  CMA
  INC
  ADD IPT I
  SPA
  BUN LE
/ input <= '9' goto LN
  CLA
  ADD IPT I
  CMA
  INC
  ADD NINE
  SNA
  BUN LN
/ output 'ERROR'
/ *OPT = *EPT, CNT = -ERROR.length-1
LE,
  CLA
  ADD EPT I
  STA OPT I
  CMA
  STA CNT
/ EPT++, OPT++, *OPT = *EPT
LE2,
  ISZ EPT
  ISZ OPT
  CLA
  ADD EPT I
  STA OPT I
/ ++CNT == 0 ? HLT : goto LE2
  ISZ CNT
  BUN LE2
  HLT
/ AlphaBet to Dec
/ X += input - 'A' + 10, goto L0
LA,
  LDA A
  CMA
  ADD TEN
  BUN LX
/ X += input - '0', goto L0
LN,
  LDA ZERO
  CMA
LX,
  INC
  ADD IPT I
  ADD X
  STA X
  BUN L0
/binary -> dec
/OUTPUT.length++, OPT++, P = X/Y, Q = X%Y, *OPT = Q
LO,
  ISZ OUTPUT
  ISZ OPT
  BSA LD
  LDA Q
  STA OPT I
/ P == 0 ? HLT
  LDA P
  SZA
  BUN LD3
  HLT
/ X = P
LD3,
  STA X
  BUN LO
LD,
  HEX 0
  CLA
  STA P
  STA Q
  LDA TEN
  STA Y
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
/ data
TEN, DEC 10
A, CHR A
F, CHR F
ZERO, CHR 0
NINE, CHR 9
CINIT, DEC -16
INPUT, DEC 4
CHR A
CHR B
CHR C
CHR X
OUTPUT, DEC 0
  CHR _
  CHR _
  CHR _
  CHR _
  CHR _
ERROR, DEC 5
  CHR R
  CHR O
  CHR R
  CHR R
  CHR E
IPT, SYM INPUT
OPT, SYM OUTPUT
EPT,SYM ERROR
X, DEC 0
Y, DEC 10
P, DEC 0
Q, DEC 0
C, DEC -16
CNT, DEC 0
END
