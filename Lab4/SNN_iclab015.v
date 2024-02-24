//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network 
//   Author     		: Jia-Yu Lee (maggie8905121@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SNN(
    //Input Port
    clk,
    rst_n,
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
//   PARAMETER
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
reg [inst_sig_width+inst_exp_width:0] recip_in_1, recip_in_2, recip_in_3, recip_in_4;
reg [inst_sig_width+inst_exp_width:0] recip_out_1, recip_out_2, recip_out_3, recip_out_4;
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
reg [6:0] input_cnt;
reg [3:0] conv_9_cnt; 
reg [2:0] conv_6_cnt;
reg [1:0] conv_4_cnt;
reg [7:0] global_cnt;
reg [inst_sig_width+inst_exp_width:0] cmp_1_reg, cmp_2_reg, cmp_3_reg, cmp_4_reg;
wire [inst_sig_width+inst_exp_width:0] constant_1;
//---------------------------------------------------------------------
//   COMBINATIONAL
//---------------------------------------------------------------------
assign constant_1 = 32'b0011_1111_1000_0000_0000_0000_0000_0000;

// reciprocal
always @ (*)
begin
    recip_in_1 = 0;
    recip_in_2 = 0;
    recip_in_3 = 0;
    recip_in_4 = 0;

    if(global_cnt == 232)
    begin
        recip_in_1 = feature_map[3][0];
        recip_in_2 = feature_map[3][1];
    end

    if(global_cnt == 238 && input_opt < 2)
    begin
        recip_in_1 = pooling_map[0][0][0];
        recip_in_2 = pooling_map[0][0][1];
        recip_in_3 = pooling_map[0][1][0];
        recip_in_4 = pooling_map[0][1][1];        
    end

    if(global_cnt == 241 && input_opt < 2)
    begin
        recip_in_1 = pooling_map[1][0][0];
        recip_in_2 = pooling_map[1][0][1];
        recip_in_3 = pooling_map[1][1][0];
        recip_in_4 = pooling_map[1][1][1];        
    end

    if(global_cnt == 238 && input_opt >=2)
    begin
        recip_in_1 = input_img[0];
        recip_in_2 = input_img[1];
        recip_in_3 = input_img[2];
        recip_in_4 = input_img[3];
    end
    if(global_cnt == 240 && input_opt >=2)
    begin
        recip_in_1 = input_img[8];
        recip_in_2 = input_img[9];
        recip_in_3 = input_img[10];
        recip_in_4 = input_img[11];
    end
end

// exp
always @ (*)
begin
    exp_in1 = 0;
    exp_in2 = 0;
    exp_in3 = 0;
    exp_in4 = 0;
    if(global_cnt == 234)
    begin
        exp_in1 = feature_map[0][0];
        exp_in2 = feature_map[0][1];
        exp_in3 = feature_map[0][2];
        exp_in4 = feature_map[0][3];
    end
    else if(global_cnt == 235)
    begin
        exp_in1 = {~(feature_map[0][0][31]),feature_map[0][0][30:0]};
        exp_in2 = {~(feature_map[0][1][31]),feature_map[0][1][30:0]};
        exp_in3 = {~(feature_map[0][2][31]),feature_map[0][2][30:0]};
        exp_in4 = {~(feature_map[0][3][31]),feature_map[0][3][30:0]};
    end
    else if(global_cnt == 236)
    begin
        exp_in1 = feature_map[1][0];
        exp_in2 = feature_map[1][1];
        exp_in3 = feature_map[1][2];
        exp_in4 = feature_map[1][3];
    end

    else if(global_cnt == 237)
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

    else if(global_cnt == 228)
    begin
        add_in1_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
        add_in2_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
        add_in3_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
        add_in4_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
    end

    else if(global_cnt == 230)
    begin
        add_in1_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
        add_in2_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
        add_in3_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
        add_in4_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
    end
    else if(global_cnt == 231)
    begin
        add_in1_1 = {~(feature_map[2][1][31]),feature_map[2][1][30:0]};
        add_in2_1 = {~(feature_map[2][3][31]),feature_map[2][3][30:0]};
    end

    else if (global_cnt == 237) // sigmoid = 1 + e^-z, tanh = e^z + e^-z 
    begin
        add_in1_1 = feature_map[3][0];
        add_in2_1 = feature_map[3][1];
        add_in3_1 = feature_map[3][2];
        add_in4_1 = feature_map[3][3];
    end

    else if (global_cnt == 238 && input_opt >= 2)
    begin
        add_in1_1 = {~(feature_map[3][0][31]),feature_map[3][0][30:0]};
        add_in2_1 = {~(feature_map[3][1][31]),feature_map[3][1][30:0]};
        add_in3_1 = {~(feature_map[3][2][31]),feature_map[3][2][30:0]};
        add_in4_1 = {~(feature_map[3][3][31]),feature_map[3][3][30:0]};
    end

    else if (global_cnt == 239) // sigmoid = 1 + e^-z, tanh = e^z + e^-z  
    begin
        add_in1_1 = feature_map[1][0];
        add_in2_1 = feature_map[1][1];
        add_in3_1 = feature_map[1][2];
        add_in4_1 = feature_map[1][3];
    end

    else if (global_cnt == 240 && input_opt >= 2)
    begin
        add_in1_1 = {~(feature_map[1][0][31]),feature_map[1][0][30:0]};
        add_in2_1 = {~(feature_map[1][1][31]),feature_map[1][1][30:0]};
        add_in3_1 = {~(feature_map[1][2][31]),feature_map[1][2][30:0]};
        add_in4_1 = {~(feature_map[1][3][31]),feature_map[1][3][30:0]};
    end

    else if (global_cnt == 243)
    begin
        add_in1_1 = {~(pooling_map[1][0][0][31]),pooling_map[1][0][0][30:0]};
        add_in2_1 = {~(pooling_map[1][0][1][31]),pooling_map[1][0][1][30:0]};
        add_in3_1 = {~(pooling_map[1][1][0][31]),pooling_map[1][1][0][30:0]};
        add_in4_1 = {~(pooling_map[1][1][1][31]),pooling_map[1][1][1][30:0]};
    end

    else if(global_cnt == 245)
    begin
        add_in1_1 = input_img[2];
        add_in2_1 = input_img[3];
    end

    else if(global_cnt == 247)
    begin
        add_in1_1 = input_img[5];
    end

