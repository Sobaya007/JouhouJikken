
`include "def_ex3.v"

module fpga_ex3
    (
    ////////////////////	Clock Input	 	////////////////////	 
    CLOCK_27,                       //  27 MHz
    ////////////////////	Push Button		////////////////////
    KEY,                            //  Pushbutton[3:0]
    ////////////////////	DPDT Switch		////////////////////
    SW,                             //  Toggle Switch[9:0]
    ////////////////////	7-SEG Display	////////////////////
    HEX0,                           //  Seven Segment Digit 0
    HEX1,                           //  Seven Segment Digit 1
    HEX2,                           //  Seven Segment Digit 2
    HEX3,                           //  Seven Segment Digit 3
    ////////////////////////	LED		////////////////////////
    LEDG,                           //  LED Green[7:0]
    LEDR,                           //  LED Red[9:0]
    ////////////////////////	UART	////////////////////////
    UART_TXD,                       //  UART Transmitter
    UART_RXD,                       //  UART Receiver
    ////////////////////	GPIO	////////////////////////////
    GPIO_0,                         //  GPIO Connection 0
    GPIO_1                          //  GPIO Connection 1
    );

    input           CLOCK_27;               //  27 MHz
    input   [3:0]   KEY;                    //  Pushbutton[3:0]
    input   [9:0]   SW;                     //  Toggle Switch[9:0]
    output  [6:0]   HEX0, HEX1, HEX2, HEX3; //  Seven Segment Digit 0,1,2,3
    output  [7:0]   LEDG;                   //  LED Green[7:0]
    output  [9:0]   LEDR;                   //  LED Red[9:0]
    output          UART_TXD;               //  UART Transmitter
    input           UART_RXD;               //  UART Receiver

    inout   [35:0]  GPIO_0;                 //  GPIO Connection 0 (inpr, outr, fgi_set, fgo_set, fgi, fgo)
    output  [35:0]  GPIO_1;                 //  GPIO Connection 1 (used for cpu monitoring)

    wire    [1:0]   gpio_mode = SW[9:8];
    wire    [1:0]   sys_mode  = SW[7:6];
    wire    [3:0]   sys_probe = SW[5:2];

    wire            intr_detect_fgi = SW[1];
    wire            intr_detect_fgo = SW[0];

    wire    [3:0]   gm, sm;
    wire    [15:0]  sp;

    dec_2to4  DEC_G (gpio_mode, gm, 1'b1);
    dec_2to4  DEC_M (sys_mode,  sm, 1'b1);
    dec_4to16 DEC_P (sys_probe, sp, 1'b1);

    wire    [17:0]  sys_probe_data;
    assign LEDG = sys_probe_data[7:0];
    assign LEDR = sys_probe_data[17:8];

    wire            clk = CLOCK_27;

    wire    [17:0]  GP_IN;					//	GPIO Input 0
    wire    [17:0]  GP_OUT;					//	GPIO Output 0

    assign  GPIO_0  =   (gm[1]) ? {GP_OUT, 18'hzzzzz} :  /// G1
                        (gm[2]) ? {18'hzzzzz, GP_OUT} :  /// G2
                        36'hzzzzzzzzz;                   /// G0

    assign  GP_IN   =   (gm[1]) ? GPIO_0[17:0]        :  /// G1
                        (gm[2]) ? GPIO_0[35:18]       :  /// G2
                        18'h0;                           /// G0

    reg     [3:0]   PREV_KEY;
    reg     [1:0]   cpu_state;

    reg     [11:0]  com_addr_reg, probe_idx;
    wire    [31:0]  probe_info;

    wire    [3:0]   probe_header = probe_info[31:28];
    wire    [11:0]  probe_addr = probe_info[27:16];

    rom_sync_4kx32 ROM (clk, probe_idx, probe_info);

    wire    KEY0    = ~KEY[0] & PREV_KEY[0]; /// detect 1->0 transition on KEY[0]
    wire    KEY1    = ~KEY[1] & PREV_KEY[1]; /// detect 1->0 transition on KEY[1]
    wire    KEY2    = ~KEY[2] & PREV_KEY[2]; /// detect 1->0 transition on KEY[2]
    wire    KEY3    = ~KEY[3] & PREV_KEY[3]; /// detect 1->0 transition on KEY[3]

    wire    insn_end, intr_detected, halted;

    initial cpu_state = `COM_RST; ///	cpu_state = S0 after power-on
    initial PREV_KEY  = 4'b0;     ///	PREV_KEY = 0000 after power-on

    wire    stop_cond = (sm[2] | (sm[3] & insn_end) | (sm[1] & intr_detected) | (halted & KEY1));

