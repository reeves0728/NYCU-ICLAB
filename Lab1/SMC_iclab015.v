//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab01 Exercise		: Supper MOSFET Calculator
//   Author     		: Lin-Hung Lai (lhlai@ieee.org)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SMC.v
//   Module Name : SMC
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module SMC(
  // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
//output [7:0] out_n;         					// use this if using continuous assignment for out_n  // Ex: assign out_n = XXX;
output reg [7:0] out_n; 								// use this if using procedure assignment for out_n   // Ex: always@(*) begin out_n = XXX; end

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [7:0] id [0:5];
wire [7:0] gm [0:5];
wire [7:0] out_a [0:2];
wire [7:0] out_b [0:2];
wire [9:0] out_b_s;
wire [7:0] gm_avg_a;
wire [7:0] gm_avg_b;
wire [7:0] i_avg_a;
wire [9:0] i_avg_b;
wire [7:0] i_avg_c;
wire [7:0] i_avg_d;
reg [7:0] i_avg;
reg [7:0] gm_avg;
reg [7:0] cal_in [0:5];
//================================================================
//    DESIGN
//================================================================

// --------------------------------------------------
// write your design here
// --------------------------------------------------

/*Calculate Id or gm*/
Calculate c0(.w(W_0),.vgs(V_GS_0),.vds(V_DS_0),.id(id[0]),.gm(gm[0]));
Calculate c1(.w(W_1),.vgs(V_GS_1),.vds(V_DS_1),.id(id[1]),.gm(gm[1]));
Calculate c2(.w(W_2),.vgs(V_GS_2),.vds(V_DS_2),.id(id[2]),.gm(gm[2]));
Calculate c3(.w(W_3),.vgs(V_GS_3),.vds(V_DS_3),.id(id[3]),.gm(gm[3]));
Calculate c4(.w(W_4),.vgs(V_GS_4),.vds(V_DS_4),.id(id[4]),.gm(gm[4]));
Calculate c5(.w(W_5),.vgs(V_GS_5),.vds(V_DS_5),.id(id[5]),.gm(gm[5]));

/*Sort*/
merge_sort s0(.in_0(cal_in[0]),.in_1(cal_in[1]),.in_2(cal_in[2]),.in_3(cal_in[3]),.in_4(cal_in[4]),.in_5(cal_in[5]),.mode(mode[1]),.out_1(out_a[0]),.out_2(out_a[1]),.out_3(out_a[2]));
look_up_table o0(.out_a(out_a[0]),.out_a_d3(out_b[0]));
look_up_table o1(.out_a(out_a[1]),.out_a_d3(out_b[1]));
look_up_table o2(.out_a(out_a[2]),.out_a_d3(out_b[2]));
look_up_table o3(.out_a(i_avg_c),.out_a_d3(i_avg_d));
look_up_table o4(.out_a(gm_avg_a),.out_a_d3(gm_avg_b));
// look_up_table_12 o4(.out_a(i_avg_a), .out_a_d12(i_avg_b));

/*Select according to mode*/

// assign i_avg_a = (3*out_b[0] + 4*out_b[1] + 5*out_b[2]);
assign i_avg_b = (3*out_b[0] + out_b_s + 5*out_b[2]);
assign i_avg_c = i_avg_b >> 2;
assign out_b_s = out_b[1] << 2;
assign gm_avg_a = (out_b[0]+out_b[1]+out_b[2]);


always @ (*) begin
  if(mode[0] == 1) begin // calculte I
    if(mode[1] == 1) begin // larger
      cal_in[0] = id[0];
      cal_in[1] = id[1];
      cal_in[2] = id[2];
      cal_in[3] = id[3];
      cal_in[4] = id[4];
      cal_in[5] = id[5];                    
    end

    else begin
      cal_in[0] = ~id[0];
      cal_in[1] = ~id[1]; 
      cal_in[2] = ~id[2];    
      cal_in[3] = ~id[3];    
      cal_in[4] = ~id[4];    
      cal_in[5] = ~id[5];           
    end 
  end

  else begin
    if(mode[1] == 1) begin // larger
      cal_in[0] = gm[0];
      cal_in[1] = gm[1];
      cal_in[2] = gm[2];
      cal_in[3] = gm[3];
      cal_in[4] = gm[4];
      cal_in[5] = gm[5];                    
    end

    else begin
      cal_in[0] = ~gm[0];
      cal_in[1] = ~gm[1]; 
      cal_in[2] = ~gm[2];    
      cal_in[3] = ~gm[3];    
      cal_in[4] = ~gm[4];    
      cal_in[5] = ~gm[5];           
    end 

  end
  
end

always @ (*) begin
  i_avg = 8'd0;
  gm_avg = 8'd0;
  if (mode[0] == 1) begin // average the current
  i_avg =  i_avg_d;
  end
  else begin
  gm_avg = gm_avg_b;
  end
end

/*Output*/

assign out_n = (mode[0] == 1) ? i_avg : gm_avg;

endmodule


//================================================================
//   SUB MODULE
//================================================================

module look_up_table (out_a, out_a_d3);
input [7:0] out_a;
output reg [7:0] out_a_d3;

always @ (*) begin
  case(out_a)
    8'd0 : out_a_d3 = 0;
    8'd1 : out_a_d3 = 0;
    8'd2 : out_a_d3 = 0;
    8'd3 : out_a_d3 = 1;
    8'd4 : out_a_d3 = 1;
    8'd5 : out_a_d3 = 1;
    8'd6 : out_a_d3 = 2;
    8'd7 : out_a_d3 = 2;
    8'd8 : out_a_d3 = 2;
    8'd9 : out_a_d3 = 3;
    8'd10 : out_a_d3 = 3;
    8'd11 : out_a_d3 = 3;
    8'd12 : out_a_d3 = 4;
    8'd13 : out_a_d3 = 4;
    8'd14 : out_a_d3 = 4;
    8'd15 : out_a_d3 = 5;
    8'd16 : out_a_d3 = 5;
    8'd17 : out_a_d3 = 5;
    8'd18 : out_a_d3 = 6;
    8'd19 : out_a_d3 = 6;
    8'd20 : out_a_d3 = 6;
    8'd21 : out_a_d3 = 7;
    8'd22 : out_a_d3 = 7;
    8'd23 : out_a_d3 = 7;
    8'd24 : out_a_d3 = 8;
    8'd25 : out_a_d3 = 8;
    8'd26 : out_a_d3 = 8;
    8'd27 : out_a_d3 = 9;
    8'd28 : out_a_d3 = 9;
    8'd29 : out_a_d3 = 9;
    8'd30 : out_a_d3 = 10;
    8'd31 : out_a_d3 = 10;
    8'd32 : out_a_d3 = 10;
    8'd33 : out_a_d3 = 11;
    8'd34 : out_a_d3 = 11;
    8'd35 : out_a_d3 = 11;
    8'd36 : out_a_d3 = 12;
    8'd37 : out_a_d3 = 12;
    8'd38 : out_a_d3 = 12;
    8'd39 : out_a_d3 = 13;
    8'd40 : out_a_d3 = 13;
    8'd41 : out_a_d3 = 13;
    8'd42 : out_a_d3 = 14;
    8'd43 : out_a_d3 = 14;
    8'd44 : out_a_d3 = 14;
    8'd45 : out_a_d3 = 15;
    8'd46 : out_a_d3 = 15;
    8'd47 : out_a_d3 = 15;
    8'd48 : out_a_d3 = 16;
    8'd49 : out_a_d3 = 16;
    8'd50 : out_a_d3 = 16;
    8'd51 : out_a_d3 = 17;
    8'd52 : out_a_d3 = 17;
    8'd53 : out_a_d3 = 17;
    8'd54 : out_a_d3 = 18;
    8'd55 : out_a_d3 = 18;
    8'd56 : out_a_d3 = 18;
    8'd57 : out_a_d3 = 19;
    8'd58 : out_a_d3 = 19;
    8'd59 : out_a_d3 = 19;
    8'd60 : out_a_d3 = 20;
    8'd61 : out_a_d3 = 20;
    8'd62 : out_a_d3 = 20;
    8'd63 : out_a_d3 = 21;
    8'd64 : out_a_d3 = 21;
    8'd65 : out_a_d3 = 21;
    8'd66 : out_a_d3 = 22;
    8'd67 : out_a_d3 = 22;
    8'd68 : out_a_d3 = 22;
    8'd69 : out_a_d3 = 23;
    8'd70 : out_a_d3 = 23;
    8'd71 : out_a_d3 = 23;
    8'd72 : out_a_d3 = 24;
    8'd73 : out_a_d3 = 24;
    8'd74 : out_a_d3 = 24;
    8'd75 : out_a_d3 = 25;
    8'd76 : out_a_d3 = 25;
    8'd77 : out_a_d3 = 25;
    8'd78 : out_a_d3 = 26;
    8'd79 : out_a_d3 = 26;
    8'd80 : out_a_d3 = 26;
    8'd81 : out_a_d3 = 27;
    8'd82 : out_a_d3 = 27;
    8'd83 : out_a_d3 = 27;
    8'd84 : out_a_d3 = 28;
    8'd85 : out_a_d3 = 28;
    8'd86 : out_a_d3 = 28;
    8'd87 : out_a_d3 = 29;
    8'd88 : out_a_d3 = 29;
    8'd89 : out_a_d3 = 29;
    8'd90 : out_a_d3 = 30;
    8'd91 : out_a_d3 = 30;
    8'd92 : out_a_d3 = 30;
    8'd93 : out_a_d3 = 31;
    8'd94 : out_a_d3 = 31;
    8'd95 : out_a_d3 = 31;
    8'd96 : out_a_d3 = 32;
    8'd97 : out_a_d3 = 32;
    8'd98 : out_a_d3 = 32;
    8'd99 : out_a_d3 = 33;
    8'd100 : out_a_d3 = 33;
    8'd101 : out_a_d3 = 33;
    8'd102 : out_a_d3 = 34;
    8'd103 : out_a_d3 = 34;
    8'd104 : out_a_d3 = 34;
    8'd105 : out_a_d3 = 35;
    8'd106 : out_a_d3 = 35;
    8'd107 : out_a_d3 = 35;
    8'd108 : out_a_d3 = 36;
    8'd109 : out_a_d3 = 36;
    8'd110 : out_a_d3 = 36;
    8'd111 : out_a_d3 = 37;
    8'd112 : out_a_d3 = 37;
    8'd113 : out_a_d3 = 37;
    8'd114 : out_a_d3 = 38;
    8'd115 : out_a_d3 = 38;
    8'd116 : out_a_d3 = 38;
    8'd117 : out_a_d3 = 39;
    8'd118 : out_a_d3 = 39;
    8'd119 : out_a_d3 = 39;
    8'd120 : out_a_d3 = 40;
    8'd121 : out_a_d3 = 40;
    8'd122 : out_a_d3 = 40;
    8'd123 : out_a_d3 = 41;
    8'd124 : out_a_d3 = 41;
    8'd125 : out_a_d3 = 41;
    8'd126 : out_a_d3 = 42;
    8'd127 : out_a_d3 = 42;
    8'd128 : out_a_d3 = 42;
    8'd129 : out_a_d3 = 43;
    8'd130 : out_a_d3 = 43;
    8'd131 : out_a_d3 = 43;
    8'd132 : out_a_d3 = 44;
    8'd133 : out_a_d3 = 44;
    8'd134 : out_a_d3 = 44;
    8'd135 : out_a_d3 = 45;
    8'd136 : out_a_d3 = 45;
    8'd137 : out_a_d3 = 45;
    8'd138 : out_a_d3 = 46;
    8'd139 : out_a_d3 = 46;
    8'd140 : out_a_d3 = 46;
    8'd141 : out_a_d3 = 47;
    8'd142 : out_a_d3 = 47;
    8'd143 : out_a_d3 = 47;
    8'd144 : out_a_d3 = 48;
    8'd145 : out_a_d3 = 48;
    8'd146 : out_a_d3 = 48;
    8'd147 : out_a_d3 = 49;
    8'd148 : out_a_d3 = 49;
    8'd149 : out_a_d3 = 49;
    8'd150 : out_a_d3 = 50;
    8'd151 : out_a_d3 = 50;
    8'd152 : out_a_d3 = 50;
    8'd153 : out_a_d3 = 51;
    8'd154 : out_a_d3 = 51;
    8'd155 : out_a_d3 = 51;
    8'd156 : out_a_d3 = 52;
    8'd157 : out_a_d3 = 52;
    8'd158 : out_a_d3 = 52;
    8'd159 : out_a_d3 = 53;
    8'd160 : out_a_d3 = 53;
    8'd161 : out_a_d3 = 53;
    8'd162 : out_a_d3 = 54;
    8'd163 : out_a_d3 = 54;
    8'd164 : out_a_d3 = 54;
    8'd165 : out_a_d3 = 55;
    8'd166 : out_a_d3 = 55;
    8'd167 : out_a_d3 = 55;
    8'd168 : out_a_d3 = 56;
    8'd169 : out_a_d3 = 56;
    8'd170 : out_a_d3 = 56;
    8'd171 : out_a_d3 = 57;
    8'd172 : out_a_d3 = 57;
    8'd173 : out_a_d3 = 57;
    8'd174 : out_a_d3 = 58;
    8'd175 : out_a_d3 = 58;
    8'd176 : out_a_d3 = 58;
    8'd177 : out_a_d3 = 59;
    8'd178 : out_a_d3 = 59;
    8'd179 : out_a_d3 = 59;
    8'd180 : out_a_d3 = 60;
    8'd181 : out_a_d3 = 60;
    8'd182 : out_a_d3 = 60;
    8'd183 : out_a_d3 = 61;
    8'd184 : out_a_d3 = 61;
    8'd185 : out_a_d3 = 61;
    8'd186 : out_a_d3 = 62;
    8'd187 : out_a_d3 = 62;
    8'd188 : out_a_d3 = 62;
    8'd189 : out_a_d3 = 63;
    8'd190 : out_a_d3 = 63;
    8'd191 : out_a_d3 = 63;
    8'd192 : out_a_d3 = 64;
    8'd193 : out_a_d3 = 64;
    8'd194 : out_a_d3 = 64;
    8'd195 : out_a_d3 = 65;
    8'd196 : out_a_d3 = 65;
    8'd197 : out_a_d3 = 65;
    8'd198 : out_a_d3 = 66;
    8'd199 : out_a_d3 = 66;
    8'd200 : out_a_d3 = 66;
    8'd201 : out_a_d3 = 67;
    8'd202 : out_a_d3 = 67;
    8'd203 : out_a_d3 = 67;
    8'd204 : out_a_d3 = 68;
    8'd205 : out_a_d3 = 68;
    8'd206 : out_a_d3 = 68;
    8'd207 : out_a_d3 = 69;
    8'd208 : out_a_d3 = 69;
    8'd209 : out_a_d3 = 69;
    8'd210 : out_a_d3 = 70;
    8'd211 : out_a_d3 = 70;
    8'd212 : out_a_d3 = 70;
    8'd213 : out_a_d3 = 71;
    8'd214 : out_a_d3 = 71;
    8'd215 : out_a_d3 = 71;
    8'd216 : out_a_d3 = 72;
    8'd217 : out_a_d3 = 72;
    8'd218 : out_a_d3 = 72;
    8'd219 : out_a_d3 = 73;
    8'd220 : out_a_d3 = 73;
    8'd221 : out_a_d3 = 73;
    8'd222 : out_a_d3 = 74;
    8'd223 : out_a_d3 = 74;
    8'd224 : out_a_d3 = 74;
    8'd225 : out_a_d3 = 75;
    8'd226 : out_a_d3 = 75;
    8'd227 : out_a_d3 = 75;
    8'd228 : out_a_d3 = 76;
    8'd229 : out_a_d3 = 76;
    8'd230 : out_a_d3 = 76;
    8'd231 : out_a_d3 = 77;
    8'd232 : out_a_d3 = 77;
    8'd233 : out_a_d3 = 77;
    8'd234 : out_a_d3 = 78;
    8'd235 : out_a_d3 = 78;
    8'd236 : out_a_d3 = 78;
    8'd237 : out_a_d3 = 79;
    8'd238 : out_a_d3 = 79;
    8'd239 : out_a_d3 = 79;
    8'd240 : out_a_d3 = 80;
    8'd241 : out_a_d3 = 80;
    8'd242 : out_a_d3 = 80;
    8'd243 : out_a_d3 = 81;
    8'd244 : out_a_d3 = 81;
    8'd245 : out_a_d3 = 81;
    8'd246 : out_a_d3 = 82;
    8'd247 : out_a_d3 = 82;
    8'd248 : out_a_d3 = 82;
    8'd249 : out_a_d3 = 83;
    8'd250 : out_a_d3 = 83;
    8'd251 : out_a_d3 = 83;
    8'd252 : out_a_d3 = 84;
    8'd253 : out_a_d3 = 84;
    8'd254 : out_a_d3 = 84;
    8'd255 : out_a_d3 = 85;
    default: out_a_d3 = 0;
  endcase
end

endmodule


module Vov (vgs_1,vds,res);

input [2:0] vgs_1;
input [2:0] vds;
output reg [7:0] res;

always @ (*) begin
case(vgs_1)
3'd0:
                case(vds)
                3'd0: res = 0;
                3'd1: res = 0;
                3'd2: res = 0;
                3'd3: res = 0;
                3'd4: res = 0;
                3'd5: res = 0;
                3'd6: res = 0;
                3'd7: res = 0;
                default: res = 0;
                endcase
3'd1:
                case(vds)
                3'd0: res = 0;
                3'd1: res = 2;
                3'd2: res = 4;
                3'd3: res = 6;
                3'd4: res = 8;
                3'd5: res = 10;
                3'd6: res = 12;
                3'd7: res = 14;
                default: res = 0;
                endcase
3'd2:
                case(vds)
                3'd0: res = 0;
                3'd1: res = 4;
                3'd2: res = 8;
                3'd3: res = 12;
                3'd4: res = 16;
                3'd5: res = 20;
                3'd6: res = 24;
                3'd7: res = 28;
                default: res = 0;
                endcase
3'd3:
                case(vds)
                3'd0: res = 0;
                3'd1: res = 6;
                3'd2: res = 12;
                3'd3: res = 18;
                3'd4: res = 24;
                3'd5: res = 30;
                3'd6: res = 36;
                3'd7: res = 42;
                default: res = 0;
                endcase
3'd4:
                case(vds)
                3'd0: res = 0;
                3'd1: res = 8;
                3'd2: res = 16;
                3'd3: res = 24;
                3'd4: res = 32;
                3'd5: res = 40;
                3'd6: res = 48;
                3'd7: res = 56;
                default: res = 0;
                endcase
3'd5:
                case(vds)
                3'd0: res = 0;
                3'd1: res = 10;
                3'd2: res = 20;
                3'd3: res = 30;
                3'd4: res = 40;
                3'd5: res = 50;
                3'd6: res = 60;
                3'd7: res = 70;
                default: res = 0;
                endcase
3'd6:
                case(vds)
                3'd0: res = 0;
                3'd1: res = 12;
                3'd2: res = 24;
                3'd3: res = 36;
                3'd4: res = 48;
                3'd5: res = 60;
                3'd6: res = 72;
                3'd7: res = 84;
                default: res = 0;
                endcase
default: res = 0;
endcase
end

endmodule

module Square (in,res);
input [2:0] in;
output reg [5:0] res;

always @ (*) begin
case(in)
        3'd0: res = 0;
        3'd1: res = 1;
        3'd2: res = 4;
        3'd3: res = 9;
        3'd4: res = 16;
        3'd5: res = 25;
        3'd6: res = 36;
        3'd7: res = 49;
        default: res = 0;
endcase

end

endmodule



module Calculate (w,vgs,vds,id,gm);
// input signal
input [2:0] w;
input [2:0] vgs;
input [2:0] vds;

// output signal
output wire [7:0] id;
output wire [7:0] gm;

// parameter

wire [2:0] vgs_1;
reg [7:0] temp_id;
reg [7:0] temp_gm;
wire [7:0] temp_gm_w_l;
wire [7:0] temp_gm_w_s;
wire [7:0] vov_res;
wire [5:0] vds_s;
wire [5:0] vgs_1_s;
wire [7:0] vov_vds;

// design
assign vgs_1 = vgs - 1;
assign id = temp_id;
assign gm = temp_gm;

Vov v0(vgs_1,vds,vov_res);
Square q0(vds,vds_s);
Square q1(vgs_1,vgs_1_s);

always @ (*) begin

if((vgs_1) > vds) begin
  temp_id = w * (vov_res - vds_s);
  temp_gm = 2*w*vds;
end

else begin
  temp_id =  (w *vgs_1_s);
  temp_gm = 2*w*vgs_1; 
end
end

endmodule


module merge_sort(in_0, in_1, in_2, in_3, in_4, in_5, mode, out_1, out_2, out_3);
    input [7:0] in_0;
    input [7:0] in_1;
    input [7:0] in_2;
    input [7:0] in_3;
    input [7:0] in_4;
    input [7:0] in_5;
    input mode;
    output reg [7:0] out_1;
    output reg [7:0] out_2;
    output reg [7:0] out_3;
    
    reg [7:0] inputs [5:0];
    reg [7:0] max [2:0];

    always @(*) begin
        // Initialize the input into arrays
        inputs[0] = in_0;
        inputs[1] = in_1;
        inputs[2] = in_2;
        inputs[3] = in_3;
        inputs[4] = in_4;
        inputs[5] = in_5;
        
        max[0] = 0;
        max[1] = 0;
        max[2] = 0;

        // Sort the input values
        for (int i = 0; i < 6; i = i + 1) begin
            if (inputs[i] > max[0]) begin
                max[2] = max[1];
                max[1] = max[0];
                max[0] = inputs[i];
            end
            else if (inputs[i] > max[1]) begin
                max[2] = max[1];
                max[1] = inputs[i];
            end
            else if (inputs[i] > max[2]) begin
                max[2] = inputs[i];
            end
        end

        // Output based on the mode
        if (mode == 0) begin
            out_1 = ~max[2];
            out_2 = ~max[1];
            out_3 = ~max[0];
        end
        else begin
            out_1 = max[0];
            out_2 = max[1];
            out_3 = max[2];
        end
    end
endmodule

// --------------------------------------------------
// Example for using submodule 
// BBQ bbq0(.meat(meat_0), .vagetable(vagetable_0), .water(water_0),.cost(cost[0]));
// --------------------------------------------------
// Example for continuous assignment
// assign out_n = XXX;
// --------------------------------------------------
// Example for procedure assignment
// always@(*) begin 
// 	out_n = XXX; 
// end
// --------------------------------------------------
// Example for case statement
// always @(*) begin
// 	case(op)
// 		2'b00: output_reg = a + b;
// 		2'b10: output_reg = a - b;
// 		2'b01: output_reg = a * b;
// 		2'b11: output_reg = a / b;
// 		default: output_reg = 0;
// 	endcase
// end
// --------------------------------------------------
