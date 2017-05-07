	ORG 10		/ program entry point
/ check M[X] < 0 ?
LW,  
	CLE    / E <- 0 	
	LDA X  / AC <- M[X]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	SZE    / (E == 0) ? skip next
	BUN LW1 / goto LW1
	CLA    /AC <- 0
/ check M[Y] == 0 ?
L0, 	
	CLE			/ E <- 0
	LDA Y		/ AC <- M[Y]
	SZA			/ (AC == 0) ? skip next
	BUN LY		/ goto LY
	HLT
/ M[Y] >>= 1
LY,
	CIR			/ {AC[15:0], E} <- {E, AC[15:0]}
	STA Y		/ M[Y] <- AC
	SZE			/ (E == 0) ? skip next
	BUN LP	/ goto LP
/ M[X] <<= 1
LX,
	CLE    / E <- 0
	LDA X  / AC <- M[X]
	CIL    / {E, AC[15:0]} <- {AC[15:0], E}
	STA X	 / M[X] <- AC
	LDA W  / AC <- M[W]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA W  / M[W] <- AC
	BUN L0 / goto LO
/ {M[Z],M[P]} += {M[W],M[X]}
LP, 
	CLE
	LDA X	 / AC <- M[X]
	ADD P	 / AC <- AC + M[P]
	STA P	 / M[P} <- AC
	LDA W  / AC <- M[W]
	SZE    / (E == 0) ? skip next
	INC    / ++AC
	ADD Z  / AC <- AC + M[Z]
	STA Z  / M[Z] <- M[Z] 
	BUN LX / goto LX
/ sign extension M[W] <- ~M[W]
LW1,   
	CLA    / AC <- 0
  LDA W  / AC <- M[W]
	CMA    / AC <- ~AC 
	STA W  / M[W] <- AC
	CLA    / AC <- 0
	CLE    / E <- 0
	BUN L0 / goto L0
/ data
X,	DEC 65535	/ X = 65535 --> {W,X}:init
W, 	DEC 0     / (init : 0)
Y,	DEC 65535	/ Y = 65535  --> Y:init
P,	DEC 0		/ (init : 0) {Z,P} = {W,X} * Y : result
Z,	DEC 0
END

