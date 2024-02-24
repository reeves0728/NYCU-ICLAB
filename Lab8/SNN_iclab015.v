//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network
//   Author     		: Hsien-Chi Peng (jhpeng2012@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SNN(
    //Input Port
    clk,
    rst_n,
    cg_en,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   REG & WIRE DECLARATIONS
//---------------------------------------------------------------------
// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
parameter rnd = 3'b000;
parameter IDLE = 0;
parameter CONV = 1;
parameter POOLING = 2;



input rst_n, clk, in_valid;
input cg_en;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

genvar i;
genvar h;
genvar p;
integer k;
integer j;
integer l;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

wire [7:0] status_mac_1,status_mac_2,status_mac_3,status_mac_4, status_cmp_1, status_cmp_2, status_add_1, status_add_2, status_add_3,status_add_4, status_cmp_3, status_cmp_4, status_recip_1, status_recip_2, status_recip_3, status_recip_4,status_exp1,status_exp2,status_exp3,status_exp4;
wire [inst_sig_width+inst_exp_width:0] mac1_out, mac2_out, mac3_out,mac4_out;
reg [inst_sig_width+inst_exp_width:0] comp_a, comp_b, comp_3, comp_4;
// reg [inst_sig_width+inst_exp_width:0] recip_in_1, recip_in_2, recip_in_3, recip_in_4;
// reg [inst_sig_width+inst_exp_width:0] recip_out_1, recip_out_2, recip_out_3, recip_out_4;

reg [inst_sig_width+inst_exp_width:0] a_div1, b_div1, div1_out;
reg [inst_sig_width+inst_exp_width:0] a_div2, b_div2, div2_out;
reg [inst_sig_width+inst_exp_width:0] a_div3, b_div3, div3_out;
reg [inst_sig_width+inst_exp_width:0] a_div4, b_div4, div4_out;

wire [inst_sig_width+inst_exp_width:0] cmp_z0, cmp_z1, cmp_z3, cmp_z4;
wire altb, agtb, aeqb, unordered; 
wire altb1, agtb1, aeqb1, unordered1; 

reg [inst_sig_width+inst_exp_width:0] input_img [0:95];
reg [inst_sig_width+inst_exp_width:0] input_kernel [0:26];
reg [inst_sig_width+inst_exp_width:0] input_weight [0:3];

reg [inst_sig_width+inst_exp_width:0] a_mac1, b_mac1, c_mac1;
reg [inst_sig_width+inst_exp_width:0] a_mac2, b_mac2, c_mac2;
reg [inst_sig_width+inst_exp_width:0] a_mac3, b_mac3, c_mac3;
reg [inst_sig_width+inst_exp_width:0] a_mac4, b_mac4, c_mac4;
reg [inst_sig_width+inst_exp_width:0] add_in1, add_in2, add_in3, add_in4;
reg [inst_sig_width+inst_exp_width:0] add_in1_1, add_in2_1, add_in3_1, add_in4_1;
reg [inst_sig_width+inst_exp_width:0] add_out1, add_out2, add_out3, add_out4;
reg [inst_sig_width+inst_exp_width:0] exp_in1, exp_in2, exp_in3, exp_in4;
reg [inst_sig_width+inst_exp_width:0] exp_out1, exp_out2, exp_out3, exp_out4;
reg [1:0] input_opt;
reg [inst_sig_width+inst_exp_width:0] image_padding [0:5][0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] kerenl [0:2][0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] kernel_select [0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] feature_map [0:3][0:3];
reg [inst_sig_width+inst_exp_width:0] pooling_map [0:1][0:1][0:1];
// reg [6:0] input_cnt;
reg [3:0] conv_9_cnt; 
reg [2:0] conv_6_cnt;
reg [1:0] conv_4_cnt;
reg [10:0] global_cnt;
reg [inst_sig_width+inst_exp_width:0] cmp_1_reg, cmp_2_reg, cmp_3_reg, cmp_4_reg;
wire [inst_sig_width+inst_exp_width:0] constant_1;


// Lab08 delcaration
reg [inst_sig_width+inst_exp_width:0] feature_map_0 [0:3][0:3];
reg [inst_sig_width+inst_exp_width:0] feature_map_padding_0 [0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] feature_map_1 [0:3][0:3];
reg [inst_sig_width+inst_exp_width:0] feature_map_padding_1 [0:5][0:5];

reg [inst_sig_width+inst_exp_width:0] feature_map_sum_0 [0:3][0:3];
reg [inst_sig_width+inst_exp_width:0] feature_map_sum_1 [0:3][0:3];

reg [inst_sig_width+inst_exp_width:0] sum1_1, sum1_2, sum1_3, sum1_out;
reg [inst_sig_width+inst_exp_width:0] sum2_1, sum2_2, sum2_3, sum2_out;
reg [inst_sig_width+inst_exp_width:0] sum3_1, sum3_2, sum3_3, sum3_out;
reg [inst_sig_width+inst_exp_width:0] sum4_1, sum4_2, sum4_3, sum4_out;
reg [inst_sig_width+inst_exp_width:0] sum_temp_9;
reg [inst_sig_width+inst_exp_width:0] div5_out;

wire [inst_sig_width+inst_exp_width:0] constant_9;

//---------------------------------------------------------------------
//   LAB08
//---------------------------------------------------------------------
assign constant_9 = 32'b0100_0001_0001_0000_0000_0000_0000_0000;

wire clk_1;
wire sleep_1;
assign sleep_1 = !(global_cnt == 112);
GATED_OR GATED_1 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_1), .RST_N(rst_n), .CLOCK_GATED(clk_1));

// feature_map_0
always @ (posedge clk_1 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_0[0][j] <= 0;
    end

    else
    begin
        if(global_cnt == 112)
        begin
                for(j=0;j<=3;j=j+1)
                    feature_map_0[0][j] <= feature_map[0][j];
        end
    end
end

wire clk_2;
wire sleep_2;
assign sleep_2 = !(global_cnt == 112);
GATED_OR GATED_2 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_2), .RST_N(rst_n), .CLOCK_GATED(clk_2));

// feature_map_0
always @ (posedge clk_2 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_0[1][j] <= 0;
    end

    else
    begin
        if(global_cnt == 112)
        begin
                for(j=0;j<=3;j=j+1)
                    feature_map_0[1][j] <= feature_map[1][j];
        end
    end
end

wire clk_3;
wire sleep_3;
assign sleep_3 = !(global_cnt == 112);
GATED_OR GATED_3 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_3), .RST_N(rst_n), .CLOCK_GATED(clk_3));
// feature_map_0
always @ (posedge clk_3 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_0[2][j] <= 0;
    end

    else
    begin
        if(global_cnt == 112)
        begin
                for(j=0;j<=3;j=j+1)
                    feature_map_0[2][j] <= feature_map[2][j];
        end
    end
end

wire clk_4;
wire sleep_4;
assign sleep_4 = !(global_cnt == 112);
GATED_OR GATED_4 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_4), .RST_N(rst_n), .CLOCK_GATED(clk_4));
// feature_map_0
always @ (posedge clk_4 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_0[3][j] <= 0;
    end

    else
    begin
        if(global_cnt == 112)
        begin
                for(j=0;j<=3;j=j+1)
                    feature_map_0[3][j] <= feature_map[3][j];
        end
    end
end

// feature_map_padding_0
always @ (*)
begin
    for(k=0;k<=3;k=k+1)
        for(j=0;j<=3;j=j+1)
            feature_map_padding_0[k+1][j+1] = feature_map_0[k][j];
    if(input_opt == 2'd0 || input_opt == 2'd2)
    begin
        feature_map_padding_0[0][0] = feature_map_0[0][0];
        feature_map_padding_0[0][1] = feature_map_0[0][0];
        feature_map_padding_0[0][2] = feature_map_0[0][1];
        feature_map_padding_0[0][3] = feature_map_0[0][2];
        feature_map_padding_0[0][4] = feature_map_0[0][3];
        feature_map_padding_0[0][5] = feature_map_0[0][3];
        feature_map_padding_0[1][0] = feature_map_0[0][0];
        feature_map_padding_0[1][5] = feature_map_0[0][3];
        feature_map_padding_0[2][0] = feature_map_0[1][0]; 
        feature_map_padding_0[2][5] = feature_map_0[1][3]; 
        feature_map_padding_0[3][0] = feature_map_0[2][0]; 
        feature_map_padding_0[3][5] = feature_map_0[2][3]; 
        feature_map_padding_0[4][0] = feature_map_0[3][0];  
        feature_map_padding_0[4][5] = feature_map_0[3][3]; 
        feature_map_padding_0[5][0] = feature_map_0[3][0];
        feature_map_padding_0[5][1] = feature_map_0[3][0]; 
        feature_map_padding_0[5][2] = feature_map_0[3][1];
        feature_map_padding_0[5][3] = feature_map_0[3][2];
        feature_map_padding_0[5][4] = feature_map_0[3][3];
        feature_map_padding_0[5][5] = feature_map_0[3][3];
    end

    else
    begin
        feature_map_padding_0[0][0] = 0;
        feature_map_padding_0[0][1] = 0;  
        feature_map_padding_0[0][2] = 0;
        feature_map_padding_0[0][3] = 0;  
        feature_map_padding_0[0][4] = 0;
        feature_map_padding_0[0][5] = 0;  
        feature_map_padding_0[1][0] = 0;  
        feature_map_padding_0[1][5] = 0;  
        feature_map_padding_0[2][0] = 0;  
        feature_map_padding_0[2][5] = 0;  
        feature_map_padding_0[3][0] = 0;  
        feature_map_padding_0[3][5] = 0;  
        feature_map_padding_0[4][0] = 0;  
        feature_map_padding_0[4][5] = 0;  
        feature_map_padding_0[5][0] = 0;
        feature_map_padding_0[5][1] = 0;  
        feature_map_padding_0[5][2] = 0;
        feature_map_padding_0[5][3] = 0;  
        feature_map_padding_0[5][4] = 0;
        feature_map_padding_0[5][5] = 0;  
    end
end


wire clk_5;
wire sleep_5;
assign sleep_5 = !(global_cnt == 220);
GATED_OR GATED_5 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_5), .RST_N(rst_n), .CLOCK_GATED(clk_5));
// feature_map_1
always @ (posedge clk_5 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_1[0][j] <= 0;
    end

    else
    begin
        if(global_cnt == 220)
        begin
                for(j=0;j<=3;j=j+1)
                    feature_map_1[0][j] <= feature_map[0][j];
        end
    end
end


wire clk_6;
wire sleep_6;
assign sleep_6 = !(global_cnt == 220);
GATED_OR GATED_6 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_6), .RST_N(rst_n), .CLOCK_GATED(clk_6));
// feature_map_1
always @ (posedge clk_6 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_1[1][j] <= 0;
    end

    else
    begin
        if(global_cnt == 220)
        begin
                for(j=0;j<=3;j=j+1)
                    feature_map_1[1][j] <= feature_map[1][j];
        end
    end
end

wire clk_7;
wire sleep_7;
assign sleep_7 = !(global_cnt == 220);
GATED_OR GATED_7 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_7), .RST_N(rst_n), .CLOCK_GATED(clk_7));

// feature_map_1
always @ (posedge clk_7 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_1[2][j] <= 0;
    end

    else
    begin
        if(global_cnt == 220)
        begin
                for(j=0;j<=3;j=j+1)
                    feature_map_1[2][j] <= feature_map[2][j];
        end
    end
end


wire clk_8;
wire sleep_8;
assign sleep_8 = !(global_cnt == 220);
GATED_OR GATED_8 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_8), .RST_N(rst_n), .CLOCK_GATED(clk_8));
// feature_map_1
always @ (posedge clk_8 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_1[3][j] <= 0;
    end

    else
    begin
        if(global_cnt == 220)
        begin
                for(j=0;j<=3;j=j+1)
                    feature_map_1[3][j] <= feature_map[3][j];
        end
    end
end

// feature_map_padding_1
always @ (*)
begin
    for(k=0;k<=3;k=k+1)
        for(j=0;j<=3;j=j+1)
            feature_map_padding_1[k+1][j+1] = feature_map_1[k][j];
    if(input_opt == 2'd0 || input_opt == 2'd2)
    begin
        feature_map_padding_1[0][0] = feature_map_1[0][0];
        feature_map_padding_1[0][1] = feature_map_1[0][0];
        feature_map_padding_1[0][2] = feature_map_1[0][1];
        feature_map_padding_1[0][3] = feature_map_1[0][2];
        feature_map_padding_1[0][4] = feature_map_1[0][3];
        feature_map_padding_1[0][5] = feature_map_1[0][3];
        feature_map_padding_1[1][0] = feature_map_1[0][0];
        feature_map_padding_1[1][5] = feature_map_1[0][3];
        feature_map_padding_1[2][0] = feature_map_1[1][0]; 
        feature_map_padding_1[2][5] = feature_map_1[1][3]; 
        feature_map_padding_1[3][0] = feature_map_1[2][0]; 
        feature_map_padding_1[3][5] = feature_map_1[2][3]; 
        feature_map_padding_1[4][0] = feature_map_1[3][0];  
        feature_map_padding_1[4][5] = feature_map_1[3][3]; 
        feature_map_padding_1[5][0] = feature_map_1[3][0];
        feature_map_padding_1[5][1] = feature_map_1[3][0]; 
        feature_map_padding_1[5][2] = feature_map_1[3][1];
        feature_map_padding_1[5][3] = feature_map_1[3][2];
        feature_map_padding_1[5][4] = feature_map_1[3][3];
        feature_map_padding_1[5][5] = feature_map_1[3][3];
    end

    else
    begin
        feature_map_padding_1[0][0] = 0;
        feature_map_padding_1[0][1] = 0;  
        feature_map_padding_1[0][2] = 0;
        feature_map_padding_1[0][3] = 0;  
        feature_map_padding_1[0][4] = 0;
        feature_map_padding_1[0][5] = 0;  
        feature_map_padding_1[1][0] = 0;  
        feature_map_padding_1[1][5] = 0;  
        feature_map_padding_1[2][0] = 0;  
        feature_map_padding_1[2][5] = 0;  
        feature_map_padding_1[3][0] = 0;  
        feature_map_padding_1[3][5] = 0;  
        feature_map_padding_1[4][0] = 0;  
        feature_map_padding_1[4][5] = 0;  
        feature_map_padding_1[5][0] = 0;
        feature_map_padding_1[5][1] = 0;  
        feature_map_padding_1[5][2] = 0;
        feature_map_padding_1[5][3] = 0;  
        feature_map_padding_1[5][4] = 0;
        feature_map_padding_1[5][5] = 0;  
    end
end

wire clk_9;
wire sleep_9;
assign sleep_9 = !(global_cnt == 114 || global_cnt == 115 || global_cnt == 116 || global_cnt == 117);
GATED_OR GATED_9 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_9), .RST_N(rst_n), .CLOCK_GATED(clk_9));
// feature_map_sum_0
always @ (posedge clk_9 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_sum_0[0][j] <= 0;
    end

    else
    begin
        if(global_cnt == 114) feature_map_sum_0[0][0] <= div5_out;
        if(global_cnt == 115) feature_map_sum_0[0][1] <= div5_out;
        if(global_cnt == 116) feature_map_sum_0[0][2] <= div5_out;
        if(global_cnt == 117) feature_map_sum_0[0][3] <= div5_out;
    end
end

wire clk_10;
wire sleep_10;
assign sleep_10 = !(global_cnt == 118 || global_cnt == 119 || global_cnt == 120 || global_cnt == 121);
GATED_OR GATED_10 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_10), .RST_N(rst_n), .CLOCK_GATED(clk_10));

