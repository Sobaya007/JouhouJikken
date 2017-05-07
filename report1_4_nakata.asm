	ORG 10		/ program entry point
/ N1 <- N, call DIV, M[R] == 0 ?
LD0,	
	LDA N  / AC <- M[N]
	STA N1 / M[N1] <- AC
	CLA    / AC <- 0
	STA R  / M[R] <- AC
 	BSA DIV / goto DIV
	LDA R  / AC <- M[R]
	SZA    / (AC == 0) ? skip next
	BUN LD1 / goto LD1
/ M[Y1] == M[N] ?
	LDA Y1 / AC <- M[Y1]
	CMA    / AC <- ~AC
	INC    / ++AC
	ADD N  / AC += M[N]
	SZA    / (AC == 0) ? skip next
	BUN LD2 / goto LD2
	HLT
/ --M[N1], M[Y1] <- M[Y]
LD2,	
	LDA N  / AC <- M[N]
	ADD VM1 / AC -= 1
	STA N  / M[N] <- AC
	LDA Y  / AC <- M[Y]
	STA Y1 / M[Y1] <- AC
	BUN LD0 / goto LD0
/ ++M[Y1]
LD1,	
	ISZ Y1 / ++M[Y1]
	BUN LD0	
/ M[R] <- M[N1](mod M[Y1]), M[N1] <- M[N1]/M[Y1]
DIV,
	HEX 0  / return address
	LDA W1 / AC<- M[W1]
	STA W  / M[W] <- AC
	CLA    / AC <- 0	
DIV0,  
	LDA W  / AC <- M[W]
	SNA    / (AC < 0) ? skip next
	BUN DIV I / goto DIV
DIV1, 	
	CLE    / E <- 0   
	CLA    / AC <- 0
	LDA N1 / AC <- M[N1]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA N1 / M[N1] <- AC
	CLA    / AC <- 0
	LDA R  / AC <- M[R]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA R  / M[R] <- AC
	LDA Y1 / AC <- M[Y1]
	CMA    / AC <- ~AC
	INC    / ++AC
	ADD R  / AC += M[R]
 	SZE    / (E == 0) ? skip next
	BUN DIV2 / goto DIV2
DIV3,  
	CLA    / AC <- 0
	LDA W  / AC <- M[W]
	INC    / ++AC
	STA W  / M[W] <- AC
	CLA    / AC <- 0
	BUN DIV0 / goto DIV0
DIV2,
  STA R  / M[R] <- AC
	CLA    / AC <- 0
	LDA N1 / AC <- M[N1]
	INC    / ++AC
	STA N1 / M[N1] <- AC
 	BUN DIV3 / goto DIV3
/ data
N,	HEX ffff   N = ffff --> X:init   --> result
N1,	DEC 0
Y,	DEC 2
Y1,	DEC 2
R,	HEX 0
W,	DEC 0
W1,	DEC -16
VM1,	DEC -1
END