end

// pooling map
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) begin
        for(k=0;k<2;k=k+1)begin
            for(j=0;j<2;j=j+1) begin
                for(l=0;l<2;l=l+1) begin
                    pooling_map[k][j][l] <= 0;
                end
            end
        end
    end

    else
    begin
        if(global_cnt == 96) pooling_map[0][0][0] <= cmp_1_reg;
        else if(global_cnt == 98) pooling_map[0][0][1] <= cmp_2_reg;
        else if(global_cnt == 114) pooling_map[0][1][0] <= cmp_1_reg;
        else if(global_cnt == 116) pooling_map[0][1][1] <= cmp_2_reg;
        else if(global_cnt == 204) pooling_map[1][0][0] <= cmp_1_reg;
        else if(global_cnt == 206) pooling_map[1][0][1] <= cmp_2_reg;
        else if(global_cnt == 222) pooling_map[1][1][0] <= cmp_1_reg;
        else if(global_cnt == 224) pooling_map[1][1][1] <= cmp_2_reg;
        else if(global_cnt == 237 && input_opt < 2)
        begin
            pooling_map[0][0][0] <= add_out1;
            pooling_map[0][0][1] <= add_out2;
            pooling_map[0][1][0] <= add_out3;
            pooling_map[0][1][1] <= add_out4;
        end
        else if(global_cnt == 238 && input_opt < 2)
        begin
            pooling_map[0][0][0] <= recip_out_1;
            pooling_map[0][0][1] <= recip_out_2;
            pooling_map[0][1][0] <= recip_out_3;
            pooling_map[0][1][1] <= recip_out_4;
        end
        else if(global_cnt == 239 && input_opt < 2)
        begin
            pooling_map[1][0][0] <= add_out1;
            pooling_map[1][0][1] <= add_out2;
            pooling_map[1][1][0] <= add_out3;
            pooling_map[1][1][1] <= add_out4;
        end

        else if(global_cnt == 241 && input_opt < 2)
        begin
            pooling_map[1][0][0] <= recip_out_1;
            pooling_map[1][0][1] <= recip_out_2;
            pooling_map[1][1][0] <= recip_out_3;
            pooling_map[1][1][1] <= recip_out_4;
        end

        else if(global_cnt == 239 && input_opt >= 2)
        begin
            pooling_map[0][0][0] <= mac1_out;
            pooling_map[0][0][1] <= mac2_out;
            pooling_map[0][1][0] <= mac3_out;
            pooling_map[0][1][1] <= mac4_out;            
        end

        else if(global_cnt == 241 && input_opt >= 2)
        begin
            pooling_map[1][0][0] <= mac1_out;
            pooling_map[1][0][1] <= mac2_out;
            pooling_map[1][1][0] <= mac3_out;
            pooling_map[1][1][1] <= mac4_out;            
        end

        else if(out_valid == 1'b1)
        begin
        for(k=0;k<2;k=k+1)begin
            for(j=0;j<2;j=j+1) begin
                for(l=0;l<2;l=l+1) begin
                    pooling_map[k][j][l] <= 0;
                end
            end
        end
        end
    end
end

// cmp_1_reg
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) cmp_1_reg <= 0;
    else
    begin
        if(global_cnt == 85) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 94) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 95) cmp_1_reg <= cmp_z0;

        else if(global_cnt == 103) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 112) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 113) cmp_1_reg <= cmp_z0;

        else if(global_cnt == 193) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 202) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 203) cmp_1_reg <= cmp_z0;

        else if(global_cnt == 211) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 220) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 221) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 225) cmp_1_reg <= cmp_z0;
        else if (global_cnt == 227) cmp_1_reg <= cmp_z0;

    end
