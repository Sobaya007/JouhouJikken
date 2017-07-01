		ORG 0		/ interrupt entry point
ST0,HEX 0		/ interrupt return address
	BUN I_HND	/ goto I_HND (interrupt handler)

	ORG 10		/ program entry point
INI, / initialize data
	CLA			/ AC <- 0
	STA STT		/ M[STT] <- 0
/ IMSK[3:0] : { S_IN, S_OUT, P_IN, P_OUT }
	LDA VH8		/ AC <- M[VH8] (1000)
	IMK			/ IMSK <- (1000) (S_IN enabled)
	ISZ P_INPUT
	ISZ P_H_INPUT
	SIO			/ IOT <- 1 (serial-IO selected)
	ION			/ enable interrupt
L0, LDA STT		/ AC <- M[STT]
	SNA			/ (M[STT] < 0) ? skip next
	BUN L0
	LDA INPUT
	SZA
	BUN LX
	
/////////// subroutine (check end-character) ////////
CEC,HEX 0
/ arg0 (AC) : output character
/ end-character = 0xd (ENTER)
	ADD ENT		/ AC <- AC - d
	SZA			/ (AC == 0) ? skip next
	BUN CEC2	/ return from CEC
/ output character matches (ctrl-D)
CEC3,	
	LDA SPC
	OUT
RL3,
	SKO
	BUN RL3
	LDA VM1		/ AC <- -1
	STA STT		/ M[STT] <- -1
	CLA			/ AC <- 0
	IMK			/ IMSK <- 0 (all interrupts disabled)
	BUN CEC I	/ return from CEC
CEC2,
	LDA SDT
	STA P_INPUT I
	ISZ INPUT
	BSA LCH
	ISZ P_INPUT
	ISZ P_H_INPUT
	ISZ H_INPUT
	ISZ INPUT_COUNT
	BUN CEC I
	BUN CEC3
/////////// interrupt handler /////////
/ 1. store AC & E to memory
I_HND, STA BA	/ M[BA] <- AC	(store AC)
	CIL			/ AC[0] <- E	(AC[15:1] is not important here...)
	STA BE		/ M[BE] <- AC	(store E)
/ 2. check SFG and S_IN
SIN,
	SKI			/ (S_IN ready) ? skip next
	BUN IRT		/ goto IRT
	INP			/ AC(7:0) <- INPR
	STA SDT		/ M[SDT] <- AC
	BSA CEC		/ call CEC (check end-character)
/ 4. restore AC & E from memory
IRT,LDA BE		/ AC <- M[BE]
	CIR			/ E <- AC[0]	(restore E)
	LDA BA		/ AC <- M[BA]	(restore AC)
	ION			/ IEN <- 1		(enable interrupt)
	BUN ST0 I	/ indirect return (return address stored in ST0)

	
/loading input
/  X(HEX) <- H_INPUT(CHR)[]
LX,
	CLA    / AC <- 0
	LDA H_INPUT  / AC <- M[H_INPUT]
	CMA    / AC <- ~AC
	INC    / ++AC
	STA H_INPUT_COUNT / M[H_INPUT_COUNT] <- AC
	ADD P_H_INPUT / AC += M[P_H_INPUT]
	STA P_H_INPUT / M[P_H_INPUT] <- AC
	CLA
LX1,
	ADD P_H_INPUT I
	ISZ H_INPUT_COUNT
	BUN LX2
	STA X
	CLA
	BUN LD
LX2,
	CIL
	CIL
	CIL
	CIL
	ISZ P_H_INPUT
	BUN LX1
	
	
	
	
/ start finding prime number
/ N1 <- N, call DIV, M[R] == 0 ?
LD,
	LDA X
	STA N
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
	BUN RES
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
RES,
	LDA N
	STA RESULT
/ Z(CHR)[] <- X(HEX)
LZ,
	LDA W1 / AC <- M[W1]
	STA W  / M[W] <- AC
	CLA    / AC <- 0
 	ISZ Z  / ++M[Z]
	ISZ PZ / ++M[PZ]
	LDA N  / AC <- M[N]
	ADD VM10 / AC -= 10
	CME    / E <- ~E
	SZE    / (E == 0) ? skip next
	BUN LZ5 / goto LZ5
LZ0,   
	LDA W  / AC <- M[W]
	SNA    / (AC < 0) ? skip next
	BUN LZ4 / goto LZ4
LZ1, 	
	CLE    / E <- 0
	CLA    / AC <- 0
	LDA N  / AC <- M[N]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA N  / M[N] <- AC
	CLA    / AC <- 0
 	LDA PZ I / AC <- M[M[PZ]]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA PZ I / M[M[PZ]] <- AC 
	LDA M  / AC <- M[M]
	CMA    / AC <- ~AC
	INC    / ++AC
	ADD PZ I / AC += M[M[PZ]] 
	SZE    / (E == 0) ? skip next
	BUN LZ2 / goto LZ2
LZ3,
  CLA    / AC <- 0
	LDA W  / AC <- M[W]
	INC    / ++AC
	STA W  / M[W] <- AC
	CLA    / AC <- 0
	BUN LZ0 / goto LZ0