////////////       system finite state machine       //////////////
    always @ (posedge clk) begin
        PREV_KEY <= KEY;
        case(cpu_state)
//////////// COM_RST : reset state (after power on) //////////// 
            `COM_RST : begin
                if(KEY0)            cpu_state <= `COM_RUN;
                else if(KEY1)       cpu_state <= `COM_STP;
                com_addr_reg  <= 12'b0;
                probe_idx <= 12'b0;
            end
//////////// COM_RUN : run state //////////// 
            `COM_RUN : begin
                if(KEY0)            cpu_state <= `COM_RST;
                else if(stop_cond)  cpu_state <= `COM_STP;
            end
//////////// COM_STP : stop state //////////// 
            `COM_STP : begin
                if(KEY0)            cpu_state <= `COM_RST;
                else if(KEY1)       cpu_state <= `COM_RUN;
                if(halted) begin
                    if(KEY2 | (probe_header == `MEM_END)) probe_idx <= 12'b0;
                    else if(KEY3)                         probe_idx <= probe_idx + 1;
                    com_addr_reg  <= probe_addr;
                end
                else begin
                    if(KEY2)        com_addr_reg <= 12'b0;
                    else if(KEY3)   com_addr_reg <= com_addr_reg + 1;
                end
            end
        endcase
    end

    wire    [7:0]   inpr, outr, rx_byte, tx_byte;
    wire            tx_enable, rx_error;
    wire    [1:0]   fg_in, fg_in_set_n, fg_out, fg_out_set_n;
    wire    [15:0]  bus, mem, dr, ac, ir;
    wire    [11:0]  ar, pc;
    wire    [2:0]   sc;
    wire            s, r, e, ien, sc_clr;
    wire    [1:0]   imask, iosel;

    wire            rx_done_n, tx_done_n;

/**********************************************************************
                       GPIO connection:
board A(G1)                             board B(G2)
============================            ============================
GPIO_0[17:0]  = GP_IN [17:0]     <----- GPIO_0[17:0]  = GP_OUT[17:0]
GPIO_0[35:18] = GP_OUT[17:0]     -----> GPIO_0[35:18] = GP_IN [17:0]
----------------------------            ----------------------------
GP_IN [7:0]   = inpr[7:0]        <----- GP_OUT[7:0]   = outr[7:0]
GP_OUT[16]    = fg_in[0]         -----> GP_IN [16]    = fg_out_set_n[0]
GP_IN [17]    = fg_in_set_n[0]   <----- GP_OUT[17]    = fg_out[0]

GP_OUT[7:0]   = outr[7:0]        -----> GP_IN [7:0]   = inpr[7:0]
GP_IN [16]    = fg_out_set_n[0]  <----- GP_OUT[16]    = fg_in[0]
GP_OUT[17]    = fg_out[0]        -----> GP_IN [17]    = fg_in_set_n[0]

GP_OUT[11:10] = imask[1:0]       -----> GP_IN [11:10] (NO CONNECTION)
GP_OUT[12]    = fg_out_set_n[1]  -----> GP_IN [12]    (NO CONNECTION)
GP_OUT[13]    = fg_out[1]        -----> GP_IN [13]    (NO CONNECTION)
GP_OUT[14]    = fg_in_set_n[1]   -----> GP_IN [14]    (NO CONNECTION)
GP_OUT[15]    = fg_in[1]         -----> GP_IN [15]    (NO CONNECTION)
GP_IN [11:10] (NO CONNECTION)    <----- GP_OUT[11:10] = imask[1:0]
GP_IN [12]    (NO CONNECTION)    <----- GP_OUT[12]    = fg_out_set_n[1]
GP_IN [13]    (NO CONNECTION)    <----- GP_OUT[13]    = fg_out[1]
GP_IN [14]    (NO CONNECTION)    <----- GP_OUT[14]    = fg_in_set_n[1]
GP_IN [15]    (NO CONNECTION)    <----- GP_OUT[15]    = fg_in[1]
**********************************************************************/

    assign inpr = (iosel[1]) ? rx_byte : GP_IN[7:0];
    assign GP_OUT[7:0] = outr;
    assign fg_out_set_n  = { tx_done_n, GP_IN[16]};
    assign fg_in_set_n   = { rx_done_n, GP_IN[17]};
    assign GP_OUT[15:10] = { fg_in[1], fg_in_set_n[1], fg_out[1], fg_out_set_n[1], imask};
    assign GP_OUT[16] = fg_in[0];
    assign GP_OUT[17] = fg_out[0];