end

// cmp_2_reg
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) cmp_2_reg <= 0;
    else
    begin
        if(global_cnt == 86) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 96) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 97) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 104) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 114) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 115) cmp_2_reg <= cmp_z0;

        else if (global_cnt == 194) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 204) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 205) cmp_2_reg <= cmp_z0;

        else if (global_cnt == 212) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 222) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 223) cmp_2_reg <= cmp_z0;
        else if (global_cnt == 225) cmp_2_reg <= cmp_z1;
        else if (global_cnt == 227) cmp_2_reg <= cmp_z1;
    end
end

// cmp_3_reg
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) cmp_3_reg <= 0;
    else
    begin
        if(global_cnt == 225) cmp_3_reg <= cmp_z3;
        else if(global_cnt == 227) cmp_3_reg <= cmp_z3;
    end
end

// cmp_4_reg
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) cmp_4_reg <= 0;
    else
    begin
        if(global_cnt == 225) cmp_4_reg <= cmp_z4;
        else if(global_cnt == 227) cmp_4_reg <= cmp_z4;
    end
end
//comp_3
always @ (*)
begin
    comp_3 = 0;
    if(global_cnt == 225) comp_3 = feature_map[0][0];
    else if(global_cnt == 226) comp_3 = cmp_3_reg;
    else if(global_cnt == 227) comp_3 = feature_map[1][0];
    else if(global_cnt == 228) comp_3 = cmp_3_reg;
end

//comp_4
always @ (*)
begin
    comp_4 = 0;
    if(global_cnt == 225) comp_4 = feature_map[0][1];
    else if(global_cnt == 226) comp_4 = cmp_1_reg;
    if(global_cnt == 227) comp_4 = feature_map[1][1];
    else if(global_cnt == 228) comp_4 = cmp_1_reg;

end

// comp_a
always @ (*)
begin
    comp_a = 0;
    if(global_cnt == 85)
    begin
        comp_a = feature_map[0][0];
    end

    else if(global_cnt == 86)
    begin
        comp_a = feature_map[0][2];
    end

    else if (global_cnt == 94)
    begin
        comp_a = cmp_1_reg; 
    end

    else if(global_cnt == 95)
    begin
        comp_a = cmp_1_reg;
    end

    else if (global_cnt == 96) comp_a = cmp_2_reg;
    else if (global_cnt == 97) comp_a = cmp_2_reg;  

    else if (global_cnt == 103) comp_a = feature_map[2][0]; 
    else if (global_cnt == 104) comp_a = feature_map[2][2];  
    else if (global_cnt == 112) comp_a = cmp_1_reg; 
    else if (global_cnt == 113) comp_a = cmp_1_reg;     
    else if (global_cnt == 114) comp_a = cmp_2_reg; 
    else if (global_cnt == 115) comp_a = cmp_2_reg;    

    else if (global_cnt == 193) comp_a = feature_map[0][0]; 
    else if (global_cnt == 194) comp_a = feature_map[0][2];  
    else if (global_cnt == 202) comp_a = cmp_1_reg; 
    else if (global_cnt == 203) comp_a = cmp_1_reg;     
    else if (global_cnt == 204) comp_a = cmp_2_reg; 
    else if (global_cnt == 205) comp_a = cmp_2_reg;

    else if (global_cnt == 211) comp_a = feature_map[2][0]; 
    else if (global_cnt == 212) comp_a = feature_map[2][2];  
    else if (global_cnt == 220) comp_a = cmp_1_reg; 
    else if (global_cnt == 221) comp_a = cmp_1_reg;     
    else if (global_cnt == 222) comp_a = cmp_2_reg; 
    else if (global_cnt == 223) comp_a = cmp_2_reg;  

    else if (global_cnt == 225) comp_a = feature_map[0][2];  
    else if (global_cnt == 226) comp_a = cmp_4_reg;
    else if (global_cnt == 227) comp_a = feature_map[1][2]; 
    else if (global_cnt == 228) comp_a = cmp_4_reg;


