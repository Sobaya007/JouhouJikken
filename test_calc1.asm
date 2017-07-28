		ORG 0		/ interrupt entry point
ST0,HEX 0		/ interrupt return address
	BUN I_HND	/ goto I_HND (interrupt handler)

	ORG 10		/ program entry point
INI, / initialize data
		LDA VH8			/ AC <- 1000
		IMK				/ IMSK <- 1000 (S_IN enabled)
		SIO				/ IOT <- 1 (serial-IO selected)
/ initialize
		CLA				/ AC <- 0
		STA BYE			/ M[BYE] <- 0
		STA NXT_BYE		/ M[NXT_BYE] <- 0
		STA X			/ M[X] <- 0
		LDA CH_EQ		/ AC <- '='
		STA OPR			/ M[OPR] <- '='
		BSA INI_ST		/ call INI_ST (initialize state)
		ION				/ enable interrupt
/ wait until (M[BYE] = 1)
L0,		
		LDA BYE			/ AC <- M[BYE]
		SZA				/ (M[BYE] == 0) ? skip next
		HLT
		BUN L0			/ goto L0

INI_ST,	HEX 0
////////// subroutine (initialize state) ///////////
		CLA				/ AC      <- 0
		STA Y			/ M[Y]    <- 0
		STA Y_PD		/ M[Y_PD] <- 0
		STA STT			/ M[STT]  <- 0
		STA OUT_STT		/ M[OUT_STT] <- 0
		LDA VM10			/ AC      <- M[VM4] (-10)
		STA CNT			/ M[CNT]  <- -10
		BUN INI_ST I	/ return from INI_ST

/////////// interrupt handler ///////////
I_HND,	
/ store AC & E to memory
		STA BA			/ M[BA] <- AC	(store AC)
		CIL				/ AC[0] <- E	(AC[15:1] is not important here...)
		STA BE			/ M[BE] <- AC	(store E)

/////////// state machine ///////////
/ M[OUT_STT] != 0  : output pending
/ M[STT] = 0  : read hex inputs (up to 4 hex digits)
/ M[STT] = 1  : read operator (+,-,= : compute, others : end program...)
/ M[STT] >= 2 : output message
/ check state :
		LDA OUT_STT		/ AC <- M[OUT_STT]
		SZA				/ (M[OUT_STT] = 0) ? skip next
		BUN PUT_OUT		/ goto PUT_OUT (process output)

/////////// process input ///////////
/ input mode (M[TMI] <- INPR)
		SKI				/ (FGI = 0) ? skip next
		BUN IRT			/ goto IRT (return from interrupt handler) --> this should not happen...
		CLA				/ AC <- 0
		INP				/ AC[7:0] <- INPR
		STA TMI			/ M[TMI] <- INPR
		/BSA READ_HX		/ call READ_HX (read hex value to M[HXI](3:0))
		BSA READ_DX
		SPA				/ (AC >= 0) ? skip next
		BUN STT_1		/ goto STT_1 (non-hex input)
/ hex input :
/ check state 0 :
		LDA STT			/ AC <- M[STT]
		SZA				/ (AC = 0) ? skip next
		BUN ERR			/ goto ERR (error!!!)

/////////// state 0: read operand 1,2 ///////////
		LDA Y			/ AC <- M[Y]
		MUL VD10
		ADD DXI
		STA Y
		LDA VH1
		STA Y_PD
		ISZ CNT
		
		
/ operand digit pending
		BUN IRT			/ goto IRT (return from interrupt handler)
/ goto state 1 :
		ISZ STT			/ ++M[STT] (no skip)

/////////// return from interrupt handler ///////////
IRT,	
		LDA BE			/ AC <- M[BE]
		CIR				/ E  <- AC[0]	(restore E)
		LDA BA			/ AC <- M[BA]	(restore AC)
		ION				/ IEN <- 1		(enable interrupt)
		BUN ST0 I		/ indirect return (return address stored in ST0)

/////////// error !!!! ///////////
ERR,
		CLA				/ AC <- 0
		STA X			/ M[X] <- 0
		STA Y			/ M[Y] <- 0
		LDA A_EMG		/ AC <- M[A_EMG] (EMG)
		BSA SET_MSG		/ call SET_MSG (set message info)

