`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_exaAle
 *
 * This is an exaAle of a (trivially siAle) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "Arj_counter" for the
 * exaAle programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_systollic #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);


reg  [7:0]  A11;
reg  [7:0]  A12;
reg  [7:0]  A21;
reg  [7:0]  A22;

// Matrix B
reg  [7:0]  B11;
reg  [7:0]  B12;
reg  [7:0]  B21;
reg  [7:0]  B22;


// Result  //
reg [15:0] C11;
reg [15:0] C12;
reg [15:0] C21;
reg [15:0] C22;

wire clk;
    localparam A_OFF = 8'h00, B_OFF = 8'h04, C1_OFF = 8'h08, C2_OFF = 8'h0C, C2_OFF = 8'h10, C2_OFF = 8'h14;
    //  WB Interface
    //  3 32 regsisters:
    //  A  (RW)    0x00 
    //  A  (RW)    0x04
    //  P   (RO)    0x08
   
    wire                valid           = wbs_stb_i & wbs_cyc_i;
    wire                we              = wbs_we_i && valid;
    wire                re              = ~wbs_we_i && valid;
    wire [3:0]          byte_wr_en      = wbs_sel_i & {4{we}}; 
    wire                we_A_reg       = we & (wbs_adr_i[7:0] == A_OFF);
    wire                we_B_reg       = we & (wbs_adr_i[7:0] == B_OFF);
    wire                re_A_reg       = re & (wbs_adr_i[7:0] == A_OFF);
    wire                re_B_reg       = re & (wbs_adr_i[7:0] == B_OFF);
    wire                re_C1_reg      = re & (wbs_adr_i[7:0] == C1_OFF);
    wire                re_C2_reg      = re & (wbs_adr_i[7:0] == C2_OFF);
    wire                re_C3_reg      = re & (wbs_adr_i[7:0] == C3_OFF);
    wire                re_C4_reg      = re & (wbs_adr_i[7:0] == C4_OFF);

    assign clk = wb_clk_i;
    
    always @(posedge clk or posedge wb_rst_i) begin // Always block to assign A
        if(wb_rst_i) begin

            A11 <= 8'h0;
            A12 <= 8'h0;
            A21 <= 8'h0;
            A22 <= 8'h0;
            end
        else if(we_A_reg)  
        begin
            A11 <= wbs_dat_i[7:0];
            A12 <= wbs_dat_i[15:8];
            A21 <= wbs_dat_i[23:16];
            A22 <= wbs_dat_i[31:24];
            end
    end

    always @(posedge clk or posedge wb_rst_i) begin // Always block to assign A
        if(wb_rst_i)   begin
            B11 <= 8'h0;
            B12 <= 8'h0;
            B21 <= 8'h0;
            B22 <= 8'h0;
            end
        else if(we_B_reg) begin
            B11 <= wbs_dat_i[7:0];
            B12 <= wbs_dat_i[15:8];
            B21 <= wbs_dat_i[23:16];
            B22 <= wbs_dat_i[31:24];
    end 
    end

    assign      wbs_dat_o   =   (re_C1_reg) ?   C11[15:0]   :
                                (re_C2_reg) ?   P[31:16]  :
                                (re_C3_reg) ?   P[47:32]  :
                                (re_C4_reg) ?   P[63:48]  :
                                (re_A_reg) ?   A  :
                                (re_B_reg) ?   B  :
                                32'hDEADBEEF;

    assign      wbs_ack_o   =   (we_A_reg || we_B_reg || (re_C1_reg && done) || (re_C2_reg && done)|| (re_C3_reg && done)|| (re_C4_reg && done))   ?   1'b1    :   1'b0;
    

    assign irq = 3'b000;	
    systolic_array sys(
        .clk(clk),
        .rst(wb_rst_i),
        .a11(A11),
        .a12(A12),
        .a21(A21),
        .a22(A22),
        .b11(B11),
        .b12(B12),
        .b21(B21),
        .b22(B22),
        .c11(C11),
        .c12(C12),
        .c21(C21),
        .c22(C22),
    );

endmodule

`default_nettype wire