LZ2,   
	STA PZ I / M[M[PZ]] <- AC
	CLA    / AC <- 0
	LDA N  / AC <- M[N]
	INC    / ++AC
	STA N  / AC <- M[N]
	BUN LZ3 / goto LZ3
LZ4,
	LDA PZ I/ AC <- M[M[PZ]] 
	ADD VP48 / AC += 48
	STA PZ I / AC <- M[M[PZ]]
	BUN LZ / goto M[LZ]
LZ5,	
	CLA    / AC <- 0
	LDA N  / AC <- M[N]
	ADD VP48 / AC += 48
	STA PZ I / M[M[PZ]] <- AC 
O_L,
	LDA PZ
	STA POUT
	LDA Z
	CMA
	INC
	STA POUT_COUNT
O_L1,
	SIO
	IOF
	LDA VH4
	IMK
	LDA POUT I
	OUT
RL,
	SKO
	BUN RL
	LDA POUT
	ADD VM1
	STA POUT
	ISZ POUT_COUNT
	BUN O_L1
	LDA SPC
	OUT
RL2,
	SKO
	BUN RL2
	LDA RESULT
	ADD VM1
	STA X
INIT,
	CLA
	STA N
	STA N1
	LDA Y
	STA Y1
	CLA
	STA R
	STA W
	LDA PZ_INIT
	STA PZ
	CLA
	STA PZ I
	ISZ PZ
	STA PZ I
	ISZ PZ
	STA PZ I
	ISZ PZ
	STA PZ I
	ISZ PZ
	STA PZ I
	ISZ PZ
	STA PZ I
	LDA PZ_INIT
	STA PZ
	CLA
	STA POUT
	STA POUT_COUNT
RETURN,
	LDA X
	ADD VM1
	SZA
	BUN LD
	HLT
/ A(HEX)[] <- N(CHR)[], error check
LCH,	
	HEX 0  / return address
	LDA P_INPUT I / AC <- M[M[P_INPUT]]
	ADD VM48 / AC -= 48
	STA P_H_INPUT I / M[M[P_H_INPUT]] <- AC
	SPA    / (AC >= 0) ? skip next
	BUN ERR / goto ERR
	ADD VM10 / AC -= 10
	SPA    / (AC >= 0) ? skip next
	BUN LCH I/ goto LCH
	LDA P_INPUT I/ AC <- M[P_INPUT]	
	ADD VM55 / AC -= 55
	STA P_H_INPUT I / AC <-M[M[P_H_INPUT]] 
	ADD VM10 / AC -= 10
	SPA    / (AC >= 0) ? skip next
	BUN ERR / goto ERR
	ADD VM6 / AC -= 6
	SPA    / (AC >= 0) ? skip next
	BUN LCH I / goto LCH
	BUN ERR / goto ERR
ERR,
	LDA PEMG I / AC [PEMG] PEMG: error message address
	OUT    / OUTR <- AC
RL4,
	SKO
	BUN RL4
	ISZ PEMG / ++M[PEMG]
	ISZ ECNT / ++M[ECNT] (M[ECNT] == 0) ? skip next
	BUN ERR / goto ERR 
	HLT
	
/ data
X,  DEC 0
RESULT, HEX 0
N,	DEC 0    N = ffff --> X:init   --> result
N1,	DEC 0
Y,	DEC 2
Y1,	DEC 2
R,	HEX 0
W,	DEC 0
W1,	DEC -16
Z,  HEX 0  / length init: 0
	HEX 0  / A(HEX) --> Y(DEC) init: 00000 
	HEX 0
	HEX 0
	HEX 0
	HEX 0
PZ,	SYM Z / Z pointer address
PZ_INIT, SYM Z
POUT, HEX 0
POUT_COUNT, HEX 0
VM48,	DEC -48
VP48,   DEC 48
VM55,	DEC -55
VM6,    DEC -6
VM10,   DEC -10
M,  DEC 10
SPC,  HEX 20
INPUT, HEX 0
	HEX 0
	HEX 0
	HEX 0
	HEX 0
P_INPUT, SYM INPUT
INPUT_COUNT, DEC -4
H_INPUT, HEX 0
	HEX 0
	HEX 0
	HEX 0
	HEX 0
P_H_INPUT, SYM H_INPUT
H_INPUT_COUNT, DEC 0
/ data (no initialization)
BA, DEC 000		/ backup storage for AC during interrupt handling
BE, DEC 000		/ backup storage for  E during interrupt handling
SDT,DEC 0		/ S_IN data
/ data (need initialization code)
STT,DEC 0       / state
/ data (read-only)
VH4,HEX 4       / VH4 = 0x4 (0100)
VH8,HEX 8       / VHA = 0x8 (1000)
VM1,DEC -1      / VM1 = -1
VM4,DEC -4		/ VM4 = -4
ENT, HEX -d
/ error message
EMG, HEX a 
	HEX 45		/ 'E'
	HEX 52		/ 'R'
	HEX 52		/ 'R'
	HEX 4f		/ 'O'
	HEX 52		/ 'R'
ECNT, DEC -6 / error counter 
PEMG,	SYM EMG / error message pointer address
END