/////////// prepare output ///////////
PRP_OUT,
		LDA VH1			/ AC <- M[VH1] (2)
		STA OUT_STT		/ M[OUT_STT] <- 1 (output state)
		LDA VH4			/ AC <- 0100
		IMK				/ IMSK <- 0100 (S_OUT enabled)
		BUN IRT			/ goto IRT (return from interrupt handler)

CHK_CH,	HEX 0			/ return address
////////// subroutine (check character) ///////////
/ arg0 (AC) : character to identify
/ return AC = 1 : character matched
/ return AC = 0 : character not matched
		CMA				/ AC <- ~AC
		INC				/ AC <- AC + 1 (AC = - arg0)
		ADD TMI			/ AC <- AC + M[TMI] (M[TMI] - arg0)
		SZA				/ (M[TMI] = arg0) ? skip next
		LDA VM1			/ AC <- M[VM1] (-1) (no match)
		INC				/ AC <- AC + 1
		BUN CHK_CH I	/ return from CHK_CH

/////////// state 1: read operator ///////////
STT_1,	/ cur-operator : M[TMI]
/ (cur-operator = ' ') ?
		LDA CH_WS		/ AC <- M[CH_WS] (' ')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not white-space)
		BUN STT_WS		/ goto STT_WS (handle white-space)
/ (cur-operator = '=') ?
		LDA CH_EQ		/ AC <- M[CH_EQ] ('=')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not '=')
		BUN STT_COMP	/ goto STT_COMP (compute on prev-operator)
/ (cur-operator = '+') ?
		LDA CH_PL		/ AC <- M[CH_PL] ('+')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not '+')
		BUN STT_COMP	/ goto STT_COMP (compute on prev-operator)
/ (cur-operator = '-') ?
		LDA CH_MN		/ AC <- M[CH_MN] ('-')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not '-')
		BUN STT_COMP	/ goto STT_COMP (compute on prev-operator)
/ (cur-operator = '*') ?
		LDA CH_MUL		/ AC <- M[CH_MN] ('*')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not '*')
		BUN STT_COMP	/ goto STT_COMP (compute on prev-operator)
/ (cur-operator = '/') ?
		LDA CH_DIV		/ AC <- M[CH_MN] ('/')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not '/')
		BUN STT_COMP	/ goto STT_COMP (compute on prev-operator)
/ (cur-operator = 'p') ?
		LDA CH_P		/ AC <- M[CH_MN] ('p')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not 'p')
		BUN STT_COMP	/ goto STT_COMP (compute on prev-operator)
/ (cur-operator = 'c') ?
		LDA CH_C		/ AC <- M[CH_MN] ('c')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not 'c')
		BUN STT_COMP	/ goto STT_COMP (compute on prev-operator)
/ (cur-operator = '^') ?
		LDA CH_EXP		/ AC <- M[CH_MN] ('^')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not '^')
		BUN STT_COMP	/ goto STT_COMP (compute on prev-operator)
/ (cur-operator is unsupported... : prepare to terminate this program)
		LDA VH1			/ AC <- M[VH1] (1)
		STA NXT_BYE		/ M[NXT_BYE] <- 1
		LDA A_BMG		/ AC <- M[A_BMG] (BMG)
		BSA SET_MSG		/ call SET_MSG (set message info)
		BUN PRP_OUT
/ current input is white-space : check (M[Y_PD] = 1) ?
STT_WS,
		LDA Y_PD		/ AC <- M[Y_PD]
		ADD VM1			/ AC <- M[Y_PD] - 1
		SZA				/ (M[Y_PD] - 1 = 0) ? skip next
/ no pending input
		BUN IRT			/ goto IRT (return from interrupt handler)
/ set STT <- 1 on white-space on pending input (M[Y_PD] = 1)
		LDA VH1			/ AC <- M[VH1] (1)
		STA STT			/ M[STT] <- 1
		BUN IRT			/ goto IRT (return from interrupt handler)