// feature_map_sum_0
always @ (posedge clk_10 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_sum_0[1][j] <= 0;
    end

    else
    begin
        if(global_cnt == 118) feature_map_sum_0[1][0] <= div5_out;
        if(global_cnt == 119) feature_map_sum_0[1][1] <= div5_out;
        if(global_cnt == 120) feature_map_sum_0[1][2] <= div5_out;
        if(global_cnt == 121) feature_map_sum_0[1][3] <= div5_out;
    end
end

wire clk_11;
wire sleep_11;
assign sleep_11 = !(global_cnt == 122 || global_cnt == 123 || global_cnt == 124 || global_cnt == 125);
GATED_OR GATED_11 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_11), .RST_N(rst_n), .CLOCK_GATED(clk_11));
// feature_map_sum_0
always @ (posedge clk_11 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_sum_0[2][j] <= 0;
    end

    else
    begin

        if(global_cnt == 122) feature_map_sum_0[2][0] <= div5_out;
        if(global_cnt == 123) feature_map_sum_0[2][1] <= div5_out;
        if(global_cnt == 124) feature_map_sum_0[2][2] <= div5_out;
        if(global_cnt == 125) feature_map_sum_0[2][3] <= div5_out;
    end
end

wire clk_12;
wire sleep_12;
assign sleep_12 = !(global_cnt == 126 || global_cnt == 127 || global_cnt == 128 || global_cnt == 129);
GATED_OR GATED_12 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_12), .RST_N(rst_n), .CLOCK_GATED(clk_12));
// feature_map_sum_0
always @ (posedge clk_12 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_sum_0[3][j] <= 0;
    end

    else
    begin
        if(global_cnt == 126) feature_map_sum_0[3][0] <= div5_out;
        if(global_cnt == 127) feature_map_sum_0[3][1] <= div5_out;
        if(global_cnt == 128) feature_map_sum_0[3][2] <= div5_out;
        if(global_cnt == 129) feature_map_sum_0[3][3] <= div5_out;
    end
end

wire clk_13;
wire sleep_13;
assign sleep_13 = !(global_cnt == 222 || global_cnt == 223 || global_cnt == 224 || global_cnt == 225);
GATED_OR GATED_13 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_13), .RST_N(rst_n), .CLOCK_GATED(clk_13));

// feature_map_sum_1
always @ (posedge clk_13 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_sum_1[0][j] <= 0;
    end

    else
    begin
        if(global_cnt == 222) feature_map_sum_1[0][0] <= div5_out;
        if(global_cnt == 223) feature_map_sum_1[0][1] <= div5_out;
        if(global_cnt == 224) feature_map_sum_1[0][2] <= div5_out;
        if(global_cnt == 225) feature_map_sum_1[0][3] <= div5_out;
    end
end

wire clk_14;
wire sleep_14;
assign sleep_14 = !(global_cnt == 226 || global_cnt == 227 || global_cnt == 228 || global_cnt == 229);
GATED_OR GATED_14 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_14), .RST_N(rst_n), .CLOCK_GATED(clk_14));
// feature_map_sum_1
always @ (posedge clk_14 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_sum_1[1][j] <= 0;
    end

    else
    begin
        if(global_cnt == 226) feature_map_sum_1[1][0] <= div5_out;
        if(global_cnt == 227) feature_map_sum_1[1][1] <= div5_out;
        if(global_cnt == 228) feature_map_sum_1[1][2] <= div5_out;
        if(global_cnt == 229) feature_map_sum_1[1][3] <= div5_out;
    end
end

wire clk_15;
wire sleep_15;
assign sleep_15 = !(global_cnt == 230 || global_cnt == 231 || global_cnt == 232 || global_cnt == 233);
GATED_OR GATED_15 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_15), .RST_N(rst_n), .CLOCK_GATED(clk_15));
// feature_map_sum_1
always @ (posedge clk_15 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_sum_1[2][j] <= 0;
    end

    else
    begin
        if(global_cnt == 230) feature_map_sum_1[2][0] <= div5_out;
        if(global_cnt == 231) feature_map_sum_1[2][1] <= div5_out;
        if(global_cnt == 232) feature_map_sum_1[2][2] <= div5_out;
        if(global_cnt == 233) feature_map_sum_1[2][3] <= div5_out;
    end
end

wire clk_16;
wire sleep_16;
assign sleep_16 = !(global_cnt == 234 || global_cnt == 235 || global_cnt == 236 || global_cnt == 237);
GATED_OR GATED_16 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_16), .RST_N(rst_n), .CLOCK_GATED(clk_16));
// feature_map_sum_1
always @ (posedge clk_16 or negedge rst_n)
begin
    if(!rst_n)
    begin
            for(j=0;j<=3;j=j+1)
                feature_map_sum_1[3][j] <= 0;
    end

    else
    begin
        if(global_cnt == 234) feature_map_sum_1[3][0] <= div5_out;
        if(global_cnt == 235) feature_map_sum_1[3][1] <= div5_out;
        if(global_cnt == 236) feature_map_sum_1[3][2] <= div5_out;
        if(global_cnt == 237) feature_map_sum_1[3][3] <= div5_out;
    end
end

wire clk_17;
wire sleep_17;
assign sleep_17 = !((global_cnt >= 113 && global_cnt <= 128) || (global_cnt >= 221 && global_cnt <= 236));
GATED_OR GATED_17 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_17), .RST_N(rst_n), .CLOCK_GATED(clk_17));
// sum_temp_9
always @ (posedge clk_17 or negedge rst_n)
begin
    if(!rst_n) sum_temp_9 <= 0;
    else
    begin
        if(global_cnt >= 113 && global_cnt <= 128) sum_temp_9 <= sum4_out;
        if(global_cnt >= 221 && global_cnt <= 236) sum_temp_9 <= sum4_out;
    end
end

