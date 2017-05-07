	ORG 10		/ program entry point
/ count 16  W: -16 --> 0
L0,    
	LDA W  / AC <- M[W]
	SNA    / (AC < 0) ? next skip
	HLT
/ main loop
L1,
	CLE    / E <- 0
	CLA    /　AC <- 0
	LDA X  / AC <- M[X]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA X  / M[X] <- AC
	CLA    / AC <- 0
	LDA P  / AC <- M[P]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA P  / M[P] <- AC
	LDA Y  / AC <- M[Y]
	CMA    / AC <- ~AC
	INC    / ++AC
	ADD P  / AC <- AC + M[P]
	SZE    / (E == 0) ? skip next
	BUN L2 / goto L2
/ ++M[W]
L3,
	CLA    / AC <- 0
	LDA W  / AC <- M[W]
	INC    / ++AC
	STA W  / M[W] <- AC
	CLA    / AC <- 0
	BUN L0 / goto L0
/ P - Y >= 0 -->  ++M[X]
L2,
	STA P  / M[P] <- AC
	CLA    / AC <- 0
	LDA X  / AC <- M[X]
	INC    / ++AC
	STA X  / M[X] <- AC
	BUN L3 / goto L3
/ data
X,	DEC 65535		/ X = 65535 --> X:init   -->   X = X / Y :result
Y,	DEC 65535	/ Y = 65535 --> Y:init
P,	HEX 0		/ (init : 0) P = X mod Y : result
W,  DEC -16 / counter (init : -16)
END