/ compute on prev-operator
STT_COMP,
/ swap M[OPR] (prev-operator) <-> M[TMI] (cur-operator)
		LDA OPR			/ AC     <- M[OPR]
		STA TMA			/ M[TMA] <- M[OPR]
		LDA TMI			/ AC     <- M[TMI]
		STA OPR			/ M[OPR] <- M[TMI]
		LDA TMA			/ AC     <- M[TMA]
		STA TMI			/ M[TMI] <- M[TMA]
/ (M[Y_PD] = 0) ?
		LDA Y_PD		/ AC <- M[Y_PD]
		SZA				/ (M[Y_PD] = 0) ? skip next
		BUN CHK_OP		/ goto CHK_OP (check prev-operator)
/ no input at M[Y] : copy M[X] to M[Y]
		LDA X			/ AC   <- M[X]
		STA Y			/ M[Y] <- M[X]
CHK_OP,
/ skip-output flag = 0
		CLA				/ AC     <- 0
		STA TMA			/ M[TMA] <- 0 (skip-output flag = 0)
/ (prev-operator = '=') ?
		LDA CH_EQ		/ AC <- M[CH_EQ] ('=')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN C_EQ		/ goto C_EQ (compute EQUAL)
/ (prev-operator = '+') ?
		LDA CH_PL		/ AC <- M[CH_PL] ('+')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN C_ADD		/ goto C_ADD (compute ADD)
/ (prev-operator = '-') ?
		LDA CH_MN		/ AC <- M[CH_PL] ('-')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN C_SUB		/ goto C_SUB (compute SUB)
/ (prev-operator = '*') ?
		LDA CH_MUL		/ AC <- M[CH_MUL] ('*')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN C_MUL		/ goto C_SUB (compute MUL)
/ (prev-operator = '/') ?
		LDA CH_DIV		/ AC <- M[CH_PL] ('/')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN C_DIV		/ goto C_SUB (compute DIV)
/ (prev-operator = 'p') ?
		LDA CH_P		/ AC <- M[CH_PL] ('p')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN C_P		/ goto C_P (compute xPy)
/ (prev-operator = 'c') ?
		LDA CH_C		/ AC <- M[CH_PL] ('c')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN C_C		/ goto C_C (compute xCy)
/ (prev-operator = '^') ?
		LDA CH_EXP		/ AC <- M[CH_PL] ('^')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN C_EXP		/ goto C_EXP (compute EXP)
/ (prev-operator is unsupported) ?
		BUN C_NONE		/ goto C_NONE (unsupported operator)
C_EQ,	/ EQUAL : M[Z] <- M[Y]
		ISZ TMA			/ ++M[TMA] (no skip) : skip-output flag = 1
		LDA Y			/ AC     <- M[Y]
		BUN STA_Z		/ goto STA_Z
C_ADD,	/ ADD : M[Z] <- M[X] + M[Y]
		LDA X			/ AC <- M[X]
		ADD Y			/ AC <- M[X] + M[Y]
		BUN STA_Z		/ goto STA_Z
C_SUB,	/ SUB : M[Z] <- M[X] - M[Y]
		LDA Y			/ AC <- M[Y]
		CMA				/ AC <- ~AC
		INC				/ AC <- AC + 1 (-M[Y])
		ADD X			/ AC <- M[X] - M[Y]
		BUN STA_Z		/ goto STA_Z
C_MUL,	/ MUL : M[Z] <- M[X] * M[Y]
		LDA Y			/ AC <- M[Y]
		MUL X			/ AC <- M[X] * M[Y]
		BUN STA_Z		/ goto STA_Z
C_DIV,	/ DIV : M[Z] <- M[X] / M[Y]
		LDA X			/ AC <- M[Y]
		DIV Y			/ AC <- M[X] / M[Y]
		BUN STA_Z		/ goto STA_Z
C_P,	/ P 
		LDA X
		STA P_X
		LDA Y
		STA P_Y
		BSA P			
		BUN STA_Z		/ goto STA_Z
C_C,	/ C 
		LDA X
		STA C_X
		LDA Y
		STA C_Y
		BSA C			
		BUN STA_Z		/ goto STA_Z