// sum1, sum2, sum3, sum4
always @ (*)
begin
    sum1_1 = 0;
    sum1_2 = 0;
    sum1_3 = 0;
    
    sum2_1 = 0;
    sum2_2 = 0;
    sum2_3 = 0;
    
    sum3_1 = 0;
    sum3_2 = 0;
    sum3_3 = 0;

    sum4_1 = sum1_out;
    sum4_2 = sum2_out;
    sum4_3 = sum3_out;

    if(global_cnt == 113)
    begin
        sum1_1 = feature_map_padding_0[0][0];
        sum1_2 = feature_map_padding_0[0][1];
        sum1_3 = feature_map_padding_0[0][2];

        sum2_1 = feature_map_padding_0[1][0];
        sum2_2 = feature_map_padding_0[1][1];
        sum2_3 = feature_map_padding_0[1][2];

        sum3_1 = feature_map_padding_0[2][0];
        sum3_2 = feature_map_padding_0[2][1];
        sum3_3 = feature_map_padding_0[2][2];
    end

    if(global_cnt == 114)
    begin
        sum1_1 = feature_map_padding_0[0][1];
        sum1_2 = feature_map_padding_0[0][2];
        sum1_3 = feature_map_padding_0[0][3];

        sum2_1 = feature_map_padding_0[1][1];
        sum2_2 = feature_map_padding_0[1][2];
        sum2_3 = feature_map_padding_0[1][3];

        sum3_1 = feature_map_padding_0[2][1];
        sum3_2 = feature_map_padding_0[2][2];
        sum3_3 = feature_map_padding_0[2][3];
    end

    if(global_cnt == 115)
    begin
        sum1_1 = feature_map_padding_0[0][2];
        sum1_2 = feature_map_padding_0[0][3];
        sum1_3 = feature_map_padding_0[0][4];

        sum2_1 = feature_map_padding_0[1][2];
        sum2_2 = feature_map_padding_0[1][3];
        sum2_3 = feature_map_padding_0[1][4];

        sum3_1 = feature_map_padding_0[2][2];
        sum3_2 = feature_map_padding_0[2][3];
        sum3_3 = feature_map_padding_0[2][4];
    end

    if(global_cnt == 116)
    begin
        sum1_1 = feature_map_padding_0[0][3];
        sum1_2 = feature_map_padding_0[0][4];
        sum1_3 = feature_map_padding_0[0][5];

        sum2_1 = feature_map_padding_0[1][3];
        sum2_2 = feature_map_padding_0[1][4];
        sum2_3 = feature_map_padding_0[1][5];

        sum3_1 = feature_map_padding_0[2][3];
        sum3_2 = feature_map_padding_0[2][4];
        sum3_3 = feature_map_padding_0[2][5];
    end

    if(global_cnt == 117)
    begin
        sum1_1 = feature_map_padding_0[1][0];
        sum1_2 = feature_map_padding_0[1][1];
        sum1_3 = feature_map_padding_0[1][2];

        sum2_1 = feature_map_padding_0[2][0];
        sum2_2 = feature_map_padding_0[2][1];
        sum2_3 = feature_map_padding_0[2][2];

        sum3_1 = feature_map_padding_0[3][0];
        sum3_2 = feature_map_padding_0[3][1];
        sum3_3 = feature_map_padding_0[3][2];
    end

    if(global_cnt == 118)
    begin
        sum1_1 = feature_map_padding_0[1][1];
        sum1_2 = feature_map_padding_0[1][2];
        sum1_3 = feature_map_padding_0[1][3];

        sum2_1 = feature_map_padding_0[2][1];
        sum2_2 = feature_map_padding_0[2][2];
        sum2_3 = feature_map_padding_0[2][3];

        sum3_1 = feature_map_padding_0[3][1];
        sum3_2 = feature_map_padding_0[3][2];
        sum3_3 = feature_map_padding_0[3][3];
    end

    if(global_cnt == 119)
    begin
        sum1_1 = feature_map_padding_0[1][2];
        sum1_2 = feature_map_padding_0[1][3];
        sum1_3 = feature_map_padding_0[1][4];

        sum2_1 = feature_map_padding_0[2][2];
        sum2_2 = feature_map_padding_0[2][3];
        sum2_3 = feature_map_padding_0[2][4];

        sum3_1 = feature_map_padding_0[3][2];
        sum3_2 = feature_map_padding_0[3][3];
        sum3_3 = feature_map_padding_0[3][4];
    end

    if(global_cnt == 120)
    begin
        sum1_1 = feature_map_padding_0[1][3];
        sum1_2 = feature_map_padding_0[1][4];
        sum1_3 = feature_map_padding_0[1][5];

        sum2_1 = feature_map_padding_0[2][3];
        sum2_2 = feature_map_padding_0[2][4];
        sum2_3 = feature_map_padding_0[2][5];

        sum3_1 = feature_map_padding_0[3][3];
        sum3_2 = feature_map_padding_0[3][4];
        sum3_3 = feature_map_padding_0[3][5];
    end

    if(global_cnt == 121)
    begin
        sum1_1 = feature_map_padding_0[2][0];
        sum1_2 = feature_map_padding_0[2][1];
        sum1_3 = feature_map_padding_0[2][2];

        sum2_1 = feature_map_padding_0[3][0];
        sum2_2 = feature_map_padding_0[3][1];
        sum2_3 = feature_map_padding_0[3][2];

        sum3_1 = feature_map_padding_0[4][0];
        sum3_2 = feature_map_padding_0[4][1];
        sum3_3 = feature_map_padding_0[4][2];
    end

    if(global_cnt == 122)
    begin
        sum1_1 = feature_map_padding_0[2][1];
        sum1_2 = feature_map_padding_0[2][2];
        sum1_3 = feature_map_padding_0[2][3];

        sum2_1 = feature_map_padding_0[3][1];
        sum2_2 = feature_map_padding_0[3][2];
        sum2_3 = feature_map_padding_0[3][3];

        sum3_1 = feature_map_padding_0[4][1];
        sum3_2 = feature_map_padding_0[4][2];
        sum3_3 = feature_map_padding_0[4][3];
    end

    if(global_cnt == 123)
    begin
        sum1_1 = feature_map_padding_0[2][2];
        sum1_2 = feature_map_padding_0[2][3];
        sum1_3 = feature_map_padding_0[2][4];

        sum2_1 = feature_map_padding_0[3][2];
        sum2_2 = feature_map_padding_0[3][3];
        sum2_3 = feature_map_padding_0[3][4];

        sum3_1 = feature_map_padding_0[4][2];
        sum3_2 = feature_map_padding_0[4][3];
        sum3_3 = feature_map_padding_0[4][4];
    end

    if(global_cnt == 124)
    begin
        sum1_1 = feature_map_padding_0[2][3];
        sum1_2 = feature_map_padding_0[2][4];
        sum1_3 = feature_map_padding_0[2][5];

        sum2_1 = feature_map_padding_0[3][3];
        sum2_2 = feature_map_padding_0[3][4];
        sum2_3 = feature_map_padding_0[3][5];

        sum3_1 = feature_map_padding_0[4][3];
        sum3_2 = feature_map_padding_0[4][4];
        sum3_3 = feature_map_padding_0[4][5];
    end

    if(global_cnt == 125)
    begin
        sum1_1 = feature_map_padding_0[3][0];
        sum1_2 = feature_map_padding_0[3][1];
        sum1_3 = feature_map_padding_0[3][2];

        sum2_1 = feature_map_padding_0[4][0];
        sum2_2 = feature_map_padding_0[4][1];
        sum2_3 = feature_map_padding_0[4][2];

        sum3_1 = feature_map_padding_0[5][0];
        sum3_2 = feature_map_padding_0[5][1];
        sum3_3 = feature_map_padding_0[5][2];
    end

    if(global_cnt == 126)
    begin
        sum1_1 = feature_map_padding_0[3][1];
        sum1_2 = feature_map_padding_0[3][2];
        sum1_3 = feature_map_padding_0[3][3];

        sum2_1 = feature_map_padding_0[4][1];
        sum2_2 = feature_map_padding_0[4][2];
        sum2_3 = feature_map_padding_0[4][3];

        sum3_1 = feature_map_padding_0[5][1];
        sum3_2 = feature_map_padding_0[5][2];
        sum3_3 = feature_map_padding_0[5][3];
    end

    if(global_cnt == 127)
    begin
        sum1_1 = feature_map_padding_0[3][2];
        sum1_2 = feature_map_padding_0[3][3];
        sum1_3 = feature_map_padding_0[3][4];

        sum2_1 = feature_map_padding_0[4][2];
        sum2_2 = feature_map_padding_0[4][3];
        sum2_3 = feature_map_padding_0[4][4];

        sum3_1 = feature_map_padding_0[5][2];
        sum3_2 = feature_map_padding_0[5][3];
        sum3_3 = feature_map_padding_0[5][4];
    end

    if(global_cnt == 128)
    begin
        sum1_1 = feature_map_padding_0[3][3];
        sum1_2 = feature_map_padding_0[3][4];
        sum1_3 = feature_map_padding_0[3][5];

        sum2_1 = feature_map_padding_0[4][3];
        sum2_2 = feature_map_padding_0[4][4];
        sum2_3 = feature_map_padding_0[4][5];

        sum3_1 = feature_map_padding_0[5][3];
        sum3_2 = feature_map_padding_0[5][4];
        sum3_3 = feature_map_padding_0[5][5];
    end

    if(global_cnt == 221)
    begin
        sum1_1 = feature_map_padding_1[0][0];
        sum1_2 = feature_map_padding_1[0][1];
        sum1_3 = feature_map_padding_1[0][2];

        sum2_1 = feature_map_padding_1[1][0];
        sum2_2 = feature_map_padding_1[1][1];
        sum2_3 = feature_map_padding_1[1][2];

        sum3_1 = feature_map_padding_1[2][0];
        sum3_2 = feature_map_padding_1[2][1];
        sum3_3 = feature_map_padding_1[2][2];
    end

    if(global_cnt == 222)
    begin
        sum1_1 = feature_map_padding_1[0][1];
        sum1_2 = feature_map_padding_1[0][2];
        sum1_3 = feature_map_padding_1[0][3];

        sum2_1 = feature_map_padding_1[1][1];
        sum2_2 = feature_map_padding_1[1][2];
        sum2_3 = feature_map_padding_1[1][3];

        sum3_1 = feature_map_padding_1[2][1];
        sum3_2 = feature_map_padding_1[2][2];
        sum3_3 = feature_map_padding_1[2][3];
    end

    if(global_cnt == 223)
    begin
        sum1_1 = feature_map_padding_1[0][2];
        sum1_2 = feature_map_padding_1[0][3];
        sum1_3 = feature_map_padding_1[0][4];

        sum2_1 = feature_map_padding_1[1][2];
        sum2_2 = feature_map_padding_1[1][3];
        sum2_3 = feature_map_padding_1[1][4];

        sum3_1 = feature_map_padding_1[2][2];
        sum3_2 = feature_map_padding_1[2][3];
        sum3_3 = feature_map_padding_1[2][4];
    end

    if(global_cnt == 224)
    begin
        sum1_1 = feature_map_padding_1[0][3];
        sum1_2 = feature_map_padding_1[0][4];
        sum1_3 = feature_map_padding_1[0][5];

        sum2_1 = feature_map_padding_1[1][3];
        sum2_2 = feature_map_padding_1[1][4];
        sum2_3 = feature_map_padding_1[1][5];

        sum3_1 = feature_map_padding_1[2][3];
        sum3_2 = feature_map_padding_1[2][4];
        sum3_3 = feature_map_padding_1[2][5];
    end

    if(global_cnt == 225)
    begin
        sum1_1 = feature_map_padding_1[1][0];
        sum1_2 = feature_map_padding_1[1][1];
        sum1_3 = feature_map_padding_1[1][2];

        sum2_1 = feature_map_padding_1[2][0];
        sum2_2 = feature_map_padding_1[2][1];
        sum2_3 = feature_map_padding_1[2][2];

        sum3_1 = feature_map_padding_1[3][0];
        sum3_2 = feature_map_padding_1[3][1];
        sum3_3 = feature_map_padding_1[3][2];
    end

    if(global_cnt == 226)
    begin
        sum1_1 = feature_map_padding_1[1][1];
        sum1_2 = feature_map_padding_1[1][2];
        sum1_3 = feature_map_padding_1[1][3];

        sum2_1 = feature_map_padding_1[2][1];
        sum2_2 = feature_map_padding_1[2][2];
        sum2_3 = feature_map_padding_1[2][3];

        sum3_1 = feature_map_padding_1[3][1];
        sum3_2 = feature_map_padding_1[3][2];
        sum3_3 = feature_map_padding_1[3][3];
    end

    if(global_cnt == 227)
    begin
        sum1_1 = feature_map_padding_1[1][2];
        sum1_2 = feature_map_padding_1[1][3];
        sum1_3 = feature_map_padding_1[1][4];

        sum2_1 = feature_map_padding_1[2][2];
        sum2_2 = feature_map_padding_1[2][3];
        sum2_3 = feature_map_padding_1[2][4];

        sum3_1 = feature_map_padding_1[3][2];
        sum3_2 = feature_map_padding_1[3][3];
        sum3_3 = feature_map_padding_1[3][4];
    end

    if(global_cnt == 228)
    begin
        sum1_1 = feature_map_padding_1[1][3];
        sum1_2 = feature_map_padding_1[1][4];
        sum1_3 = feature_map_padding_1[1][5];

        sum2_1 = feature_map_padding_1[2][3];
        sum2_2 = feature_map_padding_1[2][4];
        sum2_3 = feature_map_padding_1[2][5];

        sum3_1 = feature_map_padding_1[3][3];
        sum3_2 = feature_map_padding_1[3][4];
        sum3_3 = feature_map_padding_1[3][5];
    end

    if(global_cnt == 229)
    begin
        sum1_1 = feature_map_padding_1[2][0];
        sum1_2 = feature_map_padding_1[2][1];
        sum1_3 = feature_map_padding_1[2][2];

        sum2_1 = feature_map_padding_1[3][0];
        sum2_2 = feature_map_padding_1[3][1];
        sum2_3 = feature_map_padding_1[3][2];

        sum3_1 = feature_map_padding_1[4][0];
        sum3_2 = feature_map_padding_1[4][1];
        sum3_3 = feature_map_padding_1[4][2];
    end

    if(global_cnt == 230)
    begin
        sum1_1 = feature_map_padding_1[2][1];
        sum1_2 = feature_map_padding_1[2][2];
        sum1_3 = feature_map_padding_1[2][3];

        sum2_1 = feature_map_padding_1[3][1];
        sum2_2 = feature_map_padding_1[3][2];
        sum2_3 = feature_map_padding_1[3][3];

        sum3_1 = feature_map_padding_1[4][1];
        sum3_2 = feature_map_padding_1[4][2];
        sum3_3 = feature_map_padding_1[4][3];
    end

    if(global_cnt == 231)
    begin
        sum1_1 = feature_map_padding_1[2][2];
        sum1_2 = feature_map_padding_1[2][3];
        sum1_3 = feature_map_padding_1[2][4];

        sum2_1 = feature_map_padding_1[3][2];
        sum2_2 = feature_map_padding_1[3][3];
        sum2_3 = feature_map_padding_1[3][4];

        sum3_1 = feature_map_padding_1[4][2];
        sum3_2 = feature_map_padding_1[4][3];
        sum3_3 = feature_map_padding_1[4][4];
    end

    if(global_cnt == 232)
    begin
        sum1_1 = feature_map_padding_1[2][3];
        sum1_2 = feature_map_padding_1[2][4];
        sum1_3 = feature_map_padding_1[2][5];

        sum2_1 = feature_map_padding_1[3][3];
        sum2_2 = feature_map_padding_1[3][4];
        sum2_3 = feature_map_padding_1[3][5];

        sum3_1 = feature_map_padding_1[4][3];
        sum3_2 = feature_map_padding_1[4][4];
        sum3_3 = feature_map_padding_1[4][5];
    end

    if(global_cnt == 233)
    begin
        sum1_1 = feature_map_padding_1[3][0];
        sum1_2 = feature_map_padding_1[3][1];
        sum1_3 = feature_map_padding_1[3][2];

        sum2_1 = feature_map_padding_1[4][0];
        sum2_2 = feature_map_padding_1[4][1];
        sum2_3 = feature_map_padding_1[4][2];

        sum3_1 = feature_map_padding_1[5][0];
        sum3_2 = feature_map_padding_1[5][1];
        sum3_3 = feature_map_padding_1[5][2];
    end

    if(global_cnt == 234)
    begin
        sum1_1 = feature_map_padding_1[3][1];
        sum1_2 = feature_map_padding_1[3][2];
        sum1_3 = feature_map_padding_1[3][3];

        sum2_1 = feature_map_padding_1[4][1];
        sum2_2 = feature_map_padding_1[4][2];
        sum2_3 = feature_map_padding_1[4][3];

        sum3_1 = feature_map_padding_1[5][1];
        sum3_2 = feature_map_padding_1[5][2];
        sum3_3 = feature_map_padding_1[5][3];
    end

    if(global_cnt == 235)
    begin
        sum1_1 = feature_map_padding_1[3][2];
        sum1_2 = feature_map_padding_1[3][3];
        sum1_3 = feature_map_padding_1[3][4];

        sum2_1 = feature_map_padding_1[4][2];
        sum2_2 = feature_map_padding_1[4][3];
        sum2_3 = feature_map_padding_1[4][4];

        sum3_1 = feature_map_padding_1[5][2];
        sum3_2 = feature_map_padding_1[5][3];
        sum3_3 = feature_map_padding_1[5][4];
    end

    if(global_cnt == 236)
    begin
        sum1_1 = feature_map_padding_1[3][3];
        sum1_2 = feature_map_padding_1[3][4];
        sum1_3 = feature_map_padding_1[3][5];

        sum2_1 = feature_map_padding_1[4][3];
        sum2_2 = feature_map_padding_1[4][4];
        sum2_3 = feature_map_padding_1[4][5];

        sum3_1 = feature_map_padding_1[5][3];
        sum3_2 = feature_map_padding_1[5][4];
        sum3_3 = feature_map_padding_1[5][5];
    end



end

//---------------------------------------------------------------------
//   COMBINATIONAL
//---------------------------------------------------------------------




assign constant_1 = 32'b0011_1111_1000_0000_0000_0000_0000_0000;

always @ (*)
begin
    a_div1 = 0;
    a_div2 = 0;
    a_div3 = 0;
    a_div4 = 0;

    b_div1 = 0;
    b_div2 = 0;
    b_div3 = 0;
    b_div4 = 0;

    if(global_cnt == 273)
    begin
        a_div1 = feature_map[0][0];
        a_div2 = feature_map[0][1];
        a_div3 = feature_map[0][2];
        a_div4 = feature_map[0][3];

        b_div1 = feature_map[3][0];
        b_div2 = feature_map[3][0];
        b_div3 = feature_map[3][0];
        b_div4 = feature_map[3][0];
    end

    else if(global_cnt == 274)
    begin
        a_div1 = feature_map[1][0];
        a_div2 = feature_map[1][1];
        a_div3 = feature_map[1][2];
        a_div4 = feature_map[1][3];

        b_div1 = feature_map[3][1];
        b_div2 = feature_map[3][1];
        b_div3 = feature_map[3][1];
        b_div4 = feature_map[3][1];
    end

    else if(global_cnt == 278 && input_opt < 2)
    begin
        a_div1 = constant_1;
        a_div2 = constant_1;
        a_div3 = constant_1;
        a_div4 = constant_1;
        
        b_div1 = pooling_map[0][0][0];
        b_div2 = pooling_map[0][0][1];
        b_div3 = pooling_map[0][1][0];
        b_div4 = pooling_map[0][1][1];
    end

    else if(global_cnt == 281 && input_opt < 2)
    begin
        a_div1 = constant_1;
        a_div2 = constant_1;
        a_div3 = constant_1;
        a_div4 = constant_1;

        b_div1 = pooling_map[1][0][0];
        b_div2 = pooling_map[1][0][1];
        b_div3 = pooling_map[1][1][0];
        b_div4 = pooling_map[1][1][1];             
    end

    else if (global_cnt == 279 && input_opt >= 2)
    begin
        a_div1 = input_img[4];
        a_div2 = input_img[5];
        a_div3 = input_img[6];
        a_div4 = input_img[7]; 

        b_div1 = input_img[0];   
        b_div2 = input_img[1]; 
        b_div3 = input_img[2]; 
        b_div4 = input_img[3];    
    end

    else if(global_cnt == 281 && input_opt >=2)
    begin
        a_div1 = input_img[12];
        a_div2 = input_img[13];
        a_div3 = input_img[14];
        a_div4 = input_img[15]; 

        b_div1 = input_img[8];   
        b_div2 = input_img[9]; 
        b_div3 = input_img[10]; 
        b_div4 = input_img[11];            
    end