end

// comp_b
always @ (*)
begin
    comp_b = 0;
    if(global_cnt == 85)
    begin
        comp_b = feature_map[0][1];
    end
    else if(global_cnt == 86)
    begin
        comp_b = feature_map[0][3];
    end

    else if (global_cnt == 94)
    begin
        comp_b = feature_map[1][0];
    end

    else if (global_cnt == 95)
    begin
        comp_b = feature_map[1][1];
    end
    else if (global_cnt == 96) comp_b = feature_map[1][2];
    else if (global_cnt == 97) comp_b = feature_map[1][3];

    else if (global_cnt == 103) comp_b = feature_map[2][1];
    else if (global_cnt == 104) comp_b = feature_map[2][3];
    else if (global_cnt == 112) comp_b = feature_map[3][0];
    else if (global_cnt == 113) comp_b = feature_map[3][1];
    else if (global_cnt == 114) comp_b = feature_map[3][2];
    else if (global_cnt == 115) comp_b = feature_map[3][3];

    else if (global_cnt == 193) comp_b = feature_map[0][1];
    else if (global_cnt == 194) comp_b = feature_map[0][3];
    else if (global_cnt == 202) comp_b = feature_map[1][0];
    else if (global_cnt == 203) comp_b = feature_map[1][1];
    else if (global_cnt == 204) comp_b = feature_map[1][2];
    else if (global_cnt == 205) comp_b = feature_map[1][3];

    else if (global_cnt == 211) comp_b = feature_map[2][1];
    else if (global_cnt == 212) comp_b = feature_map[2][3];
    else if (global_cnt == 220) comp_b = feature_map[3][0];
    else if (global_cnt == 221) comp_b = feature_map[3][1];
    else if (global_cnt == 222) comp_b = feature_map[3][2];
    else if (global_cnt == 223) comp_b = feature_map[3][3];

    else if (global_cnt == 225) comp_b = feature_map[0][3];
    else if (global_cnt == 226) comp_b = cmp_2_reg;
    else if (global_cnt == 227) comp_b = feature_map[1][3];
    else if (global_cnt == 228) comp_b = cmp_2_reg;
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
// feature_map
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) 
    begin
        for(j=0;j<4;j=j+1) begin
            for(l=0;l<4;l=l+1) begin
                feature_map[j][l] <= 0;
            end
        end
    end

    else
    begin
        if(conv_4_cnt == 0 && conv_6_cnt == 3 && conv_9_cnt == 6)
        begin
            for(j=0;j<4;j=j+1) begin
                for(l=0;l<4;l=l+1) begin
                    feature_map[j][l] <= 0;
                end
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
                1: 
                begin
                    feature_map[1][0] <= add_out1;
                    feature_map[1][1] <= add_out2;
                    feature_map[1][2] <= add_out3;
                    feature_map[1][3] <= add_out4;
                end
                2: 
                begin
                    feature_map[2][0] <= add_out1;
                    feature_map[2][1] <= add_out2;
                    feature_map[2][2] <= add_out3;
                    feature_map[2][3] <= add_out4;
                end 
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
        if(global_cnt == 221) 
        begin
            feature_map[0][0] <= mac1_out;       
            feature_map[0][1] <= mac2_out;
            feature_map[0][2] <= mac3_out;
            feature_map[0][3] <= mac4_out;
        end
        if(global_cnt == 226) 
        begin
            feature_map[1][0] <= mac1_out;       
            feature_map[1][1] <= mac2_out;
            feature_map[1][2] <= mac3_out;
            feature_map[1][3] <= mac4_out;
            feature_map[2][0] <= cmp_z3;       
            feature_map[2][1] <= cmp_z1;
        end
        if(global_cnt == 228)
        begin
            feature_map[2][2] <= cmp_z3;       
            feature_map[2][3] <= cmp_z1;            
            feature_map[0][0] <= add_out1;       
            feature_map[0][1] <= add_out2;
            feature_map[0][2] <= add_out3;
            feature_map[0][3] <= add_out4;
        end
        if(global_cnt == 230)
        begin         
            feature_map[1][0] <= add_out1;       
            feature_map[1][1] <= add_out2;
            feature_map[1][2] <= add_out3;
            feature_map[1][3] <= add_out4;
        end
        if(global_cnt == 231)
        begin         
            feature_map[3][0] <= add_out1;       
            feature_map[3][1] <= add_out2;
        end

        if(global_cnt == 232)
        begin
            feature_map[3][2] <= recip_out_1;       
            feature_map[3][3] <= recip_out_2;            
        end

        if(global_cnt == 233)
        begin
            feature_map[0][0] <= mac1_out;
            feature_map[0][1] <= mac2_out;
            feature_map[0][2] <= mac3_out;
            feature_map[0][3] <= mac4_out;           
        end

        if(global_cnt == 234)
        begin
            feature_map[1][0] <= mac1_out;
            feature_map[1][1] <= mac2_out;
            feature_map[1][2] <= mac3_out;
            feature_map[1][3] <= mac4_out;       
            feature_map[2][0] <= exp_out1; // +z1
            feature_map[2][1] <= exp_out2;
            feature_map[2][2] <= exp_out3;
            feature_map[2][3] <= exp_out4;    
        end

        if(global_cnt == 235)
        begin
            feature_map[3][0] <= exp_out1; // -z1
            feature_map[3][1] <= exp_out2;
            feature_map[3][2] <= exp_out3;
            feature_map[3][3] <= exp_out4;  
        end

        if(global_cnt == 236)
        begin
            feature_map[0][0] <= exp_out1;// +z2
            feature_map[0][1] <= exp_out2;
            feature_map[0][2] <= exp_out3;
            feature_map[0][3] <= exp_out4;  
        end

        if(global_cnt == 237)
        begin
            feature_map[1][0] <= exp_out1;// -z2
            feature_map[1][1] <= exp_out2;
            feature_map[1][2] <= exp_out3;
            feature_map[1][3] <= exp_out4;  
        end

        if(out_valid == 1'b1) // zero
        begin
        for(j=0;j<4;j=j+1) begin
            for(l=0;l<4;l=l+1) begin
                feature_map[j][l] <= 0;
            end
        end
        end

    end
end


// add_in1
always @ (posedge clk or negedge rst_n)
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

        else if(global_cnt == 227) add_in1 <= feature_map[0][0]; 
        else if(global_cnt == 229) add_in1 <= feature_map[1][0]; 
        else if(global_cnt == 230) add_in1 <= feature_map[2][0];
        else if(global_cnt == 236 && input_opt < 2) add_in1 <= constant_1; // sigmoid
        else if(global_cnt == 238 && input_opt < 2) add_in1 <= constant_1;

        else if(global_cnt == 236 && input_opt >= 2) add_in1 <= feature_map[2][0]; // tanh
        else if(global_cnt == 237 && input_opt >= 2) add_in1 <= feature_map[2][0];
        else if(global_cnt == 238 && input_opt >= 2) add_in1 <= feature_map[0][0];
        else if(global_cnt == 239 && input_opt >= 2) add_in1 <= feature_map[0][0];
        else if(global_cnt == 242) add_in1 <= pooling_map[0][0][0];
        else if(global_cnt == 244) add_in1 <= input_img[0];
        else if(global_cnt == 246) add_in1 <= input_img[4];
    end
end

// add_in2
always @ (posedge clk or negedge rst_n)
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
        else if (global_cnt == 227) add_in2 <= feature_map[0][1];
        else if (global_cnt == 229) add_in2 <= feature_map[1][1];
        else if (global_cnt == 230) add_in2 <= feature_map[2][2];
        else if (global_cnt == 236 && input_opt < 2) add_in2 <= constant_1;
        else if (global_cnt == 238 && input_opt < 2) add_in2 <= constant_1;

        else if(global_cnt == 236 && input_opt >= 2) add_in2 <= feature_map[2][1];
        else if(global_cnt == 237 && input_opt >= 2) add_in2 <= feature_map[2][1];
        else if(global_cnt == 238 && input_opt >= 2) add_in2 <= feature_map[0][1];
        else if(global_cnt == 239 && input_opt >= 2) add_in2 <= feature_map[0][1];
        else if(global_cnt == 242) add_in2 <= pooling_map[0][0][1];
        else if(global_cnt == 244) add_in2 <= input_img[1];
    end
end
// add_in3
always @ (posedge clk or negedge rst_n)
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
        else if (global_cnt == 227) add_in3 <= feature_map[0][2];
        else if (global_cnt == 229) add_in3 <= feature_map[1][2];
        else if (global_cnt == 236 && input_opt < 2) add_in3 <= constant_1;
        else if (global_cnt == 238 && input_opt < 2) add_in3 <= constant_1;

        else if (global_cnt == 236 && input_opt >= 2) add_in3 <= feature_map[2][2];
        else if (global_cnt == 237 && input_opt >= 2) add_in3 <= feature_map[2][2];
        else if (global_cnt == 238 && input_opt >= 2) add_in3 <= feature_map[0][2];
        else if (global_cnt == 239 && input_opt >= 2) add_in3 <= feature_map[0][2];
        else if(global_cnt == 242) add_in3 <= pooling_map[0][1][0];
    end
end
// add_in4
always @ (posedge clk or negedge rst_n)
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
        else if (global_cnt == 227) add_in4 <= feature_map[0][3];
        else if (global_cnt == 229) add_in4 <= feature_map[1][3];
        else if (global_cnt == 236 && input_opt < 2) add_in4 <= constant_1;
        else if (global_cnt == 238 && input_opt < 2) add_in4 <= constant_1;

        else if (global_cnt == 236 && input_opt >= 2) add_in4 <= feature_map[2][3];
        else if (global_cnt == 237 && input_opt >= 2) add_in4 <= feature_map[2][3];
        else if (global_cnt == 238 && input_opt >= 2) add_in4 <= feature_map[0][3];
        else if (global_cnt == 239 && input_opt >= 2) add_in4 <= feature_map[0][3];
        else if(global_cnt == 242) add_in4 <= pooling_map[0][1][1];
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
    else if(global_cnt == 220) a_mac1 = pooling_map[0][0][0];
    else if(global_cnt == 221) a_mac1 = pooling_map[0][0][1];
    else if(global_cnt == 225) a_mac1 = pooling_map[1][0][0];
    else if(global_cnt == 226) a_mac1 = pooling_map[1][0][1];
    else if(global_cnt == 233) a_mac1 = feature_map[0][0];
    else if(global_cnt == 234) a_mac1 = feature_map[1][0];
    else if(global_cnt == 239 && input_opt >=2 ) a_mac1 = input_img[0];
    else if(global_cnt == 241 && input_opt >=2 ) a_mac1 = input_img[8];
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
    else if(global_cnt == 220) b_mac1 = input_weight[0];
    else if(global_cnt == 221) b_mac1 = input_weight[2];
    else if(global_cnt == 225) b_mac1 = input_weight[0];
    else if(global_cnt == 226) b_mac1 = input_weight[2];
    else if(global_cnt == 233) b_mac1 = feature_map[3][2];
    else if(global_cnt == 234) b_mac1 = feature_map[3][3];
    else if(global_cnt == 239 && input_opt >=2 ) b_mac1 = input_img[4];
    else if(global_cnt == 241 && input_opt >=2 ) b_mac1 = input_img[12];
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) c_mac1 <= 32'b0;
    else
    begin
        if(global_cnt>3 && global_cnt < 220)
        begin
            if(conv_9_cnt == 8) c_mac1 <= 32'b0;
            else c_mac1 <= mac1_out;
        end 
        if(global_cnt == 220) c_mac1 <= mac1_out;
        if(global_cnt == 221) c_mac1 <= 0;  
        if(global_cnt == 225) c_mac1 <= mac1_out;
        if(global_cnt == 226) c_mac1 <= 0;       
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
    else if(global_cnt == 220) a_mac2 = pooling_map[0][0][0];
    else if(global_cnt == 221) a_mac2 = pooling_map[0][0][1];
    else if(global_cnt == 225) a_mac2 = pooling_map[1][0][0];
    else if(global_cnt == 226) a_mac2 = pooling_map[1][0][1];
    else if(global_cnt == 233) a_mac2 = feature_map[0][1];
    else if(global_cnt == 234) a_mac2 = feature_map[1][1];
    else if(global_cnt == 239 && input_opt >=2 ) a_mac2 = input_img[1];
    else if(global_cnt == 241 && input_opt >=2 ) a_mac2 = input_img[9];
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
    else if(global_cnt == 220) b_mac2 = input_weight[1];
    else if(global_cnt == 221) b_mac2 = input_weight[3];
    else if(global_cnt == 225) b_mac2 = input_weight[1];
    else if(global_cnt == 226) b_mac2 = input_weight[3];
    else if(global_cnt == 233) b_mac2 = feature_map[3][2];
    else if(global_cnt == 234) b_mac2 = feature_map[3][3];
    else if(global_cnt == 239 && input_opt >=2 ) b_mac2 = input_img[5];
    else if(global_cnt == 241 && input_opt >=2 ) b_mac2 = input_img[13];
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) c_mac2 <= 32'b0;
    else
    begin
        if(global_cnt>3 && global_cnt < 220)
        begin
            if(conv_9_cnt == 8) c_mac2 <= 32'b0;
            else c_mac2 <= mac2_out;
        end      
        if(global_cnt == 220) c_mac2 <= mac2_out; 
        if(global_cnt == 221) c_mac2 <= 0;   
        if(global_cnt == 225) c_mac2 <= mac2_out; 
        if(global_cnt == 226) c_mac2 <= 0; 
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
    else if(global_cnt == 220) a_mac3 = pooling_map[0][1][0];
    else if(global_cnt == 221) a_mac3 = pooling_map[0][1][1];
    else if(global_cnt == 225) a_mac3 = pooling_map[1][1][0];
    else if(global_cnt == 226) a_mac3 = pooling_map[1][1][1];
    else if(global_cnt == 233) a_mac3 = feature_map[0][2];
    else if(global_cnt == 234) a_mac3 = feature_map[1][2];
    else if(global_cnt == 239 && input_opt >=2 ) a_mac3 = input_img[2];
    else if(global_cnt == 241 && input_opt >=2 ) a_mac3 = input_img[10];
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
    else if(global_cnt == 220) b_mac3 = input_weight[0];
    else if(global_cnt == 221) b_mac3 = input_weight[2]; 
    else if(global_cnt == 225) b_mac3 = input_weight[0];
    else if(global_cnt == 226) b_mac3 = input_weight[2]; 
    else if(global_cnt == 233) b_mac3 = feature_map[3][2];
    else if(global_cnt == 234) b_mac3 = feature_map[3][3];
    else if(global_cnt == 239 && input_opt >=2 ) b_mac3 = input_img[6];
    else if(global_cnt == 241 && input_opt >=2 ) b_mac3 = input_img[14];
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) c_mac3 <= 32'b0;
    else
    begin
        if(global_cnt>3 && global_cnt < 220)
        begin
            if(conv_9_cnt == 8) c_mac3 <= 32'b0;
            else c_mac3 <= mac3_out;
        end 
        if(global_cnt == 220) c_mac3 <= mac3_out;   
        if(global_cnt == 221) c_mac3 <= 0;        
        if(global_cnt == 225) c_mac3 <= mac3_out; 
        if(global_cnt == 226) c_mac3 <= 0; 
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
    else if(global_cnt == 220) a_mac4 = pooling_map[0][1][0];
    else if(global_cnt == 221) a_mac4 = pooling_map[0][1][1];
    else if(global_cnt == 225) a_mac4 = pooling_map[1][1][0];
    else if(global_cnt == 226) a_mac4 = pooling_map[1][1][1];
    else if (global_cnt == 233) a_mac4 = feature_map[0][3];
    else if (global_cnt == 234) a_mac4 = feature_map[1][3];
    else if(global_cnt == 239 && input_opt >=2 ) a_mac4 = input_img[3];
    else if(global_cnt == 241 && input_opt >=2 ) a_mac4 = input_img[11];
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
    else if(global_cnt == 220) b_mac4 = input_weight[1];
    else if(global_cnt == 221) b_mac4 = input_weight[3]; 
    else if(global_cnt == 225) b_mac4 = input_weight[1];
    else if(global_cnt == 226) b_mac4 = input_weight[3]; 
    else if(global_cnt == 233) b_mac4 = feature_map[3][2];
    else if(global_cnt == 234) b_mac4 = feature_map[3][3];
    else if(global_cnt == 239 && input_opt >=2 ) b_mac4 = input_img[7];
    else if(global_cnt == 241 && input_opt >=2 ) b_mac4 = input_img[15];
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) c_mac4 <= 32'b0;
    else
    begin
        if(global_cnt>3 && global_cnt < 220)
        begin
            if(conv_9_cnt == 8) c_mac4 <= 32'b0;
            else c_mac4 <= mac4_out;
        end    
        if(global_cnt == 220) c_mac4 <= mac4_out;  
        if(global_cnt == 221) c_mac4 <= 0;   
        if(global_cnt == 225) c_mac4 <= mac4_out;  
        if(global_cnt == 226) c_mac4 <= 0;  
        // else c_mac4 <= 0;   
    end