C_EXP,	/ EXP
		LDA X
		STA EXP_X
		LDA Y
		STA EXP_Y
		BSA EXP		
		BUN STA_Z		/ goto STA_Z
C_NONE, 
		CLA				/ AC <- 0 (just for now...)
STA_Z,	
		STA Z			/ M[Z] <- AC
		STA X			/ M[X] <- M[Z]
		CLA				/ AC <- 0
		STA Y			/ M[Y] <- 0
		STA Y_PD		/ M[Y_PD] <- 0
/ check skip-output flag
		LDA TMA			/ AC <- M[TMA] (skip-output flag)
		SZA				/ (AC = 0) ? skip next (prev-operator != '=')
		BUN SKIP_OUT	/ goto SKIP_OUT (prev-operator = '=')
/ write Z to Z_MSG
		/BSA WRITE_Z		/ call WRITE_Z (write Z to Z_MSG)
		/LDA A_ZMG		/ AC <- M[A_ZMG] (ZMG)
		BSA H2D
		LDA A_ZHMG
		BSA SET_MSG		/ call SET_MSG (set message info)
		BUN PRP_OUT
SKIP_OUT, / prev-operator is '=' : skip output
		BSA INI_ST		/ call INI_ST (initialize state)
		BUN IRT			/ goto IRT (return from interrupt handler)

SET_MSG,HEX 0
////////// subroutine (set message info) //////////
/ arg0 (AC) : message address
		STA PTR_MG		/ M[PTR_MG] <- arg0 (message address)
		ADD VM1			/ AC <- arg0 - 1
		STA TMA			/ M[TMA] <- arg0 - 1
		LDA TMA I		/ AC <- M[M[TMA]] (M[arg0 - 1] = message count)
		STA CNT			/ M[CNT] <- message count
		BUN SET_MSG I	/ return from SET_MSG

READ_DX,HEX	0
		LDA CH_0		/ AC <- M[CH_0] ('0')
		BSA CHK_DGT		/ call CHK_DGT (check digit character)
		DEC 0			/ 2nd argument to CHK_DGT (offset)
		DEC 9			/ 3rd argument to CHK_DGT (upper bound)
		SNA				/ (AC < 0) ? skip next
		BUN READ_DX I	/ return from RHX (M[HXI](3:0) = {0 to 9})
/ not dec value --> convert new-line (\n) and carrage-return (\r) to equal (=)
		LDA CH_NL		/ AC <- M[CH_NL] ('\n')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN CONV_EQ_D		/ goto CONV_EQ_D (convert to EQUAL)
		LDA CH_CR		/ AC <- M[CH_CR] ('\r')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN CONV_EQ_D		/ goto CONV_EQ_D (convert to EQUAL)
R_READ_DX,
		LDA VM1			/ AC <- M[VM1] (-1)
		BUN READ_DX I	/ return from RHX (not hex value)
CONV_EQ_D,
		LDA CH_EQ		/ AC <- M[CH_EQ] ('=')
		STA TMI			/ M[TMI] <- '='
		BUN R_READ_DX	/ goto R_READ_DX (return : not hex value)
		

CHK_DGT,HEX 0			/ return address
////////// subroutine (check digit character) //////////
/ arg0 (AC) : lower bound character
/ arg1 (M[M[CHK_DGT]]) : offset
/ arg2 (M[M[CHK_DGT]+1]) : upper bound value
/ return AC >= 0 : valid digit value in M[HXI](3:0)
/ return AC < 0  : not valid digit
/ check (M[TMI] >= lower bound)
		CMA				/ AC <- ~AC
		INC				/ AC <- AC + 1 (- arg0)
		ADD	TMI			/ AC <- AC + M[TMI] (M[TMI] - arg0)
		SPA				/ (AC = M[TMI] - arg0 >= 0) ? skip next
		BUN R_CHK1		/ goto R_CHK1 (return : AC < 0)
		STA TMA			/ M[TMA] <- M[TMI] - arg0
		ADD CHK_DGT I	/ AC <- M[TMI] - arg0 + arg1
		STA DXI			/ M[HXI] <- M[TMI] - arg0 + arg1 (actual hex value)
		ISZ CHK_DGT		/ ++M[CHK_DGT]