end

// exp
always @ (*)
begin
    exp_in1 = 0;
    exp_in2 = 0;
    exp_in3 = 0;
    exp_in4 = 0;
    if(global_cnt == 274)
    begin
        exp_in1 = feature_map[0][0];
        exp_in2 = feature_map[0][1];
        exp_in3 = feature_map[0][2];
        exp_in4 = feature_map[0][3];
    end
    else if(global_cnt == 275)
    begin
        exp_in1 = {~(feature_map[0][0][31]),feature_map[0][0][30:0]};
        exp_in2 = {~(feature_map[0][1][31]),feature_map[0][1][30:0]};
        exp_in3 = {~(feature_map[0][2][31]),feature_map[0][2][30:0]};
        exp_in4 = {~(feature_map[0][3][31]),feature_map[0][3][30:0]};
    end
    else if(global_cnt == 276)
    begin
        exp_in1 = feature_map[1][0];
        exp_in2 = feature_map[1][1];
        exp_in3 = feature_map[1][2];
        exp_in4 = feature_map[1][3];
    end

    else if(global_cnt == 277)
    begin
        exp_in1 = {~(feature_map[1][0][31]),feature_map[1][0][30:0]};
        exp_in2 = {~(feature_map[1][1][31]),feature_map[1][1][30:0]};
        exp_in3 = {~(feature_map[1][2][31]),feature_map[1][2][30:0]};
        exp_in4 = {~(feature_map[1][3][31]),feature_map[1][3][30:0]};
    end
end

// add_in1_1 && add_in2_1 && add_in3_1 && add_in4_1
always @ (*) 
begin
    add_in1_1 = 0;
    add_in2_1 = 0;
    add_in3_1 = 0;
    add_in4_1 = 0;

    if(global_cnt > 3 && global_cnt<220)
    begin
        add_in1_1 = mac1_out;
        add_in2_1 = mac2_out;
        add_in3_1 = mac3_out;
        add_in4_1 = mac4_out;
    end

    else if(global_cnt == 268)
    begin
        add_in1_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
        add_in2_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
        add_in3_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
        add_in4_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
    end

    else if(global_cnt == 270)
    begin
        add_in1_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
        add_in2_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
        add_in3_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
        add_in4_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
    end
    else if(global_cnt == 271)
    begin
        add_in1_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
        add_in2_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
    end

    else if (global_cnt == 277) // sigmoid = 1 + e^-z, tanh = e^z + e^-z 
    begin
        add_in1_1 = feature_map[3][0];
        add_in2_1 = feature_map[3][1];
        add_in3_1 = feature_map[3][2];
        add_in4_1 = feature_map[3][3];
    end

    else if (global_cnt == 278 && input_opt >= 2)
    begin
        add_in1_1 = {~(feature_map[3][0][31]),feature_map[3][0][30:0]};
        add_in2_1 = {~(feature_map[3][1][31]),feature_map[3][1][30:0]};
        add_in3_1 = {~(feature_map[3][2][31]),feature_map[3][2][30:0]};
        add_in4_1 = {~(feature_map[3][3][31]),feature_map[3][3][30:0]};
    end

    else if (global_cnt == 279) // sigmoid = 1 + e^-z, tanh = e^z + e^-z  
    begin
        add_in1_1 = feature_map[1][0];
        add_in2_1 = feature_map[1][1];
        add_in3_1 = feature_map[1][2];
        add_in4_1 = feature_map[1][3];
    end

    else if (global_cnt == 280 && input_opt >= 2)
    begin
        add_in1_1 = {~(feature_map[1][0][31]),feature_map[1][0][30:0]};
        add_in2_1 = {~(feature_map[1][1][31]),feature_map[1][1][30:0]};
        add_in3_1 = {~(feature_map[1][2][31]),feature_map[1][2][30:0]};
        add_in4_1 = {~(feature_map[1][3][31]),feature_map[1][3][30:0]};
    end

    else if (global_cnt == 283)
    begin
        add_in1_1 = {~(pooling_map[1][0][0][31]),pooling_map[1][0][0][30:0]};
        add_in2_1 = {~(pooling_map[1][0][1][31]),pooling_map[1][0][1][30:0]};
        add_in3_1 = {~(pooling_map[1][1][0][31]),pooling_map[1][1][0][30:0]};
        add_in4_1 = {~(pooling_map[1][1][1][31]),pooling_map[1][1][1][30:0]};
    end

    else if(global_cnt == 285)
    begin
        add_in1_1 = input_img[2];
        add_in2_1 = input_img[3];
    end

    else if(global_cnt == 287)
    begin
        add_in1_1 = input_img[5];
    end

end

wire clk_18;
wire sleep_18;
assign sleep_18 = !(global_cnt == 134 || global_cnt == 136 || global_cnt == 140 || global_cnt == 142 ||
(global_cnt == 277 && input_opt < 2) || (global_cnt == 278 && input_opt < 2) || (global_cnt == 279 && input_opt >= 2) ||
(out_valid == 1'b1));
GATED_OR GATED_18 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_18), .RST_N(rst_n), .CLOCK_GATED(clk_18));
// pooling map
always @ (posedge clk_18 or negedge rst_n)
begin
    if(!rst_n) begin
            for(j=0;j<2;j=j+1) begin
                for(l=0;l<2;l=l+1) begin
                    pooling_map[0][j][l] <= 0;
                end
            end
    end

    else
    begin
        if(global_cnt == 134) pooling_map[0][0][0] <= cmp_1_reg;
        else if(global_cnt == 136) pooling_map[0][0][1] <= cmp_2_reg;
        else if(global_cnt == 140) pooling_map[0][1][0] <= cmp_1_reg;
        else if(global_cnt == 142) pooling_map[0][1][1] <= cmp_2_reg;
        else if(global_cnt == 277 && input_opt < 2)
        begin
            pooling_map[0][0][0] <= add_out1;
            pooling_map[0][0][1] <= add_out2;
            pooling_map[0][1][0] <= add_out3;
            pooling_map[0][1][1] <= add_out4;
        end
        else if(global_cnt == 278 && input_opt < 2)
        begin
            pooling_map[0][0][0] <= div1_out;
            pooling_map[0][0][1] <= div2_out;
            pooling_map[0][1][0] <= div3_out;
            pooling_map[0][1][1] <= div4_out;
        end

        else if(global_cnt == 279 && input_opt >= 2)
        begin
            pooling_map[0][0][0] <= div1_out;
            pooling_map[0][0][1] <= div2_out;
            pooling_map[0][1][0] <= div3_out;
            pooling_map[0][1][1] <= div4_out;            
        end


        else if(out_valid == 1'b1)
        begin
            for(j=0;j<2;j=j+1) begin
                for(l=0;l<2;l=l+1) begin
                    pooling_map[0][j][l] <= 0;
                end
            end
        end
    end
end


wire clk_19;
wire sleep_19;
assign sleep_19 = !(global_cnt == 242 || global_cnt == 244 || global_cnt == 248 || global_cnt == 250 ||
(global_cnt == 279 && input_opt < 2) || (global_cnt == 281 && input_opt < 2) || (global_cnt == 281 && input_opt >= 2) ||
(out_valid == 1'b1));
GATED_OR GATED_19 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_19), .RST_N(rst_n), .CLOCK_GATED(clk_19));
// pooling map
always @ (posedge clk_19 or negedge rst_n)
begin
    if(!rst_n) begin
            for(j=0;j<2;j=j+1) begin
                for(l=0;l<2;l=l+1) begin
                    pooling_map[1][j][l] <= 0;
                end
            end
    end

    else
    begin
        if(global_cnt == 242) pooling_map[1][0][0] <= cmp_1_reg;
        else if(global_cnt == 244) pooling_map[1][0][1] <= cmp_2_reg;
        else if(global_cnt == 248) pooling_map[1][1][0] <= cmp_1_reg;
        else if(global_cnt == 250) pooling_map[1][1][1] <= cmp_2_reg;

        else if(global_cnt == 279 && input_opt < 2)
        begin
            pooling_map[1][0][0] <= add_out1;
            pooling_map[1][0][1] <= add_out2;
            pooling_map[1][1][0] <= add_out3;
            pooling_map[1][1][1] <= add_out4;
        end

        else if(global_cnt == 281 && input_opt < 2)
        begin
            pooling_map[1][0][0] <= div1_out;
            pooling_map[1][0][1] <= div2_out;
            pooling_map[1][1][0] <= div3_out;
            pooling_map[1][1][1] <= div4_out;
        end


        else if(global_cnt == 281 && input_opt >= 2)
        begin
            pooling_map[1][0][0] <= div1_out;
            pooling_map[1][0][1] <= div2_out;
            pooling_map[1][1][0] <= div3_out;
            pooling_map[1][1][1] <= div4_out;            
        end

        else if(out_valid == 1'b1)
        begin

            for(j=0;j<2;j=j+1) begin
                for(l=0;l<2;l=l+1) begin
                    pooling_map[1][j][l] <= 0;
                end
            end
        end
    end
end

wire clk_20;
wire sleep_20;
assign sleep_20 = !(global_cnt == 130 || global_cnt == 132 || global_cnt == 133 || global_cnt == 136 ||
global_cnt == 138 || global_cnt == 139 || global_cnt == 238 || global_cnt == 240 ||
global_cnt == 241 || global_cnt == 244 || global_cnt == 246 || global_cnt == 247 ||
global_cnt == 265 || global_cnt == 267);
GATED_OR GATED_20 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_20), .RST_N(rst_n), .CLOCK_GATED(clk_20));
// cmp_1_reg
always @ (posedge clk_20 or negedge rst_n)
begin
    if(!rst_n) cmp_1_reg <= 0;
    else
    begin
        if(global_cnt == 130) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 132) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 133) cmp_1_reg <= cmp_z0;

        else if(global_cnt == 136) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 138) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 139) cmp_1_reg <= cmp_z0;

        else if(global_cnt == 238) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 240) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 241) cmp_1_reg <= cmp_z0;

        else if(global_cnt == 244) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 246) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 247) cmp_1_reg <= cmp_z0;

        else if (global_cnt == 265) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 267) cmp_1_reg <= cmp_z0;

    end
end

wire clk_21;
wire sleep_21;
assign sleep_21 = !(global_cnt == 131 || global_cnt == 134 || global_cnt == 135 || global_cnt == 137 ||
global_cnt == 140 || global_cnt == 141 || global_cnt == 239 || global_cnt == 242 ||
global_cnt == 243 || global_cnt == 245 || global_cnt == 248 || global_cnt == 249 ||
global_cnt == 265 || global_cnt == 267);
GATED_OR GATED_21 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_21), .RST_N(rst_n), .CLOCK_GATED(clk_21));
// cmp_2_reg
always @ (posedge clk_21 or negedge rst_n)
begin
    if(!rst_n) cmp_2_reg <= 0;
    else
    begin
        if(global_cnt == 131) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 134) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 135) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 137) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 140) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 141) cmp_2_reg <= cmp_z0;

        else if (global_cnt == 239) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 242) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 243) cmp_2_reg <= cmp_z0;

        else if (global_cnt == 245) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 248) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 249) cmp_2_reg <= cmp_z0;

        else if (global_cnt == 265) cmp_2_reg <= cmp_z1;
        else if (global_cnt == 267) cmp_2_reg <= cmp_z1;
    end
end


wire clk_22;
wire sleep_22;
assign sleep_22 = !(global_cnt == 265 || global_cnt == 267);
GATED_OR GATED_22 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_22), .RST_N(rst_n), .CLOCK_GATED(clk_22));
// cmp_3_reg
always @ (posedge clk_22 or negedge rst_n)
begin
    if(!rst_n) cmp_3_reg <= 0;
    else
    begin
        if(global_cnt == 265) cmp_3_reg <= cmp_z3;
        else if(global_cnt == 267) cmp_3_reg <= cmp_z3;
    end
end

wire clk_23;
wire sleep_23;
assign sleep_23 = !(global_cnt == 265 || global_cnt == 267);
GATED_OR GATED_23 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_23), .RST_N(rst_n), .CLOCK_GATED(clk_23));
// cmp_4_reg
always @ (posedge clk_23 or negedge rst_n)
begin
    if(!rst_n) cmp_4_reg <= 0;
    else
    begin
        if(global_cnt == 265) cmp_4_reg <= cmp_z4;
        else if(global_cnt == 267) cmp_4_reg <= cmp_z4;
    end
end
//comp_3
always @ (*)
begin
    comp_3 = 0;
    if(global_cnt == 265) comp_3 = feature_map[0][0];
    else if(global_cnt == 266) comp_3 = cmp_3_reg;
    else if(global_cnt == 267) comp_3 = feature_map[1][0];
    else if(global_cnt == 268) comp_3 = cmp_3_reg;
end

//comp_4
always @ (*)
begin
    comp_4 = 0;
    if(global_cnt == 265) comp_4 = feature_map[0][1];
    else if(global_cnt == 266) comp_4 = cmp_1_reg;
    if(global_cnt == 267) comp_4 = feature_map[1][1];
    else if(global_cnt == 268) comp_4 = cmp_1_reg;

end