/****************
fg_out[1]       : 11111000000000000111111111100000000000011111111111
tx_enable       : 00000100000000000000000000010000000000000000000000
tx_rdy          : 11111100000000011111111111110000000001111111111111
tx_done_pulse_n : 11111111111111110011111111111111111111001111111111
****************/

    wire cpu_reset = (cpu_state == `COM_RST);

    reg    prev_fg_out1;
    always @(posedge clk) begin
        if(cpu_reset) prev_fg_out1 <= 1;
        else          prev_fg_out1 <= fg_out[1];
    end

    assign tx_enable = ~fg_out[1] & prev_fg_out1;
    assign tx_byte = outr;

    wire fgi = (iosel[1]) ? fg_in[1]  : fg_in[0];
    wire fgo = (iosel[0]) ? fg_out[1] : fg_out[0];

    assign intr_detected = r & sc_clr & (intr_detect_fgi & fgi | intr_detect_fgo & fgo);

    assign insn_end = sc_clr;

    wire [11:0] com_addr = (cpu_state == `COM_STP) ? com_addr_reg : pc;

    seg7_enc SEG7_E0 (4'h0,           HEX3);
    seg7_enc SEG7_E1 (com_addr[11:8], HEX2);
    seg7_enc SEG7_E2 (com_addr[7:4],  HEX1);
    seg7_enc SEG7_E3 (com_addr[3:0],  HEX0);

    assign halted = (s == 1'b0);
    assign GPIO_1[15:0] = ir;
    assign GPIO_1[27:16] = pc;
    assign GPIO_1[30:28] = sc;
    assign GPIO_1[31] = sc_clr;
    assign GPIO_1[32] = r;
    assign GPIO_1[33] = ien;
    assign GPIO_1[34] = s;
    assign GPIO_1[35] = 1'b0;

    assign sys_probe_data[15:0] = (sp[0])  ? ac :
                                  (sp[1])  ? {15'b0, e} :
                                  (sp[2])  ? {4'b0, pc} :
                                  (sp[3])  ? ir :
                                  (sp[4])  ? {4'b0, ar} :
                                  (sp[5])  ? dr :
                                  (sp[6])  ? mem :
                                  (sp[7])  ? bus :
                                  (sp[8])  ? {13'b0, sc} :
                                  (sp[9])  ? {11'b0, ien, imask, iosel} :
                                  (sp[10]) ? {4'b0, fg_in_set_n, fg_in, inpr} :
                                  (sp[11]) ? {4'b0, fg_out_set_n, fg_out, outr} :
                                  16'hffff;
    assign sys_probe_data[17:16] = cpu_state;

    cpu_ex3 CPU_EX3 (clk, cpu_state, com_addr,
            fg_in_set_n, fg_in, inpr,   /// input port
            fg_out_set_n, fg_out, outr, /// output port
            ien, imask, iosel,
            s, r, e, bus, mem, dr, ac, ir, ar, pc, sc, sc_clr);

    uart_rx UART_RX (clk, cpu_reset, UART_RXD, rx_byte, rx_error, fg_in[1], rx_done_n);
    uart_tx UART_TX (clk, cpu_reset, UART_TXD, tx_byte, tx_enable, fg_out[1], tx_done_n);

endmodule