/ check (M[TMI] <= upper bound)
		LDA TMA			/ AC <- M[TMA] (M[TMI] - arg0)
		CMA				/ AC <- ~AC
		INC				/ AC <- AC + 1 (arg0 - M[TMI])
		ADD CHK_DGT I	/ AC <- arg2 - arg0 - M[TMI] (if (AC < 0) then not within bound)
		BUN R_CHK2		/ goto R_CHK2
R_CHK1,
		ISZ CHK_DGT		/ ++M[CHK_DGT]
R_CHK2,
		ISZ CHK_DGT		/ ++M[CHK_DGT]
		BUN CHK_DGT I	/ return from CHK_DGT


////////// process output //////////
PUT_OUT,
		SKO				/ (FGO = 0) ? skip next
		BUN IRT			/ goto IRT (return from interrupt handler) --> this should not happen...
/ here, AC = M[OUT_STT] : 
		ADD VM1			/ AC <- M[OUT_STT] - 1
		SZA				/ (M[OUT_STT] = 1) ? skip next
		BUN PUT_OUT_2	/ goto PUT_O2
/ M[OUT_STT] = 1 : put 1st newline 
		LDA CH_NL		/ AC <- M[CH_NL] ('\n')
		OUT				/ OUTR <- AC(7:0)
		ISZ OUT_STT		/ ++M[OUT_STT] (no skip)
		BUN IRT			/ goto IRT (return from interrupt handler)
/ check (M[OUT_STT] = 2) ?
PUT_OUT_2,
		ADD VM1			/ AC <- M[OUT_STT] - 1 - 1
		SZA				/ (M[OUT_STT] = 2) ? skip next
		BUN PUT_NL2		/ goto PUT_NL2
/ M[OUT_STT] = 2 : put message
		LDA PTR_MG I	/ AC <- M[M[PTR_MG]]
		OUT				/ OUTR <- AC(7:0)
		ISZ PTR_MG		/ ++M[PTR_MG] (no skip)
		ISZ CNT			/ (++M[CNT])= 0) ? skip next
		BUN IRT			/ goto IRT (return from interrupt handler)
		ISZ OUT_STT		/ ++M[OUT_STT] (no skip)
		BUN IRT			/ goto IRT (return from interrupt handler)
/ M[OUT_STT] = 3 : put 2nd newline (process output ends here...)
PUT_NL2,	
		LDA CH_NL		/ AC <- M[CH_NL] ('\n')
		OUT				/ OUTR <- AC(7:0)
		BSA INI_ST		/ call INI_ST (initialize state)
		LDA NXT_BYE		/ AC <- M[NXT_BYE]
		STA BYE			/ M[BYE] <- M[NXT_BYE]
		SZA				/ (M[NXT_BYE] == 0) ? skip next
		BUN EXT			/ goto EXT (disable all interrupts)
		LDA VH8			/ AC <- 1000
		IMK				/ IMK <- 1000 (S_IN enabled)
		BUN IRT			/ goto IRT (return from interrupt handler)
EXT,
		CLA				/ AC <- 0
		IMK				/ IMK <- 0000 (all interrupts disabled)
		BUN IRT			/ goto IRT (return from interrupt handler)
		

H2D, HEX 0
	LDA A_ZHMG
	ADD VH9
	STA A_ZHMG
	LDA VM10
	STA CNT
H2DINI,
	CLA
	STA A_ZHMG I
	LDA A_ZHMG
	ADD VM1
	STA A_ZHMG
	ISZ CNT
	BUN H2DINI
	LDA A_ZHMG
	ADD VD10
	STA A_ZHMG
	LDA VM10
	STA CNT
/ ZHMG(CHR)[] <- Z(HEX)
LHD,
	ISZ CNT_ZHMG
	LDA W1 / AC <- M[W1]
	STA W  / M[W] <- AC
	CLA    / AC <- 0
	LDA Z  / AC <- M[Z]
	ADD VM10 / AC -= 10
	CME    / E <- ~E
	SZE    / (E == 0) ? skip next
	BUN LHD5 / goto LHD5