// comp_a
always @ (*)
begin
    comp_a = 0;
    if(global_cnt == 130)
    begin
        comp_a = feature_map_sum_0[0][0];
    end

    else if(global_cnt == 131)
    begin
        comp_a = feature_map_sum_0[0][2];
    end

    else if (global_cnt == 132)
    begin
        comp_a = cmp_1_reg; 
    end

    else if(global_cnt == 133)
    begin
        comp_a = cmp_1_reg;
    end

    else if (global_cnt == 134) comp_a = cmp_2_reg;
    else if (global_cnt == 135) comp_a = cmp_2_reg;  

    else if (global_cnt == 136) comp_a = feature_map_sum_0[2][0]; 
    else if (global_cnt == 137) comp_a = feature_map_sum_0[2][2];  
    else if (global_cnt == 138) comp_a = cmp_1_reg; 
    else if (global_cnt == 139) comp_a = cmp_1_reg;     
    else if (global_cnt == 140) comp_a = cmp_2_reg; 
    else if (global_cnt == 141) comp_a = cmp_2_reg;    

    else if (global_cnt == 238) comp_a = feature_map_sum_1[0][0]; 
    else if (global_cnt == 239) comp_a = feature_map_sum_1[0][2];  
    else if (global_cnt == 240) comp_a = cmp_1_reg; 
    else if (global_cnt == 241) comp_a = cmp_1_reg;     
    else if (global_cnt == 242) comp_a = cmp_2_reg; 
    else if (global_cnt == 243) comp_a = cmp_2_reg;

    else if (global_cnt == 244) comp_a = feature_map_sum_1[2][0]; 
    else if (global_cnt == 245) comp_a = feature_map_sum_1[2][2];  
    else if (global_cnt == 246) comp_a = cmp_1_reg; 
    else if (global_cnt == 247) comp_a = cmp_1_reg;     
    else if (global_cnt == 248) comp_a = cmp_2_reg; 
    else if (global_cnt == 249) comp_a = cmp_2_reg;  

    else if (global_cnt == 265) comp_a = feature_map[0][2];  
    else if (global_cnt == 266) comp_a = cmp_4_reg;
    else if (global_cnt == 267) comp_a = feature_map[1][2]; 
    else if (global_cnt == 268) comp_a = cmp_4_reg;


end

// comp_b
always @ (*)
begin
    comp_b = 0;
    if(global_cnt == 130)
    begin
        comp_b = feature_map_sum_0[0][1];
    end
    else if(global_cnt == 131)
    begin
        comp_b = feature_map_sum_0[0][3];
    end

    else if (global_cnt == 132)
    begin
        comp_b = feature_map_sum_0[1][0];
    end

    else if (global_cnt == 133)
    begin
        comp_b = feature_map_sum_0[1][1];
    end
    else if (global_cnt == 134) comp_b = feature_map_sum_0[1][2];
    else if (global_cnt == 135) comp_b = feature_map_sum_0[1][3];

    else if (global_cnt == 136) comp_b = feature_map_sum_0[2][1];
    else if (global_cnt == 137) comp_b = feature_map_sum_0[2][3];
    else if (global_cnt == 138) comp_b = feature_map_sum_0[3][0];
    else if (global_cnt == 139) comp_b = feature_map_sum_0[3][1];
    else if (global_cnt == 140) comp_b = feature_map_sum_0[3][2];
    else if (global_cnt == 141) comp_b = feature_map_sum_0[3][3];

    else if (global_cnt == 238) comp_b = feature_map_sum_1[0][1];
    else if (global_cnt == 239) comp_b = feature_map_sum_1[0][3];
    else if (global_cnt == 240) comp_b = feature_map_sum_1[1][0];
    else if (global_cnt == 241) comp_b = feature_map_sum_1[1][1];
    else if (global_cnt == 242) comp_b = feature_map_sum_1[1][2];
    else if (global_cnt == 243) comp_b = feature_map_sum_1[1][3];

    else if (global_cnt == 244) comp_b = feature_map_sum_1[2][1];
    else if (global_cnt == 245) comp_b = feature_map_sum_1[2][3];
    else if (global_cnt == 246) comp_b = feature_map_sum_1[3][0];
    else if (global_cnt == 247) comp_b = feature_map_sum_1[3][1];
    else if (global_cnt == 248) comp_b = feature_map_sum_1[3][2];
    else if (global_cnt == 249) comp_b = feature_map_sum_1[3][3];

    else if (global_cnt == 265) comp_b = feature_map[0][3];
    else if (global_cnt == 266) comp_b = cmp_2_reg;
    else if (global_cnt == 267) comp_b = feature_map[1][3];
    else if (global_cnt == 268) comp_b = cmp_2_reg;
end

// kernel select
generate
    for(i=0;i<3;i=i+1)
    begin
        for(h=0;h<3;h=h+1)
        begin
            always @ (*)begin
            if(conv_6_cnt == 0 || conv_6_cnt == 3) kernel_select[i][h] = kerenl[0][i][h];         
            else if (conv_6_cnt == 1 || conv_6_cnt == 4) kernel_select[i][h] = kerenl[1][i][h];
            else kernel_select[i][h] = kerenl[2][i][h];        
            end
        end
    end
endgenerate

// kernel
always @ (*)
begin
    for(k=0;k<3;k=k+1)
    begin
        for(l=0; l<3;l=l+1)
        begin
            for(j=0; j<3;j=j+1)
            begin
                kerenl[k][l][j] = input_kernel[9*k + 3*l + j];
            end
        end
    end
end
//padding
always @ (*) 
begin
    for(k=0;k<6;k=k+1)
    begin
        for(l=1;l<5;l=l+1)
        begin
            for(j=1;j<5;j=j+1)
            begin
                image_padding[k][l][j] = input_img[16*k + 4*l + j -5];
            end
        end
    end
end

generate
    for(i=0;i<6;i=i+1)begin
    always @ (*) 
    begin
        if(input_opt == 2'd0 || input_opt == 2'd2)
        begin  
            image_padding[i][0][0] = input_img[i*16];
            image_padding[i][0][1] = input_img[i*16];           
            image_padding[i][0][2] = input_img[i*16+1];  
            image_padding[i][0][3] = input_img[i*16+2];   
            image_padding[i][0][4] = input_img[i*16+3];
            image_padding[i][0][5] = input_img[i*16+3];
            image_padding[i][1][0] = input_img[i*16];
            image_padding[i][1][5] = input_img[i*16+3];
            image_padding[i][2][0] = input_img[i*16+4];
            image_padding[i][2][5] = input_img[i*16+7];
            image_padding[i][3][0] = input_img[i*16+8];
            image_padding[i][3][5] = input_img[i*16+11];
            image_padding[i][4][0] = input_img[i*16+12];
            image_padding[i][4][5] = input_img[i*16+15];
            image_padding[i][5][0] = input_img[i*16+12];
            image_padding[i][5][1] = input_img[i*16+12];           
            image_padding[i][5][2] = input_img[i*16+13];  
            image_padding[i][5][3] = input_img[i*16+14];   
            image_padding[i][5][4] = input_img[i*16+15];
            image_padding[i][5][5] = input_img[i*16+15];
        end            
    

        else
        begin
            image_padding[i][0][0] = 32'b0;
            image_padding[i][0][1] = 32'b0;           
            image_padding[i][0][2] = 32'b0;  
            image_padding[i][0][3] = 32'b0;   
            image_padding[i][0][4] = 32'b0;
            image_padding[i][0][5] = 32'b0;
            image_padding[i][1][0] = 32'b0;
            image_padding[i][1][5] = 32'b0;
            image_padding[i][2][0] = 32'b0;
            image_padding[i][2][5] = 32'b0;
            image_padding[i][3][0] = 32'b0;
            image_padding[i][3][5] = 32'b0;
            image_padding[i][4][0] = 32'b0;
            image_padding[i][4][5] = 32'b0;
            image_padding[i][5][0] = 32'b0;
            image_padding[i][5][1] = 32'b0;           
            image_padding[i][5][2] = 32'b0;  
            image_padding[i][5][3] = 32'b0;   
            image_padding[i][5][4] = 32'b0;
            image_padding[i][5][5] = 32'b0;
        end
    end
    end
endgenerate
//---------------------------------------------------------------------
//   SEQUANTIAL
//---------------------------------------------------------------------

wire clk_24;
wire sleep_24;
assign sleep_24 = !((conv_4_cnt == 0 && conv_6_cnt == 3 && conv_9_cnt == 6) || (global_cnt>3 && global_cnt < 220 && (conv_9_cnt == 8))||
global_cnt == 261 || global_cnt == 268 || global_cnt == 273 || global_cnt == 276 || out_valid == 1'b1);
GATED_OR GATED_24 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_24), .RST_N(rst_n), .CLOCK_GATED(clk_24));
// feature_map
always @ (posedge clk_24 or negedge rst_n)
begin
    if(!rst_n) 
    begin
            for(l=0;l<4;l=l+1) begin
                feature_map[0][l] <= 0;
            end
    end

    else
    begin
        if(conv_4_cnt == 0 && conv_6_cnt == 3 && conv_9_cnt == 6)
        begin
                for(l=0;l<4;l=l+1) begin
                    feature_map[0][l] <= 0;
                end
        end

        if(global_cnt>3 && global_cnt < 220) 
        begin
            if(conv_9_cnt == 8)
            begin
                case(conv_4_cnt)
                0: 
                begin
                    feature_map[0][0] <= add_out1;
                    feature_map[0][1] <= add_out2;
                    feature_map[0][2] <= add_out3;
                    feature_map[0][3] <= add_out4;
                end
                endcase
            end               
        end
        if(global_cnt == 261) 
        begin
            feature_map[0][0] <= mac1_out;       
            feature_map[0][1] <= mac2_out;
            feature_map[0][2] <= mac3_out;
            feature_map[0][3] <= mac4_out;
        end

        if(global_cnt == 268)
        begin         
            feature_map[0][0] <= add_out1;       
            feature_map[0][1] <= add_out2;
            feature_map[0][2] <= add_out3;
            feature_map[0][3] <= add_out4;
        end

        if(global_cnt == 273)
        begin
            feature_map[0][0] <= div1_out;
            feature_map[0][1] <= div2_out;
            feature_map[0][2] <= div3_out;
            feature_map[0][3] <= div4_out;           
        end

        if(global_cnt == 276)
        begin
            feature_map[0][0] <= exp_out1;// +z2
            feature_map[0][1] <= exp_out2;
            feature_map[0][2] <= exp_out3;
            feature_map[0][3] <= exp_out4;  
        end


        if(out_valid == 1'b1) // zero
        begin
            for(l=0;l<4;l=l+1) begin
                feature_map[0][l] <= 0;
            end
        end

    end
end

wire clk_25;
wire sleep_25;
assign sleep_25 = !((conv_4_cnt == 0 && conv_6_cnt == 3 && conv_9_cnt == 6) || (global_cnt>3 && global_cnt < 220 && (conv_9_cnt == 8))||
global_cnt == 266 || global_cnt == 270 || global_cnt == 274 || global_cnt == 277 || out_valid == 1'b1);
GATED_OR GATED_25 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_25), .RST_N(rst_n), .CLOCK_GATED(clk_25));
always @ (posedge clk_25 or negedge rst_n)
begin
    if(!rst_n) 
    begin

            for(l=0;l<4;l=l+1) begin
                feature_map[1][l] <= 0;
            end
    end

    else
    begin
        if(conv_4_cnt == 0 && conv_6_cnt == 3 && conv_9_cnt == 6)
        begin

                for(l=0;l<4;l=l+1) begin
                    feature_map[1][l] <= 0;
                end
        end

        if(global_cnt>3 && global_cnt < 220) 
        begin
            if(conv_9_cnt == 8)
            begin
                case(conv_4_cnt)

                1: 
                begin
                    feature_map[1][0] <= add_out1;
                    feature_map[1][1] <= add_out2;
                    feature_map[1][2] <= add_out3;
                    feature_map[1][3] <= add_out4;
                end
                endcase
            end               
        end

        if(global_cnt == 266) 
        begin
            feature_map[1][0] <= mac1_out;       
            feature_map[1][1] <= mac2_out;
            feature_map[1][2] <= mac3_out;
            feature_map[1][3] <= mac4_out;
        end

        if(global_cnt == 270)
        begin         
            feature_map[1][0] <= add_out1;       
            feature_map[1][1] <= add_out2;
            feature_map[1][2] <= add_out3;
            feature_map[1][3] <= add_out4;
        end



        if(global_cnt == 274)
        begin
            feature_map[1][0] <= div1_out;
            feature_map[1][1] <= div2_out;
            feature_map[1][2] <= div3_out;
            feature_map[1][3] <= div4_out;       

        end





        if(global_cnt == 277)
        begin
            feature_map[1][0] <= exp_out1;// -z2
            feature_map[1][1] <= exp_out2;
            feature_map[1][2] <= exp_out3;
            feature_map[1][3] <= exp_out4;  
        end

        if(out_valid == 1'b1) // zero
        begin

            for(l=0;l<4;l=l+1) begin
                feature_map[1][l] <= 0;
            end

        end

    end
end

wire clk_26;
wire sleep_26;
assign sleep_26 = !((conv_4_cnt == 0 && conv_6_cnt == 3 && conv_9_cnt == 6) || (global_cnt>3 && global_cnt < 220 && (conv_9_cnt == 8))||
global_cnt == 266 || global_cnt == 268 || global_cnt == 274 || out_valid == 1'b1);
GATED_OR GATED_26 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_26), .RST_N(rst_n), .CLOCK_GATED(clk_26));
always @ (posedge clk_26 or negedge rst_n)
begin
    if(!rst_n) 
    begin

            for(l=0;l<4;l=l+1) begin
                feature_map[2][l] <= 0;
            end

    end

    else
    begin
        if(conv_4_cnt == 0 && conv_6_cnt == 3 && conv_9_cnt == 6)
        begin

                for(l=0;l<4;l=l+1) begin
                    feature_map[2][l] <= 0;
                end

        end

        if(global_cnt>3 && global_cnt < 220) 
        begin
            if(conv_9_cnt == 8)
            begin
                case(conv_4_cnt)
                2: 
                begin
                    feature_map[2][0] <= add_out1;
                    feature_map[2][1] <= add_out2;
                    feature_map[2][2] <= add_out3;
                    feature_map[2][3] <= add_out4;
                end 
                endcase
            end               
        end

        if(global_cnt == 266) 
        begin

            feature_map[2][0] <= cmp_z3;       
            feature_map[2][1] <= cmp_z1;
        end
        if(global_cnt == 268)
        begin
            feature_map[2][2] <= cmp_z3;       
            feature_map[2][3] <= cmp_z1;            
  
        end


        if(global_cnt == 274)
        begin     
            feature_map[2][0] <= exp_out1; // +z1
            feature_map[2][1] <= exp_out2;
            feature_map[2][2] <= exp_out3;
            feature_map[2][3] <= exp_out4;    
        end


        if(out_valid == 1'b1) // zero
        begin

            for(l=0;l<4;l=l+1) begin
                feature_map[2][l] <= 0;
            end
        end

    end
end

wire clk_27;
wire sleep_27;
assign sleep_27 = !((conv_4_cnt == 0 && conv_6_cnt == 3 && conv_9_cnt == 6) || (global_cnt>3 && global_cnt < 220 && (conv_9_cnt == 8))||
global_cnt == 271 || global_cnt == 275 || out_valid == 1'b1);
GATED_OR GATED_27 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_27), .RST_N(rst_n), .CLOCK_GATED(clk_27));

