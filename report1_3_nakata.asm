	ORG 10		/ program entry point
	SIO    / serial port select
/ A <- N.length, N <- ~N
L0,
	CLA    / AC <- 0
	LDA N  / AC <- M[N]
	STA A  / M[A] <- AC
	CMA    / AC <- ~AC
	INC    / ++AC
	STA N  / M[N] <- N
	CLA    / AC <- 0
/ ++M[PA], ++M[PN], call L2
L1,	
  ISZ PA / ++M[PA]
	ISZ PN / ++M[PN]
 	BSA L2 / call L2
	ISZ N  / ++M[N] (M[N] == 0) ? skip next
	BUN L1 / goto L1
/  X(HEX) <- A(CHR)[]
LX,	
	CLA    / AC <- 0
	LDA A  / AC <- M[A]
	CMA    / AC <- ~AC
	INC    / ++AC
	STA COUNT / M[COUNT] <- AC
	ADD PA / AC += M[PA]
	STA PA / M[PA] <- AC
	ISZ COUNT / ++M[COUNT]
	CLA    / AC <- 0
	ISZ PA / ++M[PA]
	ADD PA I / AC += M[M[PA]]
LX1,	
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	ISZ PA / ++M[PA]
	ADD PA I / AC += M[M[PA]]
	ISZ COUNT / ++M[COUNT]
	BUN LX1 / goto LX1
	STA X  / M[X] <- AC
/ Y(CHR)[] <- X(HEX)
LY,
	LDA W1 / AC <- M[W1]
	STA W  / M[W] <- AC
	CLA    / AC <- 0
 	ISZ Y  / ++M[Y]
	ISZ PY / ++M[PY]
	LDA X  / AC <- M[X]
	ADD VM10 / AC -= 10
	CME    / E <- ~E
	SZE    / (E == 0) ? skip next
	BUN LY5 / goto LY5
LY0,   
	LDA W  / AC <- M[W]
	SNA    / (AC < 0) ? skip next
	BUN LY4 / goto LY4
LY1, 	
	CLE    / E <- 0
	CLA    / AC <- 0
	LDA X  / AC <- M[X]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA X  / M[X] <- AC
	CLA    / AC <- 0
 	LDA PY I / AC <- M[M[PY]]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA PY I / M[M[PY]] <- AC 
	LDA M  / AC <- M[M]
	CMA    / AC <- ~AC
	INC    / ++AC
	ADD PY I / AC += M[M[PY]] 
	SZE    / (E == 0) ? skip next
	BUN LY2 / goto LY2
LY3,
  CLA    / AC <- 0
	LDA W  / AC <- M[W]
	INC    / ++AC
	STA W  / M[W] <- AC
	CLA    / AC <- 0
	BUN LY0 / goto LY0
LY2,   
	STA PY I / M[M[PY]] <- AC
	CLA    / AC <- 0
	LDA X  / AC <- M[X]
	INC    / ++AC
	STA X  / AC <- M[X]
	BUN LY3 / goto LY3
LY4,
	LDA PY I/ AC <- M[M[PY]] 
	ADD VP48 / AC += 48
	STA PY I / AC <- M[M[PY]]
	BUN LY / goto M[LY]
LY5,	
	CLA    / AC <- 0
	LDA X  / AC <- M[X]
	ADD VP48 / AC += 48
	STA PY I / M[M[PY]] <- AC 
	HLT
/ A(HEX)[] <- N(CHR)[], error check
L2,	
	HEX 0  / return address
	LDA PN I / AC <- M[M[PN]]
	ADD VM48 / AC -= 48
	STA PA I / M[M[PA]] <- AC
	SPA    / (AC >= 0) ? skip next
	BUN ERR / goto ERR
	ADD VM10 / AC -= 10
	SPA    / (AC >= 0) ? skip next
	BUN L2 I/ goto L2
	LDA PN I/ AC <- M[PN]	
	ADD VM55 / AC -= 55
	STA PA I / AC <-M[M[PA]] 
	ADD VM10 / AC -= 10
	SPA    / (AC >= 0) ? skip next
	BUN ERR / goto ERR
	ADD VM6 / AC -= 6
	SPA    / (AC >= 0) ? skip next
	BUN L2 I / goto L2
	BUN ERR / goto ERR
ERR,
	LDA PEMG I / AC [PEMG] PEMG: error message address
	OUT    / OUTR <- AC
	ISZ PEMG / ++M[PEMG]
	ISZ ECNT / ++M[ECNT] (M[ECNT] == 0) ? skip next
	BUN ERR / goto ERR 
	HLT
/ data
N,	DEC 4  / length init: 4
	CHR F  / N = FFFF input (HEX)
	CHR F
	CHR F
	CHR F
PN,	SYM N / N pointer address
X,  HEX 0 /
A,	HEX 0  / length init: 0
	HEX 0  / N(CHR) --> A(HEX) init: 0000
  HEX 0
	HEX 0
	HEX 0
PA, SYM A / A pointer address
Y,  HEX 0  / length init: 0
	HEX 0  / A(HEX) --> Y(DEC) init: 00000 
	HEX 0
	HEX 0
	HEX 0
	HEX 0
PY,	SYM Y / Y pointer address
/ error message
EMG, HEX 45		/ 'E'
	HEX 52		/ 'R'
	HEX 52		/ 'R'
	HEX 4f		/ 'O'
	HEX 52		/ 'R'
ECNT, DEC -5 / error counter 
PEMG,	SYM EMG / error message pointer address
W,	HEX 0 
W1,	DEC -16
M,  	DEC 10
COUNT, HEX 0
VM1,  	DEC -1
VM48,	DEC -48
VP48,   DEC 48
VM55,	DEC -55
VM6,    DEC -6
VM10,   DEC -10
END