LHD0,   
	LDA W  / AC <- M[W]
	SNA    / (AC < 0) ? skip next
	BUN LHD4 / goto LHD4
LHD1, 	
	CLE    / E <- 0
	CLA    / AC <- 0
	LDA Z  / AC <- M[Z]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA Z  / M[Z] <- AC
	CLA    / AC <- 0
 	LDA A_ZHMG I / AC <- M[M[A_ZHMG]]
	CIL    / {E,AC[15:0]} <- {AC[15:0],E}
	STA A_ZHMG I / M[M[A_ZHMG]] <- AC 
	LDA VHA  / AC <- M[M]
	CMA    / AC <- ~AC
	INC    / ++AC
	ADD A_ZHMG I / AC += M[M[A_ZHMG]] 
	SZE    / (E == 0) ? skip next
	BUN LHD2 / goto LHD2
LHD3,
  CLA    / AC <- 0
	LDA W  / AC <- M[W]
	INC    / ++AC
	STA W  / M[W] <- AC
	CLA    / AC <- 0
	BUN LHD0 / goto LHD0
LHD2,   
	STA A_ZHMG I / M[M[A_ZHMG]] <- AC
	CLA    / AC <- 0
	LDA Z  / AC <- M[Z]
	INC    / ++AC
	STA Z  / AC <- M[Z]
	BUN LHD3 / goto LHD3
LHD4,
	LDA A_ZHMG I/ AC <- M[M[A_ZHMG]] 
	ADD CH_0 / AC += 48
	STA A_ZHMG I / AC <- M[M[A_ZHMG]]
	LDA A_ZHMG
	ADD VM1
	STA A_ZHMG
	BUN LHD / goto M[LHD]
LHD5,	
	CLA    / AC <- 0
	LDA Z  / AC <- M[Z]
	ADD CH_0 / AC += 48
	STA A_ZHMG I / M[M[A_ZHMG]] <- AC 
	LDA A_ZHMG
	LDA CNT_ZHMG
	SNA
	BUN LHD7
LHD6,
	LDA A_ZHMG
	ADD VM1
	STA A_ZHMG
	LDA CH_0
	STA A_ZHMG I
	ISZ CNT_ZHMG
	BUN LHD6
LHD7,
	LDA VM10
	STA CNT_ZHMG
	CLA
	STA W
	BUN H2D I
	


P, HEX 0
P_1,
	LDA P_Z
	MUL P_Y
	STA P_Z
	LDA P_Y
	CMA
	ADD VH1
	ADD P_X
	SZA
	BUN P_2
	LDA P_Z
	STA P_RES
	CLA
	ADD VH1
	STA P_Z
	LDA P_RES
	BUN P I
P_2,
	ISZ P_Y
	BUN P_1
	
C, HEX 0
	LDA C_X
	STA P_X
	LDA C_Y
	CMA
	ADD VH2
	ADD C_X
	STA P_Y
	BSA P
	STA C_A
	LDA C_Y
	STA P_X
	LDA VH1
	STA P_Y
	BSA P
	STA C_B
	LDA C_A
	DIV C_B
	STA C_RES
	BUN C I
	
EXP, HEX 0
EXP_1,
	LDA EXP_A
	CMA
	ADD VH1
	ADD EXP_Y
	SZA
	BUN EXP_2
	LDA EXP_Z
	STA EXP_RES
	CLA
	ADD VH1
	STA EXP_Z
	CLA
	STA EXP_A
	LDA EXP_RES
	BUN EXP I
EXP_2,
	LDA EXP_Z
	MUL EXP_X
	STA EXP_Z
	ISZ EXP_A
	BUN EXP_1