always @ (posedge clk_27 or negedge rst_n)
begin
    if(!rst_n) 
    begin

            for(l=0;l<4;l=l+1) begin
                feature_map[3][l] <= 0;
            end

    end

    else
    begin
        if(conv_4_cnt == 0 && conv_6_cnt == 3 && conv_9_cnt == 6)
        begin

                for(l=0;l<4;l=l+1) begin
                    feature_map[3][l] <= 0;
                end

        end

        if(global_cnt>3 && global_cnt < 220) 
        begin
            if(conv_9_cnt == 8)
            begin
                case(conv_4_cnt)
                3: 
                begin
                    feature_map[3][0] <= add_out1;
                    feature_map[3][1] <= add_out2;
                    feature_map[3][2] <= add_out3;
                    feature_map[3][3] <= add_out4;
                end
                endcase
            end               
        end
        
        if(global_cnt == 271)
        begin         
            feature_map[3][0] <= add_out1;       
            feature_map[3][1] <= add_out2;
        end

        if(global_cnt == 275)
        begin
            feature_map[3][0] <= exp_out1; // -z1
            feature_map[3][1] <= exp_out2;
            feature_map[3][2] <= exp_out3;
            feature_map[3][3] <= exp_out4;  
        end

        if(out_valid == 1'b1) // zero
        begin

            for(l=0;l<4;l=l+1) begin
                feature_map[3][l] <= 0;
            end
        end

    end
end

wire clk_28;
wire sleep_28;
assign sleep_28 = !((global_cnt >3 && global_cnt < 220) || global_cnt == 267|| global_cnt == 269 || global_cnt == 270 ||
(global_cnt == 276 && input_opt < 2) || (global_cnt == 278 && input_opt < 2) ||
(global_cnt == 276 && input_opt >= 2) || (global_cnt == 277 && input_opt >= 2) || 
(global_cnt == 278 && input_opt >= 2) || (global_cnt == 279 && input_opt >= 2) ||
(global_cnt == 282) || (global_cnt == 284) || (global_cnt == 286));
GATED_OR GATED_28 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_28), .RST_N(rst_n), .CLOCK_GATED(clk_28));
// add_in1
always @ (posedge clk_28 or negedge rst_n)
begin
    if(!rst_n) add_in1 <= 0;
    else
    begin
        if(global_cnt >3 && global_cnt < 220)
        begin
            case(conv_4_cnt)
            0: add_in1 <= feature_map[0][0];
            1: add_in1 <= feature_map[1][0];
            2: add_in1 <= feature_map[2][0];
            3: add_in1 <= feature_map[3][0];
            endcase
        end

        else if(global_cnt == 267) add_in1 <= feature_map[0][0]; 
        else if(global_cnt == 269) add_in1 <= feature_map[1][0]; 
        else if(global_cnt == 270) add_in1 <= feature_map[2][0];
        else if(global_cnt == 276 && input_opt < 2) add_in1 <= constant_1; // sigmoid
        else if(global_cnt == 278 && input_opt < 2) add_in1 <= constant_1;

        else if(global_cnt == 276 && input_opt >= 2) add_in1 <= feature_map[2][0]; // tanh
        else if(global_cnt == 277 && input_opt >= 2) add_in1 <= feature_map[2][0];
        else if(global_cnt == 278 && input_opt >= 2) add_in1 <= feature_map[0][0];
        else if(global_cnt == 279 && input_opt >= 2) add_in1 <= feature_map[0][0];
        else if(global_cnt == 282) add_in1 <= pooling_map[0][0][0];
        else if(global_cnt == 284) add_in1 <= input_img[0];
        else if(global_cnt == 286) add_in1 <= input_img[4];
    end
end

wire clk_29;
wire sleep_29;
assign sleep_29 = !((global_cnt >3 && global_cnt < 220) || global_cnt == 267|| global_cnt == 269 || global_cnt == 270 ||
(global_cnt == 276 && input_opt < 2) || (global_cnt == 278 && input_opt < 2) ||
(global_cnt == 276 && input_opt >= 2) || (global_cnt == 277 && input_opt >= 2) || 
(global_cnt == 278 && input_opt >= 2) || (global_cnt == 279 && input_opt >= 2) ||
(global_cnt == 282) || (global_cnt == 284));
GATED_OR GATED_29 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_29), .RST_N(rst_n), .CLOCK_GATED(clk_29));
// add_in2
always @ (posedge clk_29 or negedge rst_n)
begin
    if(!rst_n) add_in2 <= 0;
    else
    begin
        if(global_cnt >3 && global_cnt < 220)
        begin
            case(conv_4_cnt)
            0: add_in2 <= feature_map[0][1];
            1: add_in2 <= feature_map[1][1];
            2: add_in2 <= feature_map[2][1];
            3: add_in2 <= feature_map[3][1];
            endcase
        end
        else if (global_cnt == 267) add_in2 <= feature_map[0][1];
        else if (global_cnt == 269) add_in2 <= feature_map[1][1];
        else if (global_cnt == 270) add_in2 <= feature_map[2][2];
        else if (global_cnt == 276 && input_opt < 2) add_in2 <= constant_1;
        else if (global_cnt == 278 && input_opt < 2) add_in2 <= constant_1;

        else if(global_cnt == 276 && input_opt >= 2) add_in2 <= feature_map[2][1];
        else if(global_cnt == 277 && input_opt >= 2) add_in2 <= feature_map[2][1];
        else if(global_cnt == 278 && input_opt >= 2) add_in2 <= feature_map[0][1];
        else if(global_cnt == 279 && input_opt >= 2) add_in2 <= feature_map[0][1];
        else if(global_cnt == 282) add_in2 <= pooling_map[0][0][1];
        else if(global_cnt == 284) add_in2 <= input_img[1];
    end
end

wire clk_30;
wire sleep_30;
assign sleep_30 = !((global_cnt >3 && global_cnt < 220) || global_cnt == 267|| global_cnt == 269 ||
(global_cnt == 276 && input_opt < 2) || (global_cnt == 278 && input_opt < 2) ||
(global_cnt == 276 && input_opt >= 2) || (global_cnt == 277 && input_opt >= 2) || 
(global_cnt == 278 && input_opt >= 2) || (global_cnt == 279 && input_opt >= 2) ||
(global_cnt == 282) );
GATED_OR GATED_30 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_30), .RST_N(rst_n), .CLOCK_GATED(clk_30));
// add_in3
always @ (posedge clk_30 or negedge rst_n)
begin
    if(!rst_n) add_in3 <= 0;
    else
    begin
        if(global_cnt >3 && global_cnt < 220)
        begin
            case(conv_4_cnt)
            0: add_in3 <= feature_map[0][2];
            1: add_in3 <= feature_map[1][2];
            2: add_in3 <= feature_map[2][2];
            3: add_in3 <= feature_map[3][2];
            endcase
        end
        else if (global_cnt == 267) add_in3 <= feature_map[0][2];
        else if (global_cnt == 269) add_in3 <= feature_map[1][2];
        else if (global_cnt == 276 && input_opt < 2) add_in3 <= constant_1;
        else if (global_cnt == 278 && input_opt < 2) add_in3 <= constant_1;

        else if (global_cnt == 276 && input_opt >= 2) add_in3 <= feature_map[2][2];
        else if (global_cnt == 277 && input_opt >= 2) add_in3 <= feature_map[2][2];
        else if (global_cnt == 278 && input_opt >= 2) add_in3 <= feature_map[0][2];
        else if (global_cnt == 279 && input_opt >= 2) add_in3 <= feature_map[0][2];
        else if(global_cnt == 282) add_in3 <= pooling_map[0][1][0];
    end
end

wire clk_31;
wire sleep_31;
assign sleep_31 = !((global_cnt >3 && global_cnt < 220) || global_cnt == 267|| global_cnt == 269 ||
(global_cnt == 276 && input_opt < 2) || (global_cnt == 278 && input_opt < 2) ||
(global_cnt == 276 && input_opt >= 2) || (global_cnt == 277 && input_opt >= 2) || 
(global_cnt == 278 && input_opt >= 2) || (global_cnt == 279 && input_opt >= 2) ||
(global_cnt == 282));
GATED_OR GATED_31 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_31), .RST_N(rst_n), .CLOCK_GATED(clk_31));
// add_in4
always @ (posedge clk_31 or negedge rst_n)
begin
    if(!rst_n) add_in4 <= 0;
    else
    begin
        if(global_cnt >3 && global_cnt < 220)
        begin
            case(conv_4_cnt)
            0: add_in4 <= feature_map[0][3];
            1: add_in4 <= feature_map[1][3];
            2: add_in4 <= feature_map[2][3];
            3: add_in4 <= feature_map[3][3];
            endcase
        end
        else if (global_cnt == 267) add_in4 <= feature_map[0][3];
        else if (global_cnt == 269) add_in4 <= feature_map[1][3];
        else if (global_cnt == 276 && input_opt < 2) add_in4 <= constant_1;
        else if (global_cnt == 278 && input_opt < 2) add_in4 <= constant_1;

        else if (global_cnt == 276 && input_opt >= 2) add_in4 <= feature_map[2][3];
        else if (global_cnt == 277 && input_opt >= 2) add_in4 <= feature_map[2][3];
        else if (global_cnt == 278 && input_opt >= 2) add_in4 <= feature_map[0][3];
        else if (global_cnt == 279 && input_opt >= 2) add_in4 <= feature_map[0][3];
        else if(global_cnt == 282) add_in4 <= pooling_map[0][1][1];
    end
end


//a_mac1 & b_mac1 & c_mac1
always @ (*)
begin
    a_mac1 = 0;
    if(global_cnt>3 && global_cnt < 220)
    begin
        case(conv_9_cnt)
        0: a_mac1 = image_padding[conv_6_cnt][conv_4_cnt][0];
        1: a_mac1 = image_padding[conv_6_cnt][conv_4_cnt][1];
        2: a_mac1 = image_padding[conv_6_cnt][conv_4_cnt][2];
        3: a_mac1 = image_padding[conv_6_cnt][conv_4_cnt+1][0];
        4: a_mac1 = image_padding[conv_6_cnt][conv_4_cnt+1][1];
        5: a_mac1 = image_padding[conv_6_cnt][conv_4_cnt+1][2];
        6: a_mac1 = image_padding[conv_6_cnt][conv_4_cnt+2][0];
        7: a_mac1 = image_padding[conv_6_cnt][conv_4_cnt+2][1];
        8: a_mac1 = image_padding[conv_6_cnt][conv_4_cnt+2][2];
        endcase     
    end
    else if(global_cnt == 260) a_mac1 = pooling_map[0][0][0];
    else if(global_cnt == 261) a_mac1 = pooling_map[0][0][1];
    else if(global_cnt == 265) a_mac1 = pooling_map[1][0][0];
    else if(global_cnt == 266) a_mac1 = pooling_map[1][0][1];
    else if(global_cnt == 273) a_mac1 = feature_map[0][0];
    else if(global_cnt == 274) a_mac1 = feature_map[1][0];
    else if(global_cnt == 279 && input_opt >=2 ) a_mac1 = input_img[0];
    else if(global_cnt == 281 && input_opt >=2 ) a_mac1 = input_img[8];
end

always @ (*)
begin
    b_mac1 = 0;
    if(global_cnt>3 && global_cnt < 220)
    begin
        case(conv_9_cnt)
            0: b_mac1 = kernel_select[0][0];
            1: b_mac1 = kernel_select[0][1];
            2: b_mac1 = kernel_select[0][2];
            3: b_mac1 = kernel_select[1][0];
            4: b_mac1 = kernel_select[1][1];
            5: b_mac1 = kernel_select[1][2];
            6: b_mac1 = kernel_select[2][0];
            7: b_mac1 = kernel_select[2][1];
            8: b_mac1 = kernel_select[2][2];
        endcase
    end  
    else if(global_cnt == 260) b_mac1 = input_weight[0];
    else if(global_cnt == 261) b_mac1 = input_weight[2];
    else if(global_cnt == 265) b_mac1 = input_weight[0];
    else if(global_cnt == 266) b_mac1 = input_weight[2];
    else if(global_cnt == 273) b_mac1 = feature_map[3][2];
    else if(global_cnt == 274) b_mac1 = feature_map[3][3];
    else if(global_cnt == 279 && input_opt >=2 ) b_mac1 = input_img[4];
    else if(global_cnt == 281 && input_opt >=2 ) b_mac1 = input_img[12];