end

//conv_6_cnt
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) conv_6_cnt <= 0;
    else 
    begin
        if(conv_6_cnt == 6) conv_6_cnt <= 0;
        else if (conv_4_cnt == 3 && conv_9_cnt == 8) conv_6_cnt <= conv_6_cnt + 1;
        else conv_6_cnt <= conv_6_cnt;
    end
end

//conv_4_cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) conv_4_cnt <= 0;
    else
    begin
        if(conv_4_cnt == 3 && conv_9_cnt == 8) conv_4_cnt <= 0;
        else if (conv_9_cnt == 8) conv_4_cnt <= conv_4_cnt + 1;
        else conv_4_cnt <= conv_4_cnt;
    end
end

//conv_9_cnt
always @ (posedge clk or  negedge rst_n)
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


//Opt
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) input_opt <= 0;
    else
    begin
        if(in_valid &&(input_cnt <1)) input_opt <= Opt;
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

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(k=0; k< 96; k=k+1)begin
            input_img[k] <= 0;
        end
    end
    else
    begin
        if(in_valid == 1) input_img[input_cnt] <= Img;
        else if(global_cnt == 237 && input_opt >= 2) 
        begin
            input_img[0] <= add_out1;
            input_img[1] <= add_out2;
            input_img[2] <= add_out3;
            input_img[3] <= add_out4;
        end
        else if(global_cnt == 238 && input_opt >= 2)
        begin
            input_img[4] <= add_out1;
            input_img[5] <= add_out2;
            input_img[6] <= add_out3;
            input_img[7] <= add_out4;    
            input_img[0] <= recip_out_1;
            input_img[1] <= recip_out_2;
            input_img[2] <= recip_out_3;
            input_img[3] <= recip_out_4;      
        end

        else if(global_cnt == 239 && input_opt >= 2)
        begin
            input_img[8] <= add_out1;
            input_img[9] <= add_out2;
            input_img[10] <= add_out3;
            input_img[11] <= add_out4;
        end
        else if(global_cnt == 240 && input_opt >= 2)
        begin
            input_img[12] <= add_out1;
            input_img[13] <= add_out2;
            input_img[14] <= add_out3;
            input_img[15] <= add_out4;
            input_img[8] <= recip_out_1;
            input_img[9] <= recip_out_2;
            input_img[10] <= recip_out_3;
            input_img[11] <= recip_out_4;
        end

        else if(global_cnt == 243)
        begin
            input_img[0] <= {1'b0,add_out1[30:0]};
            input_img[1] <= {1'b0,add_out2[30:0]};
            input_img[2] <= {1'b0,add_out3[30:0]};
            input_img[3] <= {1'b0,add_out4[30:0]};
        end

        else if(global_cnt == 245)
        begin
            input_img[4] <= add_out1;
            input_img[5] <= add_out2;
        end
    end
end

// input_kernel
generate
	for(i = 0; i < 27; i = i + 1) begin
		always @(posedge clk or negedge rst_n) begin
			if(!rst_n) input_kernel[i] <= 0;
            else
            begin
                if(in_valid && input_cnt == i) input_kernel[i] <= Kernel;
                else input_kernel[i] <= input_kernel[i];
            end
		end
	end
endgenerate

// input_weight
generate
	for(i = 0; i < 4; i = i + 1) begin
		always @(posedge clk or negedge rst_n) begin
			if(!rst_n)  input_weight[i] <= 0;
            else
            begin
                if(in_valid && input_cnt == i)
                begin
                    input_weight[i] <= Weight;
                end 
                else input_weight[i] <= input_weight[i];
            end
		end
	end
endgenerate

// input counter
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) input_cnt <= 0;
    else
    begin
        if(input_cnt == 7'd0)
        begin 
            if(!in_valid) input_cnt <= 0;
            else input_cnt <= input_cnt + 1;
        end
        else if (input_cnt == 95) input_cnt <= 0;
        else input_cnt <= input_cnt + 1;
    end
end
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
        else if(global_cnt == 247) global_cnt<=0;
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
        if(global_cnt == 247)
        begin
            out_valid <= 1'b1;
        end
        else out_valid <= 1'b0;
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
        if(global_cnt == 247)
        begin
            out <= add_out1;
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

//reciprocal (divide)
DW_fp_recip #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_faithful_round) recip_1(.a(recip_in_1), .rnd(rnd), .z(recip_out_1), .status(status_recip_1));
DW_fp_recip #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_faithful_round) recip_2(.a(recip_in_2), .rnd(rnd), .z(recip_out_2), .status(status_recip_2));
DW_fp_recip #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_faithful_round) recip_3(.a(recip_in_3), .rnd(rnd), .z(recip_out_3), .status(status_recip_3));
DW_fp_recip #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_faithful_round) recip_4(.a(recip_in_4), .rnd(rnd), .z(recip_out_4), .status(status_recip_4));
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
//set_implementation rtl recip_1
//set_implementation rtl recip_2
//set_implementation rtl recip_3
//set_implementation rtl recip_4
//synopsys dc_script_end
endmodule