/ data (no initialization)
Z,		DEC 0       / result
TMA,	DEC 0		/ temporal
TMB,	DEC 0		/ temporal
TMI,	DEC 0		/ char (raw) input
HXI,	DEC 0		/ hex input
BA,		DEC 000		/ backup storage for AC during interrupt handling
BE,		DEC 000		/ backup storage for  E during interrupt handling
PTR_MG, HEX 0		/ message pointer
/ data (need initialization code : one-time)
BYE,	DEC 0		/ (init: 0) bye
NXT_BYE,DEC 0		/ (init: 0) next bye
OPR,	DEC 0		/ (init: 0) operator
X,		DEC 0       / (init: 0) X operand
/ data (need initialization code : after every output -> INI_ST)
Y,		DEC 0       / (init: 0) Y operand
Y_PD,	DEC 0		/ (init: 0) Y pending
CNT,	DEC 0		/ (init: -4) digit count
STT,	DEC 0		/ (init: 0) 0: read operand, 1: read operator
OUT_STT,DEC 0		/ (init: 0) 0: output 1st newline, 1: output ans, 2: output 2nd newline
/ data (read-only)
AMK,	HEX FFF0	/ AMK = FFF0 (and mask)
AMKN,	HEX 000F	/ AMKN = 000F (and mask negated)
VH1,	HEX 1		/ VH1 = 1
VH2,	HEX 2		/ VH2 = 2
VH3,	HEX 3		/ VH3 = 3
VH4,	HEX 4		/ VH4 = 4
VH8,	HEX 8		/ VH8 = 8
VH9,  HEX 9
VHA,	HEX A		/ VHA = A
VM1,	DEC -1		/ VM1 = -1
VM2,	DEC -2		/ VM2 = -2
VM4,	DEC -4		/ VM2 = -4
VM5,  DEC -5
VM10,	DEC -10		/ VM10 = -10
CH_0,	HEX 30		/ '0'
CH_P, HEX 70
CH_C, HEX 63
CH_EXP, HEX 5E
CH_UA,	HEX 41		/ 'A'
CH_LA,	HEX 61		/ 'a'
CH_NL,	HEX 0A		/ '\n' (newline : line feed)
CH_CR,	HEX 0D		/ '\r' (carrage return : appears on DOS)
CH_WS,	HEX 20		/ ' ' (white space)
CH_EQ,	HEX 3D		/ '=' (equal)
CH_PL,	HEX 2B		/ '+' (plus)
CH_MN,	HEX 2D		/ '-' (minus)
CH_MUL,	HEX 2A		/ '*' (mul)
CH_DIV,	HEX 2F		/ '/' (div)
A_ZMG,	SYM ZMG
CNT_ZMG,DEC -4		/ CNT_ZMG = -4
ZMG,	HEX 0		/ hex digit 3
		HEX 0		/ hex digit 2
		HEX 0		/ hex digit 1
		HEX 0		/ hex digit 0
A_EMG,	SYM EMG
CNT_EMG,DEC -6		/ CNT_EMG = -6
EMG,	HEX 65		/ 'e'
		HEX 72		/ 'r'
		HEX 72		/ 'r'
		HEX 6F		/ 'o'
		HEX 72		/ 'r'
		HEX 21		/ '!'
A_BMG,	SYM BMG
CNT_BMG,DEC -4		/ CNT_BMG = -4
BMG,	HEX 62		/ 'b'
		HEX 79		/ 'y'
		HEX 65		/ 'e'
		HEX 21		/ '!'
/nakata
A_ZHMG,	SYM ZHMG
CNT_ZHMG,DEC -10		/ CNT_ZHMG = -10
ZHMG,
		HEX 0   / hex digit 9
		HEX 0		/ hex digit 8
		HEX 0		/ hex digit 7
		HEX 0		/ hex digit 6
		HEX 0		/ hex digit 5
		HEX 0   / hex digit 4
		HEX 0		/ hex digit 3
		HEX 0		/ hex digit 2
		HEX 0		/ hex digit 1
		HEX 0		/ hex digit 0
W, HEX 0
W1, DEC -32
DXI, DEC 0
VD10, DEC 10
VD100, DEC 100
VD1000, DEC 1000
VD10000, DEC 10000
P_X, DEC 0
P_Y, DEC 0
P_Z, DEC 1
P_RES, DEC 0
C_X, DEC 0
C_Y, DEC 0
C_A, DEC 1
C_B, DEC 1
C_RES, DEC 0
EXP_X, DEC 0
EXP_Y, DEC 0
EXP_A, DEC 0
EXP_Z, DEC 1
EXP_RES, DEC 0

END