end
wire clk_32;
wire sleep_32;
assign sleep_32 = !((global_cnt>3 && global_cnt < 220) ||global_cnt == 260 || global_cnt == 261 || global_cnt == 265 || global_cnt == 266);
GATED_OR GATED_32 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_32), .RST_N(rst_n), .CLOCK_GATED(clk_32));
always @ (posedge clk_32 or negedge rst_n)
begin
    if(!rst_n) c_mac1 <= 32'b0;
    else
    begin
        if(global_cnt>3 && global_cnt < 220)
        begin
            if(conv_9_cnt == 8) c_mac1 <= 32'b0;
            else c_mac1 <= mac1_out;
        end 
        if(global_cnt == 260) c_mac1 <= mac1_out;
        if(global_cnt == 261) c_mac1 <= 0;  
        if(global_cnt == 265) c_mac1 <= mac1_out;
        if(global_cnt == 266) c_mac1 <= 0;       
    end
    // else c_mac1 <= 0;
end

// a_mac2 & b_mac2 & c_mac2
always @ (*)
begin
    a_mac2 = 0;
    if(global_cnt>3 && global_cnt < 220)
    begin
        case(conv_9_cnt)
        0: a_mac2 = image_padding[conv_6_cnt][conv_4_cnt][1];
        1: a_mac2 = image_padding[conv_6_cnt][conv_4_cnt][2];
        2: a_mac2 = image_padding[conv_6_cnt][conv_4_cnt][3];
        3: a_mac2 = image_padding[conv_6_cnt][conv_4_cnt+1][1];
        4: a_mac2 = image_padding[conv_6_cnt][conv_4_cnt+1][2];
        5: a_mac2 = image_padding[conv_6_cnt][conv_4_cnt+1][3];
        6: a_mac2 = image_padding[conv_6_cnt][conv_4_cnt+2][1];
        7: a_mac2 = image_padding[conv_6_cnt][conv_4_cnt+2][2];
        8: a_mac2 = image_padding[conv_6_cnt][conv_4_cnt+2][3];
        endcase     
    end
    else if(global_cnt == 260) a_mac2 = pooling_map[0][0][0];
    else if(global_cnt == 261) a_mac2 = pooling_map[0][0][1];
    else if(global_cnt == 265) a_mac2 = pooling_map[1][0][0];
    else if(global_cnt == 266) a_mac2 = pooling_map[1][0][1];
    else if(global_cnt == 273) a_mac2 = feature_map[0][1];
    else if(global_cnt == 274) a_mac2 = feature_map[1][1];
    else if(global_cnt == 279 && input_opt >=2 ) a_mac2 = input_img[1];
    else if(global_cnt == 281 && input_opt >=2 ) a_mac2 = input_img[9];
end
always @ (*)
begin
    b_mac2 = 0;
    if(global_cnt>3 && global_cnt < 220)
    begin
        case(conv_9_cnt)
            0: b_mac2 = kernel_select[0][0];
            1: b_mac2 = kernel_select[0][1];
            2: b_mac2 = kernel_select[0][2];
            3: b_mac2 = kernel_select[1][0];
            4: b_mac2 = kernel_select[1][1];
            5: b_mac2 = kernel_select[1][2];
            6: b_mac2 = kernel_select[2][0];
            7: b_mac2 = kernel_select[2][1];
            8: b_mac2 = kernel_select[2][2];
        endcase
    end    
    else if(global_cnt == 260) b_mac2 = input_weight[1];
    else if(global_cnt == 261) b_mac2 = input_weight[3];
    else if(global_cnt == 265) b_mac2 = input_weight[1];
    else if(global_cnt == 266) b_mac2 = input_weight[3];
    else if(global_cnt == 273) b_mac2 = feature_map[3][2];
    else if(global_cnt == 274) b_mac2 = feature_map[3][3];
    else if(global_cnt == 279 && input_opt >=2 ) b_mac2 = input_img[5];
    else if(global_cnt == 281 && input_opt >=2 ) b_mac2 = input_img[13];
end

wire clk_33;
wire sleep_33;
assign sleep_33 = !((global_cnt>3 && global_cnt < 220) ||global_cnt == 260 || global_cnt == 261 || global_cnt == 265 || global_cnt == 266);
GATED_OR GATED_33 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_33), .RST_N(rst_n), .CLOCK_GATED(clk_33));
always @ (posedge clk_33 or negedge rst_n)
begin
    if(!rst_n) c_mac2 <= 32'b0;
    else
    begin
        if(global_cnt>3 && global_cnt < 220)
        begin
            if(conv_9_cnt == 8) c_mac2 <= 32'b0;
            else c_mac2 <= mac2_out;
        end      
        if(global_cnt == 260) c_mac2 <= mac2_out; 
        if(global_cnt == 261) c_mac2 <= 0;   
        if(global_cnt == 265) c_mac2 <= mac2_out; 
        if(global_cnt == 266) c_mac2 <= 0; 
        // else  c_mac2 <= 0;
    end
end

// a_mac3 & b_mac3 & c_mac3
always @ (*)
begin
    a_mac3 = 0;
    if(global_cnt>3 && global_cnt < 220)
    begin
        case(conv_9_cnt)
        0: a_mac3 = image_padding[conv_6_cnt][conv_4_cnt][2];
        1: a_mac3 = image_padding[conv_6_cnt][conv_4_cnt][3];
        2: a_mac3 = image_padding[conv_6_cnt][conv_4_cnt][4];
        3: a_mac3 = image_padding[conv_6_cnt][conv_4_cnt+1][2];
        4: a_mac3 = image_padding[conv_6_cnt][conv_4_cnt+1][3];
        5: a_mac3 = image_padding[conv_6_cnt][conv_4_cnt+1][4];
        6: a_mac3 = image_padding[conv_6_cnt][conv_4_cnt+2][2];
        7: a_mac3 = image_padding[conv_6_cnt][conv_4_cnt+2][3];
        8: a_mac3 = image_padding[conv_6_cnt][conv_4_cnt+2][4];
        endcase     
    end
    else if(global_cnt == 260) a_mac3 = pooling_map[0][1][0];
    else if(global_cnt == 261) a_mac3 = pooling_map[0][1][1];
    else if(global_cnt == 265) a_mac3 = pooling_map[1][1][0];
    else if(global_cnt == 266) a_mac3 = pooling_map[1][1][1];
    else if(global_cnt == 273) a_mac3 = feature_map[0][2];
    else if(global_cnt == 274) a_mac3 = feature_map[1][2];
    else if(global_cnt == 279 && input_opt >=2 ) a_mac3 = input_img[2];
    else if(global_cnt == 281 && input_opt >=2 ) a_mac3 = input_img[10];
end
always @ (*)
begin
    b_mac3 = 0;
    if(global_cnt>3 && global_cnt < 220)
    begin
        case(conv_9_cnt)
            0: b_mac3 = kernel_select[0][0];
            1: b_mac3 = kernel_select[0][1];
            2: b_mac3 = kernel_select[0][2];
            3: b_mac3 = kernel_select[1][0];
            4: b_mac3 = kernel_select[1][1];
            5: b_mac3 = kernel_select[1][2];
            6: b_mac3 = kernel_select[2][0];
            7: b_mac3 = kernel_select[2][1];
            8: b_mac3 = kernel_select[2][2];
        endcase
    end  
    else if(global_cnt == 260) b_mac3 = input_weight[0];
    else if(global_cnt == 261) b_mac3 = input_weight[2]; 
    else if(global_cnt == 265) b_mac3 = input_weight[0];
    else if(global_cnt == 266) b_mac3 = input_weight[2]; 
    else if(global_cnt == 273) b_mac3 = feature_map[3][2];
    else if(global_cnt == 274) b_mac3 = feature_map[3][3];
    else if(global_cnt == 279 && input_opt >=2 ) b_mac3 = input_img[6];
    else if(global_cnt == 281 && input_opt >=2 ) b_mac3 = input_img[14];
end

wire clk_34;
wire sleep_34;
assign sleep_34 = !((global_cnt>3 && global_cnt < 220) ||global_cnt == 260 || global_cnt == 261 || global_cnt == 265 || global_cnt == 266);
GATED_OR GATED_34 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_34), .RST_N(rst_n), .CLOCK_GATED(clk_34));
always @ (posedge clk_34 or negedge rst_n)
begin
    if(!rst_n) c_mac3 <= 32'b0;
    else
    begin
        if(global_cnt>3 && global_cnt < 220)
        begin
            if(conv_9_cnt == 8) c_mac3 <= 32'b0;
            else c_mac3 <= mac3_out;
        end 
        if(global_cnt == 260) c_mac3 <= mac3_out;   
        if(global_cnt == 261) c_mac3 <= 0;        
        if(global_cnt == 265) c_mac3 <= mac3_out; 
        if(global_cnt == 266) c_mac3 <= 0; 
        // else c_mac3 <= 0;  
    end
end

// a_mac4 & b_mac4 & c_mac4
always @ (*)
begin
    a_mac4 = 0;
    if(global_cnt>3 && global_cnt < 220)
    begin
        case(conv_9_cnt)
        0: a_mac4 = image_padding[conv_6_cnt][conv_4_cnt][3];
        1: a_mac4 = image_padding[conv_6_cnt][conv_4_cnt][4];
        2: a_mac4 = image_padding[conv_6_cnt][conv_4_cnt][5];
        3: a_mac4 = image_padding[conv_6_cnt][conv_4_cnt+1][3];
        4: a_mac4 = image_padding[conv_6_cnt][conv_4_cnt+1][4];
        5: a_mac4 = image_padding[conv_6_cnt][conv_4_cnt+1][5];
        6: a_mac4 = image_padding[conv_6_cnt][conv_4_cnt+2][3];
        7: a_mac4 = image_padding[conv_6_cnt][conv_4_cnt+2][4];
        8: a_mac4 = image_padding[conv_6_cnt][conv_4_cnt+2][5];
        endcase     
    end
    else if(global_cnt == 260) a_mac4 = pooling_map[0][1][0];
    else if(global_cnt == 261) a_mac4 = pooling_map[0][1][1];
    else if(global_cnt == 265) a_mac4 = pooling_map[1][1][0];
    else if(global_cnt == 266) a_mac4 = pooling_map[1][1][1];
    else if (global_cnt == 273) a_mac4 = feature_map[0][3];
    else if (global_cnt == 274) a_mac4 = feature_map[1][3];
    else if(global_cnt == 279 && input_opt >=2 ) a_mac4 = input_img[3];
    else if(global_cnt == 281 && input_opt >=2 ) a_mac4 = input_img[11];
end
always @ (*)
begin
    b_mac4 = 0;
    if(global_cnt>3 && global_cnt < 220)
    begin
        case(conv_9_cnt)
            0: b_mac4 = kernel_select[0][0];
            1: b_mac4 = kernel_select[0][1];
            2: b_mac4 = kernel_select[0][2];
            3: b_mac4 = kernel_select[1][0];
            4: b_mac4 = kernel_select[1][1];
            5: b_mac4 = kernel_select[1][2];
            6: b_mac4 = kernel_select[2][0];
            7: b_mac4 = kernel_select[2][1];
            8: b_mac4 = kernel_select[2][2];
        endcase
    end  
    else if(global_cnt == 260) b_mac4 = input_weight[1];
    else if(global_cnt == 261) b_mac4 = input_weight[3]; 
    else if(global_cnt == 265) b_mac4 = input_weight[1];
    else if(global_cnt == 266) b_mac4 = input_weight[3]; 
    else if(global_cnt == 273) b_mac4 = feature_map[3][2];
    else if(global_cnt == 274) b_mac4 = feature_map[3][3];
    else if(global_cnt == 279 && input_opt >=2 ) b_mac4 = input_img[7];
    else if(global_cnt == 281 && input_opt >=2 ) b_mac4 = input_img[15];
end

wire clk_35;
wire sleep_35;
assign sleep_35 = !((global_cnt>3 && global_cnt < 220) ||global_cnt == 260 || global_cnt == 261 || global_cnt == 265 || global_cnt == 266);
GATED_OR GATED_35 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_35), .RST_N(rst_n), .CLOCK_GATED(clk_35));
always @ (posedge clk_35 or negedge rst_n)
begin
    if(!rst_n) c_mac4 <= 32'b0;
    else
    begin
        if(global_cnt>3 && global_cnt < 220)
        begin
            if(conv_9_cnt == 8) c_mac4 <= 32'b0;
            else c_mac4 <= mac4_out;
        end    
        if(global_cnt == 260) c_mac4 <= mac4_out;  
        if(global_cnt == 261) c_mac4 <= 0;   
        if(global_cnt == 265) c_mac4 <= mac4_out;  
        if(global_cnt == 266) c_mac4 <= 0;  
        // else c_mac4 <= 0;   
    end
end

wire clk_36;
wire sleep_36;
assign sleep_36 = !((conv_6_cnt == 6) || (conv_4_cnt == 3 && conv_9_cnt == 8));
GATED_OR GATED_36 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_36), .RST_N(rst_n), .CLOCK_GATED(clk_36));
//conv_6_cnt
always @ (posedge clk_36 or negedge rst_n)
begin
    if(!rst_n) conv_6_cnt <= 0;
    else 
    begin
        if(conv_6_cnt == 6) conv_6_cnt <= 0;
        else if (conv_4_cnt == 3 && conv_9_cnt == 8) conv_6_cnt <= conv_6_cnt + 1;
        else conv_6_cnt <= conv_6_cnt;
    end
end

