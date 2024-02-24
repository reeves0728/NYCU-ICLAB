//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output [IP_WIDTH*4-1:0] OUT_character;

// ===============================================================
// Design
// ===============================================================

generate
    if(IP_WIDTH == 3) 
    begin
        wire [3:0] index[0:2];
        wire [4:0] weight[0:2];
        wire [4:0] w[0:5];
        wire [3:0] i[0:5];

        assign index[0] = IN_character[3:0];
        assign index[1] = IN_character[7:4];
        assign index[2] = IN_character[11:8];
        assign weight[0] = IN_weight[4:0];
        assign weight[1] = IN_weight[9:5];
        assign weight[2] = IN_weight[14:10];   

        compare c0(.index_1(index[0]) ,.index_2(index[2]),.weight_1(weight[0]),.weight_2(weight[2]),.index_b(i[0]),.index_s(i[1]),.weight_b(w[0]), .weight_s(w[1]));
        compare c1(.index_1(i[0]) ,.index_2(index[1]),.weight_1(w[0]),.weight_2(weight[1]),.index_b(i[2]),.index_s(i[3]),.weight_b(w[2]), .weight_s(w[3]));
        compare c2(.index_1(i[3]) ,.index_2(i[1]),.weight_1(w[3]),.weight_2(w[1]),.index_b(i[4]),.index_s(i[5]),.weight_b(w[4]), .weight_s(w[5]));

        assign OUT_character = {i[2],i[4],i[5]};
    end

    else if(IP_WIDTH == 4)
    begin
        wire [3:0] index[0:3];
        wire [4:0] weight[0:3];

        wire [3:0] i[0:9];
        wire [4:0] w[0:9];

        assign index[0] = IN_character[3:0];
        assign index[1] = IN_character[7:4];
        assign index[2] = IN_character[11:8];
        assign index[3] = IN_character[15:12];

        assign weight[0] = IN_weight[4:0];
        assign weight[1] = IN_weight[9:5];
        assign weight[2] = IN_weight[14:10];
        assign weight[3] = IN_weight[19:15];

        compare c0(.index_1(index[0]) ,.index_2(index[2]),.weight_1(weight[0]),.weight_2(weight[2]),.index_b(i[0]),.index_s(i[2]),.weight_b(w[0]), .weight_s(w[2]));
        compare c1(.index_1(index[1]) ,.index_2(index[3]),.weight_1(weight[1]),.weight_2(weight[3]),.index_b(i[1]),.index_s(i[3]),.weight_b(w[1]), .weight_s(w[3]));

        compare c2(.index_1(i[0]) ,.index_2(i[1]),.weight_1(w[0]),.weight_2(w[1]),.index_b(i[4]),.index_s(i[5]),.weight_b(w[4]), .weight_s(w[5]));
        compare c3(.index_1(i[2]) ,.index_2(i[3]),.weight_1(w[2]),.weight_2(w[3]),.index_b(i[6]),.index_s(i[7]),.weight_b(w[6]), .weight_s(w[7]));

        compare c4(.index_1(i[5]) ,.index_2(i[6]),.weight_1(w[5]),.weight_2(w[6]),.index_b(i[8]),.index_s(i[9]),.weight_b(w[8]), .weight_s(w[9]));

        assign OUT_character = {i[4],i[8],i[9],i[7]};
    end

    else if(IP_WIDTH == 5)
    begin
        wire [3:0] index[0:4];
        wire [4:0] weight[0:4];
        wire [3:0] i[0:17];
        wire [4:0] w[0:17];

        assign index[0] = IN_character[3:0];
        assign index[1] = IN_character[7:4];
        assign index[2] = IN_character[11:8];
        assign index[3] = IN_character[15:12];
        assign index[4] = IN_character[19:16];

        assign weight[0] = IN_weight[4:0];
        assign weight[1] = IN_weight[9:5];
        assign weight[2] = IN_weight[14:10];
        assign weight[3] = IN_weight[19:15];
        assign weight[4] = IN_weight[24:20];

        compare c0(.index_1(index[0]) ,.index_2(index[3]),.weight_1(weight[0]),.weight_2(weight[3]),.index_b(i[0]),.index_s(i[2]),.weight_b(w[0]), .weight_s(w[2]));
        compare c1(.index_1(index[1]) ,.index_2(index[4]),.weight_1(weight[1]),.weight_2(weight[4]),.index_b(i[1]),.index_s(i[3]),.weight_b(w[1]), .weight_s(w[3]));

        compare c2(.index_1(i[0]) ,.index_2(index[2]),.weight_1(w[0]),.weight_2(weight[2]),.index_b(i[4]),.index_s(i[6]),.weight_b(w[4]), .weight_s(w[6]));
        compare c3(.index_1(i[1]) ,.index_2(i[2]),.weight_1(w[1]),.weight_2(w[2]),.index_b(i[5]),.index_s(i[7]),.weight_b(w[5]), .weight_s(w[7]));

        compare c4(.index_1(i[4]) ,.index_2(i[5]),.weight_1(w[4]),.weight_2(w[5]),.index_b(i[8]),.index_s(i[9]),.weight_b(w[8]), .weight_s(w[9]));
        compare c5(.index_1(i[6]) ,.index_2(i[3]),.weight_1(w[6]),.weight_2(w[3]),.index_b(i[10]),.index_s(i[11]),.weight_b(w[10]), .weight_s(w[11])); 

        compare c6(.index_1(i[9]) ,.index_2(i[10]),.weight_1(w[9]),.weight_2(w[10]),.index_b(i[12]),.index_s(i[13]),.weight_b(w[12]), .weight_s(w[13]));
        compare c7(.index_1(i[7]) ,.index_2(i[11]),.weight_1(w[7]),.weight_2(w[11]),.index_b(i[14]),.index_s(i[15]),.weight_b(w[14]), .weight_s(w[15])); 

        compare c8(.index_1(i[13]) ,.index_2(i[14]),.weight_1(w[13]),.weight_2(w[14]),.index_b(i[16]),.index_s(i[17]),.weight_b(w[16]), .weight_s(w[17]));    

        assign OUT_character = {i[8],i[12],i[16],i[17],i[15]};       
    end

    else if(IP_WIDTH == 6)
    begin
        wire [3:0] index[0:5];
        wire [4:0] weight[0:5];
        wire [3:0] i[0:23];
        wire [4:0] w[0:23];

        assign index[0] = IN_character[3:0];
        assign index[1] = IN_character[7:4];
        assign index[2] = IN_character[11:8];
        assign index[3] = IN_character[15:12];
        assign index[4] = IN_character[19:16];
        assign index[5] = IN_character[23:20];

        assign weight[0] = IN_weight[4:0];
        assign weight[1] = IN_weight[9:5];
        assign weight[2] = IN_weight[14:10];
        assign weight[3] = IN_weight[19:15];
        assign weight[4] = IN_weight[24:20];
        assign weight[5] = IN_weight[29:25];

        compare c0(.index_1(index[0]) ,.index_2(index[5]),.weight_1(weight[0]),.weight_2(weight[5]),.index_b(i[0]),.index_s(i[5]),.weight_b(w[0]), .weight_s(w[5]));
        compare c1(.index_1(index[1]) ,.index_2(index[3]),.weight_1(weight[1]),.weight_2(weight[3]),.index_b(i[1]),.index_s(i[3]),.weight_b(w[1]), .weight_s(w[3]));
        compare c2(.index_1(index[2]) ,.index_2(index[4]),.weight_1(weight[2]),.weight_2(weight[4]),.index_b(i[2]),.index_s(i[4]),.weight_b(w[2]), .weight_s(w[4]));

        compare c3(.index_1(i[1]) ,.index_2(i[2]),.weight_1(w[1]),.weight_2(w[2]),.index_b(i[6]),.index_s(i[7]),.weight_b(w[6]), .weight_s(w[7]));
        compare c4(.index_1(i[3]) ,.index_2(i[4]),.weight_1(w[3]),.weight_2(w[4]),.index_b(i[8]),.index_s(i[9]),.weight_b(w[8]), .weight_s(w[9]));

        compare c5(.index_1(i[0]) ,.index_2(i[8]),.weight_1(w[0]),.weight_2(w[8]),.index_b(i[10]),.index_s(i[12]),.weight_b(w[10]), .weight_s(w[12]));
        compare c6(.index_1(i[7]) ,.index_2(i[5]),.weight_1(w[7]),.weight_2(w[5]),.index_b(i[11]),.index_s(i[13]),.weight_b(w[11]), .weight_s(w[13]));

        compare c7(.index_1(i[10]) ,.index_2(i[6]),.weight_1(w[10]),.weight_2(w[6]),.index_b(i[14]),.index_s(i[15]),.weight_b(w[14]), .weight_s(w[15]));
        compare c8(.index_1(i[11]) ,.index_2(i[12]),.weight_1(w[11]),.weight_2(w[12]),.index_b(i[16]),.index_s(i[17]),.weight_b(w[16]), .weight_s(w[17]));
        compare c9(.index_1(i[9]) ,.index_2(i[13]),.weight_1(w[9]),.weight_2(w[13]),.index_b(i[18]),.index_s(i[19]),.weight_b(w[18]), .weight_s(w[19]));

        compare c10(.index_1(i[15]) ,.index_2(i[16]),.weight_1(w[15]),.weight_2(w[16]),.index_b(i[20]),.index_s(i[21]),.weight_b(w[20]), .weight_s(w[21]));
        compare c11(.index_1(i[17]) ,.index_2(i[18]),.weight_1(w[17]),.weight_2(w[18]),.index_b(i[22]),.index_s(i[23]),.weight_b(w[22]), .weight_s(w[23]));

        assign OUT_character = {i[14],i[20],i[21],i[22],i[23],i[19]};
    end

    else if(IP_WIDTH == 7)
    begin
        wire [3:0] index[0:6];
        wire [4:0] weight[0:6];
        wire [3:0] i[0:31];
        wire [4:0] w[0:31];

        assign index[0] = IN_character[3:0];
        assign index[1] = IN_character[7:4];
        assign index[2] = IN_character[11:8];
        assign index[3] = IN_character[15:12];
        assign index[4] = IN_character[19:16];
        assign index[5] = IN_character[23:20];
        assign index[6] = IN_character[27:24];

        assign weight[0] = IN_weight[4:0];
        assign weight[1] = IN_weight[9:5];
        assign weight[2] = IN_weight[14:10];
        assign weight[3] = IN_weight[19:15];
        assign weight[4] = IN_weight[24:20];
        assign weight[5] = IN_weight[29:25];
        assign weight[6] = IN_weight[34:30];

        compare c0(.index_1(index[0]) ,.index_2(index[6]),.weight_1(weight[0]),.weight_2(weight[6]),.index_b(i[0]),.index_s(i[1]),.weight_b(w[0]), .weight_s(w[1]));
        compare c1(.index_1(index[2]) ,.index_2(index[3]),.weight_1(weight[2]),.weight_2(weight[3]),.index_b(i[2]),.index_s(i[3]),.weight_b(w[2]), .weight_s(w[3]));
        compare c2(.index_1(index[4]) ,.index_2(index[5]),.weight_1(weight[4]),.weight_2(weight[5]),.index_b(i[4]),.index_s(i[5]),.weight_b(w[4]), .weight_s(w[5]));
        
        compare c3(.index_1(index[1]) ,.index_2(i[4]),.weight_1(weight[1]),.weight_2(w[4]),.index_b(i[6]),.index_s(i[7]),.weight_b(w[6]), .weight_s(w[7]));
        compare c4(.index_1(i[0]) ,.index_2(i[2]),.weight_1(w[0]),.weight_2(w[2]),.index_b(i[8]),.index_s(i[9]),.weight_b(w[8]), .weight_s(w[9]));
        compare c5(.index_1(i[3]) ,.index_2(i[1]),.weight_1(w[3]),.weight_2(w[1]),.index_b(i[10]),.index_s(i[11]),.weight_b(w[10]), .weight_s(w[11]));
        
        compare c6(.index_1(i[8]) ,.index_2(i[6]),.weight_1(w[8]),.weight_2(w[6]),.index_b(i[12]),.index_s(i[13]),.weight_b(w[12]), .weight_s(w[13]));
        compare c7(.index_1(i[10]) ,.index_2(i[7]),.weight_1(w[10]),.weight_2(w[7]),.index_b(i[14]),.index_s(i[15]),.weight_b(w[14]), .weight_s(w[15]));
        compare c8(.index_1(i[9]) ,.index_2(i[5]),.weight_1(w[9]),.weight_2(w[5]),.index_b(i[16]),.index_s(i[17]),.weight_b(w[16]), .weight_s(w[17]));
        
        compare c9(.index_1(i[13]) ,.index_2(i[16]),.weight_1(w[13]),.weight_2(w[16]),.index_b(i[18]),.index_s(i[19]),.weight_b(w[18]), .weight_s(w[19]));
        compare c10(.index_1(i[15]) ,.index_2(i[11]),.weight_1(w[15]),.weight_2(w[11]),.index_b(i[20]),.index_s(i[21]),.weight_b(w[20]), .weight_s(w[21]));
        
        compare c11(.index_1(i[19]) ,.index_2(i[14]),.weight_1(w[19]),.weight_2(w[14]),.index_b(i[22]),.index_s(i[23]),.weight_b(w[22]), .weight_s(w[23]));
        compare c12(.index_1(i[20]) ,.index_2(i[17]),.weight_1(w[20]),.weight_2(w[17]),.index_b(i[24]),.index_s(i[25]),.weight_b(w[24]), .weight_s(w[25]));
        
        compare c13(.index_1(i[18]) ,.index_2(i[22]),.weight_1(w[18]),.weight_2(w[22]),.index_b(i[26]),.index_s(i[27]),.weight_b(w[26]), .weight_s(w[27]));
        compare c14(.index_1(i[23]) ,.index_2(i[24]),.weight_1(w[23]),.weight_2(w[24]),.index_b(i[28]),.index_s(i[29]),.weight_b(w[28]), .weight_s(w[29]));
        compare c15(.index_1(i[25]) ,.index_2(i[21]),.weight_1(w[25]),.weight_2(w[21]),.index_b(i[30]),.index_s(i[31]),.weight_b(w[30]), .weight_s(w[31]));

        assign OUT_character = {i[12],i[26],i[27],i[28],i[29],i[30],i[31]};
    end

    else if(IP_WIDTH == 8)
    begin
        wire [3:0] index[7:0];
        wire [4:0] weight[7:0];
        wire [3:0] i[0:37];
        wire [4:0] w[0:37];

        assign index[0] = IN_character[3:0];
        assign index[1] = IN_character[7:4];
        assign index[2] = IN_character[11:8];
        assign index[3] = IN_character[15:12];
        assign index[4] = IN_character[19:16];
        assign index[5] = IN_character[23:20];
        assign index[6] = IN_character[27:24];
        assign index[7] = IN_character[31:28];

        assign weight[0] = IN_weight[4:0];
        assign weight[1] = IN_weight[9:5];
        assign weight[2] = IN_weight[14:10];
        assign weight[3] = IN_weight[19:15];
        assign weight[4] = IN_weight[24:20];
        assign weight[5] = IN_weight[29:25];
        assign weight[6] = IN_weight[34:30];
        assign weight[7] = IN_weight[39:35];

        compare c0(.index_1(index[1]) ,.index_2(index[3]),.weight_1(weight[1]),.weight_2(weight[3]),.index_b(i[0]),.index_s(i[1]),.weight_b(w[0]), .weight_s(w[1]));
        compare c1(.index_1(index[4]) ,.index_2(index[6]),.weight_1(weight[4]),.weight_2(weight[6]),.index_b(i[2]),.index_s(i[3]),.weight_b(w[2]), .weight_s(w[3]));
        compare c2(.index_1(index[0]) ,.index_2(index[2]),.weight_1(weight[0]),.weight_2(weight[2]),.index_b(i[4]),.index_s(i[5]),.weight_b(w[4]), .weight_s(w[5]));
        compare c3(.index_1(index[5]) ,.index_2(index[7]),.weight_1(weight[5]),.weight_2(weight[7]),.index_b(i[6]),.index_s(i[7]),.weight_b(w[6]), .weight_s(w[7]));

        compare c4(.index_1(i[4]) ,.index_2(i[2]),.weight_1(w[4]),.weight_2(w[2]),.index_b(i[8]),.index_s(i[9]),.weight_b(w[8]), .weight_s(w[9]));
        compare c5(.index_1(i[0]) ,.index_2(i[6]),.weight_1(w[0]),.weight_2(w[6]),.index_b(i[10]),.index_s(i[11]),.weight_b(w[10]), .weight_s(w[11]));     
        compare c6(.index_1(i[5]) ,.index_2(i[3]),.weight_1(w[5]),.weight_2(w[3]),.index_b(i[12]),.index_s(i[13]),.weight_b(w[12]), .weight_s(w[13]));
        compare c7(.index_1(i[1]) ,.index_2(i[7]),.weight_1(w[1]),.weight_2(w[7]),.index_b(i[14]),.index_s(i[15]),.weight_b(w[14]), .weight_s(w[15]));

        compare c8(.index_1(i[8]) ,.index_2(i[10]),.weight_1(w[8]),.weight_2(w[10]),.index_b(i[16]),.index_s(i[17]),.weight_b(w[16]), .weight_s(w[17]));
        compare c9(.index_1(i[12]) ,.index_2(i[14]),.weight_1(w[12]),.weight_2(w[14]),.index_b(i[18]),.index_s(i[19]),.weight_b(w[18]), .weight_s(w[19]));
        compare c10(.index_1(i[9]) ,.index_2(i[11]),.weight_1(w[9]),.weight_2(w[11]),.index_b(i[20]),.index_s(i[21]),.weight_b(w[20]), .weight_s(w[21]));
        compare c11(.index_1(i[13]) ,.index_2(i[15]),.weight_1(w[13]),.weight_2(w[15]),.index_b(i[22]),.index_s(i[23]),.weight_b(w[22]), .weight_s(w[23]));

        compare c12(.index_1(i[18]) ,.index_2(i[20]),.weight_1(w[18]),.weight_2(w[20]),.index_b(i[24]),.index_s(i[25]),.weight_b(w[24]), .weight_s(w[25]));
        compare c13(.index_1(i[19]) ,.index_2(i[21]),.weight_1(w[19]),.weight_2(w[21]),.index_b(i[26]),.index_s(i[27]),.weight_b(w[26]), .weight_s(w[27]));
        compare c14(.index_1(i[17]) ,.index_2(i[25]),.weight_1(w[17]),.weight_2(w[25]),.index_b(i[28]),.index_s(i[29]),.weight_b(w[28]), .weight_s(w[29]));
        compare c15(.index_1(i[26]) ,.index_2(i[22]),.weight_1(w[26]),.weight_2(w[22]),.index_b(i[30]),.index_s(i[31]),.weight_b(w[30]), .weight_s(w[31]));

        compare c16(.index_1(i[28]) ,.index_2(i[24]),.weight_1(w[28]),.weight_2(w[24]),.index_b(i[32]),.index_s(i[33]),.weight_b(w[32]), .weight_s(w[33]));
        compare c17(.index_1(i[30]) ,.index_2(i[29]),.weight_1(w[30]),.weight_2(w[29]),.index_b(i[34]),.index_s(i[35]),.weight_b(w[34]), .weight_s(w[35]));
        compare c18(.index_1(i[27]) ,.index_2(i[31]),.weight_1(w[27]),.weight_2(w[31]),.index_b(i[36]),.index_s(i[37]),.weight_b(w[36]), .weight_s(w[37]));

        assign OUT_character = {i[16],i[32],i[33],i[34],i[35],i[36],i[37],i[23]};
    end

    else
    begin
        wire [3:0] index[0:2];
        wire [4:0] weight[0:2];
        wire [4:0] w[0:5];
        wire [3:0] i[0:5];

        assign index[0] = IN_character[3:0];
        assign index[1] = IN_character[7:4];
        assign index[2] = IN_character[11:8];
        assign weight[0] = IN_weight[4:0];
        assign weight[1] = IN_weight[9:5];
        assign weight[2] = IN_weight[14:10];   

        compare c0(.index_1(index[0]) ,.index_2(index[2]),.weight_1(weight[0]),.weight_2(weight[2]),.index_b(i[0]),.index_s(i[1]),.weight_b(w[0]), .weight_s(w[1]));
        compare c1(.index_1(i[0]) ,.index_2(index[1]),.weight_1(w[0]),.weight_2(weight[1]),.index_b(i[2]),.index_s(i[3]),.weight_b(w[2]), .weight_s(w[3]));
        compare c2(.index_1(i[3]) ,.index_2(i[1]),.weight_1(w[3]),.weight_2(w[1]),.index_b(i[4]),.index_s(i[5]),.weight_b(w[4]), .weight_s(w[5]));

        assign OUT_character = {i[2],i[4],i[5]};
    end
endgenerate
endmodule

module compare(
   index_1, 
   index_2,
   weight_1,
   weight_2,
   //output
   index_b,
   index_s,
   weight_b,
   weight_s
);

input [3:0] index_1;
input [3:0] index_2;
input [4:0] weight_1;
input [4:0] weight_2;

output reg [3:0] index_b;
output reg [3:0] index_s;
output reg [4:0] weight_b;
output reg [4:0] weight_s;


always @ (*)
begin
    if(weight_1 > weight_2 || (weight_1 == weight_2 && index_1 > index_2))
    begin
        index_b = index_1;
        index_s = index_2;
        weight_b = weight_1;
        weight_s = weight_2;
    end

    else
    begin
        index_b = index_2;
        index_s = index_1;
        weight_b = weight_2;
        weight_s = weight_1;
    end
end
endmodule