wire clk_37;
wire sleep_37;
assign sleep_37 = !((conv_4_cnt == 3 && conv_9_cnt == 8) || (conv_9_cnt == 8));
GATED_OR GATED_37 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_37), .RST_N(rst_n), .CLOCK_GATED(clk_37));
//conv_4_cnt
always @(posedge clk_37 or negedge rst_n) begin
    if(!rst_n) conv_4_cnt <= 0;
    else
    begin
        if(conv_4_cnt == 3 && conv_9_cnt == 8) conv_4_cnt <= 0;
        else if (conv_9_cnt == 8) conv_4_cnt <= conv_4_cnt + 1;
        else conv_4_cnt <= conv_4_cnt;
    end
end

wire clk_38;
wire sleep_38;
assign sleep_38 = !((global_cnt>3 && global_cnt < 220));
GATED_OR GATED_38 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_38), .RST_N(rst_n), .CLOCK_GATED(clk_38));
//conv_9_cnt
always @ (posedge clk_38 or  negedge rst_n)
begin
    if(!rst_n) conv_9_cnt <= 0;
    else begin
        if(global_cnt>3 && global_cnt < 220)
        begin
            if(conv_9_cnt == 8) conv_9_cnt <= 0;
            else if (conv_6_cnt == 6) conv_9_cnt <= 0;
            else conv_9_cnt <= conv_9_cnt + 1;
        end
    end 
end


wire clk_63;
wire sleep_63;
assign sleep_63 = !(global_cnt == 0);
GATED_OR GATED_63 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_63), .RST_N(rst_n), .CLOCK_GATED(clk_63));
//Opt
always @ (posedge clk_63 or negedge rst_n) begin
    if(!rst_n) input_opt <= 0;
    else
    begin
        if(in_valid &&(global_cnt == 0)) input_opt <= Opt;
    end
end

// input_img
// generate
// 	for(i = 0; i < 96; i = i + 1) begin
// 		always @(posedge clk or negedge rst_n) begin
// 			if(!rst_n) input_img[i] <= 0;
//             else
//             begin
//                 if(in_valid && input_cnt == i) input_img[i] <= Img;
//                 else input_img[i] <= input_img[i];
//             end
// 		end
// 	end
// endgenerate

wire clk_39;
wire sleep_39;
assign sleep_39 = !((global_cnt >= 0 && global_cnt <=3) || (global_cnt == 277 && input_opt >= 2) || (global_cnt == 283));
GATED_OR GATED_39 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_39), .RST_N(rst_n), .CLOCK_GATED(clk_39));

always @ (posedge clk_39 or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(k=0; k<=3; k=k+1)begin
            input_img[k] <= 0;
        end
    end
    else
    begin
        if(in_valid == 1 && global_cnt >= 0 && global_cnt <=3) 
        begin
            case(global_cnt)
                0: input_img[0] <= Img;
                1: input_img[1] <= Img;
                2: input_img[2] <= Img;
                3: input_img[3] <= Img;
            endcase
        end
        else if(global_cnt == 277 && input_opt >= 2) 
        begin
            input_img[0] <= add_out1;
            input_img[1] <= add_out2;
            input_img[2] <= add_out3;
            input_img[3] <= add_out4;
        end

        else if(global_cnt == 283)
        begin
            input_img[0] <= {1'b0,add_out1[30:0]};
            input_img[1] <= {1'b0,add_out2[30:0]};
            input_img[2] <= {1'b0,add_out3[30:0]};
            input_img[3] <= {1'b0,add_out4[30:0]};
        end
    end
end

wire clk_40;
wire sleep_40;
assign sleep_40 = !((global_cnt >= 4 && global_cnt <=7) || (global_cnt == 278 && input_opt >= 2) || (global_cnt == 285));
GATED_OR GATED_40 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_40), .RST_N(rst_n), .CLOCK_GATED(clk_40));
always @ (posedge clk_40 or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(k=4; k<=7; k=k+1)begin
            input_img[k] <= 0;
        end
    end
    else
    begin
        if(in_valid == 1 && global_cnt >= 4 && global_cnt <=7)
        begin
            case(global_cnt)
                4: input_img[4] <= Img;
                5: input_img[5] <= Img;
                6: input_img[6] <= Img;
                7: input_img[7] <= Img;
            endcase
        end

        else if(global_cnt == 278 && input_opt >= 2)
        begin
            input_img[4] <= add_out1;
            input_img[5] <= add_out2;
            input_img[6] <= add_out3;
            input_img[7] <= add_out4;    
            // input_img[0] <= recip_out_1;
            // input_img[1] <= recip_out_2;
            // input_img[2] <= recip_out_3;
            // input_img[3] <= recip_out_4;      
        end

        else if(global_cnt == 285)
        begin
            input_img[4] <= add_out1;
            input_img[5] <= add_out2;
        end
    end
end

wire clk_41;
wire sleep_41;
assign sleep_41 = !((global_cnt >= 8 && global_cnt <=11) || (global_cnt == 279 && input_opt >= 2));
GATED_OR GATED_41 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_41), .RST_N(rst_n), .CLOCK_GATED(clk_41));
always @ (posedge clk_41 or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(k=8; k<=11; k=k+1)begin
            input_img[k] <= 0;
        end
    end
    else
    begin
        if(in_valid == 1 && global_cnt >= 8 && global_cnt <=12) 
        begin
            case(global_cnt)
                8: input_img[8] <= Img;
                9: input_img[9] <= Img;
                10: input_img[10] <= Img;
                11: input_img[11] <= Img;
            endcase
        end
        else if(global_cnt == 279 && input_opt >= 2)
        begin
            input_img[8] <= add_out1;
            input_img[9] <= add_out2;
            input_img[10] <= add_out3;
            input_img[11] <= add_out4;
        end
    end
end

wire clk_42;
wire sleep_42;
assign sleep_42 = !((global_cnt >= 12 && global_cnt <=15) || (global_cnt == 280 && input_opt >= 2));
GATED_OR GATED_42 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_42), .RST_N(rst_n), .CLOCK_GATED(clk_42));
always @ (posedge clk_42 or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(k=12; k<= 15; k=k+1)begin
            input_img[k] <= 0;
        end
    end
    else
    begin
        if(in_valid == 1 && global_cnt >= 12 && global_cnt <=15)
        begin
            case(global_cnt)
                12: input_img[12] <= Img;
                13: input_img[13] <= Img;
                14: input_img[14] <= Img;
                15: input_img[15] <= Img;
            endcase
        end


        else if(global_cnt == 280 && input_opt >= 2)
        begin
            input_img[12] <= add_out1;
            input_img[13] <= add_out2;
            input_img[14] <= add_out3;
            input_img[15] <= add_out4;
        end

    end
end

wire img_ctrl [16:95], img_clk [16:95];
generate
 for(i = 16; i <= 95; i = i + 1) begin
  assign img_ctrl[i] = cg_en && !(global_cnt == i);
  GATED_OR U0(.CLOCK(clk), .SLEEP_CTRL(img_ctrl[i]), .RST_N(rst_n), .CLOCK_GATED(img_clk[i]));
  always @(posedge img_clk[i] or negedge rst_n) begin
   if(!rst_n)
    input_img[i] <= 0;
   else if(in_valid && global_cnt == i)
    input_img[i] <= Img;
  end
 end
endgenerate

// input_kernel

wire weight_ctrl [0:26], weight_clk [0:26];
generate
 for(i = 0; i < 27; i = i + 1) begin
  assign weight_ctrl[i] = cg_en && !(global_cnt == i);
  GATED_OR U0(.CLOCK(clk), .SLEEP_CTRL(weight_ctrl[i]), .RST_N(rst_n), .CLOCK_GATED(weight_clk[i]));
  always @(posedge weight_clk[i] or negedge rst_n) begin
   if(!rst_n) 
                input_kernel[i] <= 32'b0;
   else if(global_cnt == i && in_valid) 
                input_kernel[i] <= Kernel;
   else 
                input_kernel[i] <= input_kernel[i];
  end
 end
endgenerate

wire clk_71;
wire sleep_71;
assign sleep_71 = !(global_cnt >= 0 && global_cnt <=3);
GATED_OR GATED_71 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_71), .RST_N(rst_n), .CLOCK_GATED(clk_71));
// input_weight
generate
	for(i = 0; i <= 3; i = i + 1) begin
		always @(posedge clk_71 or negedge rst_n) begin
			if(!rst_n)  input_weight[i] <= 0;
            else
            begin
                if(in_valid && global_cnt == i)
                begin
                    input_weight[i] <= Weight;
                end 
                else input_weight[i] <= input_weight[i];
            end
		end
	end
endgenerate

// // // input counter
// always @ (posedge clk or negedge rst_n)
// begin
//     if(!rst_n) input_cnt <= 0;
//     else
//     begin
//         if(input_cnt == 7'd0)
//         begin 
//             if(!in_valid) input_cnt <= 0;
//             else input_cnt <= input_cnt + 1;
//         end
//         else if (input_cnt == 95) input_cnt <= 0;
//         else input_cnt <= input_cnt + 1;
//     end
// end

// global counter
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) global_cnt <= 0;
    else begin
        if(global_cnt == 9'd0)
        begin
            if(!in_valid) global_cnt <= 0;
            else global_cnt <= global_cnt + 1;
        end
        else if(global_cnt == 1093) global_cnt<=0;
        else global_cnt <= global_cnt + 1;
    end
end


always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid <= 0;
    end
    else
    begin
        if(global_cnt == 1093)
        begin
            out_valid <= 1'b1;
        end
        else out_valid <= 1'b0;
    end
end

reg [31:0] temp_out;
wire clk_72;
wire sleep_72;
assign sleep_72 = !(global_cnt == 287);
GATED_OR GATED_72 (.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_72), .RST_N(rst_n), .CLOCK_GATED(clk_72));
always @ (posedge clk_72 or negedge rst_n)
begin
    if(!rst_n) temp_out <=0;
    else begin
        if(global_cnt == 287) temp_out <= add_out1;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        out <= 0;
    end
    else
    begin
        if(global_cnt == 1093)
        begin
            out <= temp_out;
        end
        else
        begin
            out<=0;
        end
    end
end

// mac
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) mac_1(.a(a_mac1),.b(b_mac1),.c(c_mac1),.rnd(rnd),.z(mac1_out),.status(status_mac_1));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) mac_2(.a(a_mac2),.b(b_mac2),.c(c_mac2),.rnd(rnd),.z(mac2_out),.status(status_mac_2));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) mac_3(.a(a_mac3),.b(b_mac3),.c(c_mac3),.rnd(rnd),.z(mac3_out),.status(status_mac_3));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) mac_4(.a(a_mac4),.b(b_mac4),.c(c_mac4),.rnd(rnd),.z(mac4_out),.status(status_mac_4));

// add
DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance) add_1(.a(add_in1_1), .b(add_in1), .rnd(rnd), .z(add_out1), .status(status_add_1));
DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance) add_2(.a(add_in2_1), .b(add_in2), .rnd(rnd), .z(add_out2), .status(status_add_2));
DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance) add_3(.a(add_in3_1), .b(add_in3), .rnd(rnd), .z(add_out3), .status(status_add_3));
DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance) add_4(.a(add_in4_1), .b(add_in4), .rnd(rnd), .z(add_out4), .status(status_add_4));

// comparator
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance) comp_1(.a(comp_a),.b(comp_b),.zctr(1'b1),.z0(cmp_z0),.z1(cmp_z1),.aeqb(aeqb),.altb(altb),.agtb(agtb),.unordered(unordered),.status0(status_cmp_1),.status1(status_cmp_2));
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance) comp_2(.a(comp_3),.b(comp_4),.zctr(1'b1),.z0(cmp_z3),.z1(cmp_z4),.aeqb(aeqb1),.altb(altb1),.agtb(agtb1),.unordered(unordered1),.status0(status_cmp_3),.status1(status_cmp_4));

//exp
DW_fp_exp #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch) exp_1(.a(exp_in1), .z(exp_out1), .status(status_exp1));
DW_fp_exp #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch) exp_2(.a(exp_in2), .z(exp_out2), .status(status_exp2));
DW_fp_exp #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch) exp_3(.a(exp_in3), .z(exp_out3), .status(status_exp3));
DW_fp_exp #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch) exp_4(.a(exp_in4), .z(exp_out4), .status(status_exp4));

//divide
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) div1 ( .a(a_div1), .b(b_div1), .rnd(rnd), .z(div1_out));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) div2 ( .a(a_div2), .b(b_div2), .rnd(rnd), .z(div2_out));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) div3 ( .a(a_div3), .b(b_div3), .rnd(rnd), .z(div3_out));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) div4 ( .a(a_div4), .b(b_div4), .rnd(rnd), .z(div4_out));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) div5 ( .a(sum_temp_9), .b(constant_9), .rnd(rnd), .z(div5_out));

// sum3
DW_fp_sum3 #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch_type) sum3_a(.a(sum1_1),.b(sum1_2),.c(sum1_3),.rnd(3'b0),.z(sum1_out));
DW_fp_sum3 #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch_type) sum3_b(.a(sum2_1),.b(sum2_2),.c(sum2_3),.rnd(3'b0),.z(sum2_out));
DW_fp_sum3 #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch_type) sum3_c(.a(sum3_1),.b(sum3_2),.c(sum3_3),.rnd(3'b0),.z(sum3_out));
DW_fp_sum3 #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch_type) sum3_d(.a(sum4_1),.b(sum4_2),.c(sum4_3),.rnd(3'b0),.z(sum4_out));

//synopsys dc_script_begin
//set_implementation rtl mac_1
//set_implementation rtl mac_2
//set_implementation rtl mac_3
//set_implementation rtl mac_4
//set_implementation rtl add_1
//set_implementation rtl add_2
//set_implementation rtl add_3
//set_implementation rtl add_4
//set_implementation rtl comp_1
//set_implementation rtl comp_2
//set_implementation rtl exp_1
//set_implementation rtl exp_2
//set_implementation rtl exp_3
//set_implementation rtl exp_4
//set_implementation rtl div1
//set_implementation rtl div2
//set_implementation rtl div3
//set_implementation rtl div4
//synopsys dc_script_end
endmodule