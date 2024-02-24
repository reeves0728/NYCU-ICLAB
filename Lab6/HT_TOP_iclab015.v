//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

// synopsys translate_off
`include "SORT_IP.v"
// synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
reg [31:0] IN_character, OUT_character;
reg [39:0] IN_weight;
reg [4:0] weight_reg [0:15];
reg [3:0] current_state, next_state;
reg [3:0] input_cnt;
reg out_mode_reg;
reg mask_add[1:6][14:7];
reg [31:0] temp_out;
reg [2:0] build_cnt;
reg [2:0] out_len [14:7];
reg [6:0] huffman_out [14:7];
reg [2:0] out_cnt;



integer i;
integer j;
parameter IDLE = 0;
parameter INPUT = 1;
parameter BUILD = 2;
// parameter OUTPUT = 3;
parameter A = 3;
parameter B = 4;
parameter C = 5;
parameter E = 6;
parameter I = 7;
parameter L = 8;
parameter O = 9;
parameter V = 10;
parameter shift = 11;

SORT_IP #(8) s0(.IN_character(IN_character),.IN_weight(IN_weight),.OUT_character(OUT_character));

// ===============================================================
// Design
// ===============================================================
// FSM
always @ (*)
begin
    next_state = current_state;
    case(current_state)
        IDLE:
        begin
            if(in_valid == 1'b1) next_state = INPUT;
            else next_state = IDLE;
        end
        INPUT:
        begin
            if(input_cnt == 6) next_state = BUILD;
            else next_state = INPUT;
        end

        BUILD:
        begin
            if(build_cnt == 0) next_state = I;
            else next_state = BUILD;
        end

        // shift:
        // begin
        //     next_state = I;
        // end

        I:
        begin
            if(out_cnt == out_len[10] - 1) 
            begin
                if(out_mode_reg == 1) next_state = C;
                else next_state = L;
            end
            else next_state = I;
        end

        C:
        begin
            if(out_cnt == out_len[12] - 1) next_state = L;
            else next_state = C;
        end

        L:
        begin
            if(out_cnt == out_len[9] - 1) 
            begin
                if(out_mode_reg == 1) next_state = A;
                else next_state = O;
            end
            else next_state = L;
        end

        A:
        begin
            if(out_cnt == out_len[14]-1) next_state = B;
            else next_state = A;
        end

        B:
        begin
            if(out_cnt == out_len[13]-1) next_state = IDLE;
            else next_state = B;
        end

        O:
        begin
            if(out_cnt == out_len[8]-1) next_state = V;
            else next_state = O;
        end

        V:
        begin
            if(out_cnt == out_len[7]-1) next_state = E;
            else next_state = V;
        end

        E:
        begin
            if(out_cnt == out_len[11]-1) next_state = IDLE;
            else next_state = E;
        end
    endcase
end

// out_code
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) out_code <= 0;
    else
    begin
        if(current_state == IDLE) out_code <= 0;
        else if(current_state == I) out_code <= huffman_out[10][out_cnt];
        else if(current_state == C) out_code <= huffman_out[12][out_cnt];
        else if(current_state == L) out_code <= huffman_out[9][out_cnt];
        else if(current_state == A) out_code <= huffman_out[14][out_cnt];
        else if(current_state == B) out_code <= huffman_out[13][out_cnt];
        else if(current_state == O) out_code <= huffman_out[8][out_cnt];
        else if(current_state == V) out_code <= huffman_out[7][out_cnt];
        else if(current_state == E) out_code <= huffman_out[11][out_cnt];
    end
end

// out_valid
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) out_valid <= 0;
    else
    begin
        if(current_state == IDLE) out_valid <= 0;
        else if(current_state == I) out_valid <= 1;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) out_cnt <= 0;
    else
    begin
        if(current_state == IDLE) out_cnt <= 0;

        else if(current_state == I)
        begin
         if(out_cnt ==  out_len[10] -1) out_cnt <= 0;
         else out_cnt <= out_cnt + 1;
        end

        else if(current_state == C)
        begin
         if(out_cnt ==  out_len[12] -1) out_cnt <= 0;
         else out_cnt <= out_cnt + 1;
        end

        else if(current_state == L)
        begin
         if(out_cnt ==  out_len[9] -1) out_cnt <= 0;
         else out_cnt <= out_cnt + 1;
        end

        else if(current_state == A)
        begin
         if(out_cnt ==  out_len[14] -1) out_cnt <= 0;
         else out_cnt <= out_cnt + 1;
        end

        else if(current_state == B)
        begin
         if(out_cnt ==  out_len[13] -1) out_cnt <= 0;
         else out_cnt <= out_cnt + 1;
        end

        else if(current_state == O)
        begin
         if(out_cnt ==  out_len[8] -1) out_cnt <= 0;
         else out_cnt <= out_cnt + 1;
        end

        else if(current_state == V)
        begin
         if(out_cnt ==  out_len[7] -1) out_cnt <= 0;
         else out_cnt <= out_cnt + 1;
        end

        else if(current_state == E)
        begin
         if(out_cnt ==  out_len[11] -1) out_cnt <= 0;
         else out_cnt <= out_cnt + 1;
        end
    end
end

//IN_weight
always @ (*)
begin
    IN_weight = 0;
    // if(next_state == BUILD || current_state == BUILD)
    // begin
    if(build_cnt == 6) IN_weight = {weight_reg[14],weight_reg[13],weight_reg[12],weight_reg[11],weight_reg[10],weight_reg[9],weight_reg[8],weight_reg[7]};
    else IN_weight = {weight_reg[temp_out[31:28]],weight_reg[temp_out[27:24]], weight_reg[temp_out[23:20]], weight_reg[temp_out[19:16]], weight_reg[temp_out[15:12]], weight_reg[temp_out[11:8]], weight_reg[temp_out[7:4]], weight_reg[temp_out[3:0]]};
    // end
end

// IN_character
always @ (*)
begin
    IN_character = 0;
    // if(next_state == BUILD || current_state == BUILD)
    // begin
        case(build_cnt)
            6: IN_character = {4'd14,4'd13,4'd12,4'd11,4'd10,4'd9,4'd8,4'd7};
            5: IN_character = temp_out;
            4: IN_character = temp_out;
            3: IN_character = temp_out;
            2: IN_character = temp_out;
            1: IN_character = temp_out;
            0: IN_character = temp_out;  
        endcase 
    // end
end




// temp_out
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) temp_out <= 0;
    else
    begin
        if(next_state == IDLE) temp_out <= 0;
        else if(next_state == BUILD || current_state == BUILD)
        begin
            case(build_cnt)
            6: temp_out <= {OUT_character[31:8],4'd6,4'd15};
            5: temp_out <= {OUT_character[27:8],4'd5,4'd15,4'd15};
            4: temp_out <= {OUT_character[23:8],4'd4,4'd15,4'd15,4'd15};
            3: temp_out <= {OUT_character[19:8],4'd3,4'd15,4'd15,4'd15,4'd15};
            2: temp_out <= {OUT_character[15:8],4'd2,4'd15,4'd15,4'd15,4'd15,4'd15};
            1: temp_out <= {OUT_character[11:8],4'd1,4'd15,4'd15,4'd15,4'd15,4'd15,4'd15};
            endcase
        end
    end
end

// mask_add
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0;i<7;i=i+1)
            for(j=7;j<15;j=j+1)
                mask_add[i][j] <= 0;
    end

    else
    begin
        if(next_state == IDLE)
        begin
            for(i=0;i<7;i=i+1)
                for(j=7;j<15;j=j+1)
                    mask_add[i][j] <= 0;
        end

        else if(next_state == BUILD || current_state == BUILD)
        begin
            if(build_cnt >= 1)
            begin

            if(OUT_character[3:0] >= 7 && OUT_character[7:4] >= 7)
            begin
                mask_add[build_cnt][OUT_character[3:0]] <= 1;
                mask_add[build_cnt][OUT_character[7:4]] <= 1; 
            end
            else if(OUT_character[3:0] < 7 && OUT_character[7:4] < 7)
            begin
                for(i=7;i<15;i=i+1)
                begin
                    mask_add[build_cnt][i] <= mask_add[OUT_character[3:0]][i] | mask_add[OUT_character[7:4]][i];
                end
            end

            else if(OUT_character[3:0] < 7 && OUT_character[7:4]>=7)
            begin
                case(OUT_character[7:4])
                    7:
                    begin
                        mask_add[build_cnt][7] <= 1;
                        mask_add[build_cnt][8] <= mask_add[OUT_character[3:0]][8];   
                        mask_add[build_cnt][9] <= mask_add[OUT_character[3:0]][9];    
                        mask_add[build_cnt][10] <= mask_add[OUT_character[3:0]][10]; 
                        mask_add[build_cnt][11] <= mask_add[OUT_character[3:0]][11];   
                        mask_add[build_cnt][12] <= mask_add[OUT_character[3:0]][12];    
                        mask_add[build_cnt][13] <= mask_add[OUT_character[3:0]][13];    
                        mask_add[build_cnt][14] <= mask_add[OUT_character[3:0]][14];                     
                    end
                    8:
                    begin
                        mask_add[build_cnt][8] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[3:0]][7];   
                        mask_add[build_cnt][9] <= mask_add[OUT_character[3:0]][9];    
                        mask_add[build_cnt][10] <= mask_add[OUT_character[3:0]][10]; 
                        mask_add[build_cnt][11] <= mask_add[OUT_character[3:0]][11];   
                        mask_add[build_cnt][12] <= mask_add[OUT_character[3:0]][12];    
                        mask_add[build_cnt][13] <= mask_add[OUT_character[3:0]][13];    
                        mask_add[build_cnt][14] <= mask_add[OUT_character[3:0]][14];   
                    end

                    9:
                    begin
                        mask_add[build_cnt][9] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[3:0]][7];   
                        mask_add[build_cnt][8] <= mask_add[OUT_character[3:0]][8];    
                        mask_add[build_cnt][10] <= mask_add[OUT_character[3:0]][10]; 
                        mask_add[build_cnt][11] <= mask_add[OUT_character[3:0]][11];   
                        mask_add[build_cnt][12] <= mask_add[OUT_character[3:0]][12];    
                        mask_add[build_cnt][13] <= mask_add[OUT_character[3:0]][13];    
                        mask_add[build_cnt][14] <= mask_add[OUT_character[3:0]][14];   
                    end

                    10:
                    begin
                        mask_add[build_cnt][10] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[3:0]][7];   
                        mask_add[build_cnt][8] <= mask_add[OUT_character[3:0]][8];    
                        mask_add[build_cnt][9] <= mask_add[OUT_character[3:0]][9]; 
                        mask_add[build_cnt][11] <= mask_add[OUT_character[3:0]][11];   
                        mask_add[build_cnt][12] <= mask_add[OUT_character[3:0]][12];    
                        mask_add[build_cnt][13] <= mask_add[OUT_character[3:0]][13];    
                        mask_add[build_cnt][14] <= mask_add[OUT_character[3:0]][14];   
                    end

                    11:
                    begin
                        mask_add[build_cnt][11] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[3:0]][7];   
                        mask_add[build_cnt][8] <= mask_add[OUT_character[3:0]][8];    
                        mask_add[build_cnt][9] <= mask_add[OUT_character[3:0]][9]; 
                        mask_add[build_cnt][10] <= mask_add[OUT_character[3:0]][10];   
                        mask_add[build_cnt][12] <= mask_add[OUT_character[3:0]][12];    
                        mask_add[build_cnt][13] <= mask_add[OUT_character[3:0]][13];    
                        mask_add[build_cnt][14] <= mask_add[OUT_character[3:0]][14];   
                    end

                    12:
                    begin
                        mask_add[build_cnt][12] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[3:0]][7];   
                        mask_add[build_cnt][8] <= mask_add[OUT_character[3:0]][8];    
                        mask_add[build_cnt][9] <= mask_add[OUT_character[3:0]][9]; 
                        mask_add[build_cnt][10] <= mask_add[OUT_character[3:0]][10];   
                        mask_add[build_cnt][11] <= mask_add[OUT_character[3:0]][11];    
                        mask_add[build_cnt][13] <= mask_add[OUT_character[3:0]][13];    
                        mask_add[build_cnt][14] <= mask_add[OUT_character[3:0]][14];   
                    end

                    13:
                    begin
                        mask_add[build_cnt][13] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[3:0]][7];   
                        mask_add[build_cnt][8] <= mask_add[OUT_character[3:0]][8];    
                        mask_add[build_cnt][9] <= mask_add[OUT_character[3:0]][9]; 
                        mask_add[build_cnt][10] <= mask_add[OUT_character[3:0]][10];   
                        mask_add[build_cnt][11] <= mask_add[OUT_character[3:0]][11];    
                        mask_add[build_cnt][12] <= mask_add[OUT_character[3:0]][12];    
                        mask_add[build_cnt][14] <= mask_add[OUT_character[3:0]][14];   
                    end

                    14:
                    begin
                        mask_add[build_cnt][14] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[3:0]][7];   
                        mask_add[build_cnt][8] <= mask_add[OUT_character[3:0]][8];    
                        mask_add[build_cnt][9] <= mask_add[OUT_character[3:0]][9]; 
                        mask_add[build_cnt][10] <= mask_add[OUT_character[3:0]][10];   
                        mask_add[build_cnt][11] <= mask_add[OUT_character[3:0]][11];    
                        mask_add[build_cnt][12] <= mask_add[OUT_character[3:0]][12];    
                        mask_add[build_cnt][13] <= mask_add[OUT_character[3:0]][13];   
                    end
                endcase 
            end

            else if(OUT_character[3:0] >= 7 && OUT_character[7:4]<7)
            begin
                case(OUT_character[3:0])
                    7:
                    begin
                        mask_add[build_cnt][7] <= 1;

                        mask_add[build_cnt][8] <= mask_add[OUT_character[7:4]][8];
                        mask_add[build_cnt][9] <= mask_add[OUT_character[7:4]][9];
                        mask_add[build_cnt][10] <= mask_add[OUT_character[7:4]][10];
                        mask_add[build_cnt][11] <= mask_add[OUT_character[7:4]][11];
                        mask_add[build_cnt][12] <= mask_add[OUT_character[7:4]][12];
                        mask_add[build_cnt][13] <= mask_add[OUT_character[7:4]][13];
                        mask_add[build_cnt][14] <= mask_add[OUT_character[7:4]][14];
                    end

                    8:
                    begin
                        mask_add[build_cnt][8] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[7:4]][7];
                        mask_add[build_cnt][9] <= mask_add[OUT_character[7:4]][9];
                        mask_add[build_cnt][10] <= mask_add[OUT_character[7:4]][10];
                        mask_add[build_cnt][11] <= mask_add[OUT_character[7:4]][11];
                        mask_add[build_cnt][12] <= mask_add[OUT_character[7:4]][12];
                        mask_add[build_cnt][13] <= mask_add[OUT_character[7:4]][13];
                        mask_add[build_cnt][14] <= mask_add[OUT_character[7:4]][14];

                    end

                    9:
                    begin
                        mask_add[build_cnt][9] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[7:4]][7];
                        mask_add[build_cnt][8] <= mask_add[OUT_character[7:4]][8];
                        mask_add[build_cnt][10] <= mask_add[OUT_character[7:4]][10];
                        mask_add[build_cnt][11] <= mask_add[OUT_character[7:4]][11];
                        mask_add[build_cnt][12] <= mask_add[OUT_character[7:4]][12];
                        mask_add[build_cnt][13] <= mask_add[OUT_character[7:4]][13];
                        mask_add[build_cnt][14] <= mask_add[OUT_character[7:4]][14];

                    end

                    10:
                    begin
                        mask_add[build_cnt][10] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[7:4]][7];
                        mask_add[build_cnt][8] <= mask_add[OUT_character[7:4]][8];
                        mask_add[build_cnt][9] <= mask_add[OUT_character[7:4]][9];
                        mask_add[build_cnt][11] <= mask_add[OUT_character[7:4]][11];
                        mask_add[build_cnt][12] <= mask_add[OUT_character[7:4]][12];
                        mask_add[build_cnt][13] <= mask_add[OUT_character[7:4]][13];
                        mask_add[build_cnt][14] <= mask_add[OUT_character[7:4]][14];

                    end

                    11:
                    begin
                        mask_add[build_cnt][11] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[7:4]][7];
                        mask_add[build_cnt][8] <= mask_add[OUT_character[7:4]][8];
                        mask_add[build_cnt][9] <= mask_add[OUT_character[7:4]][9];
                        mask_add[build_cnt][10] <= mask_add[OUT_character[7:4]][10];
                        mask_add[build_cnt][12] <= mask_add[OUT_character[7:4]][12];
                        mask_add[build_cnt][13] <= mask_add[OUT_character[7:4]][13];
                        mask_add[build_cnt][14] <= mask_add[OUT_character[7:4]][14];

                    end

                    12:
                    begin
                        mask_add[build_cnt][12] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[7:4]][7];
                        mask_add[build_cnt][8] <= mask_add[OUT_character[7:4]][8];
                        mask_add[build_cnt][9] <= mask_add[OUT_character[7:4]][9];
                        mask_add[build_cnt][10] <= mask_add[OUT_character[7:4]][10];
                        mask_add[build_cnt][11] <= mask_add[OUT_character[7:4]][11];
                        mask_add[build_cnt][13] <= mask_add[OUT_character[7:4]][13];
                        mask_add[build_cnt][14] <= mask_add[OUT_character[7:4]][14];

                    end

                    13:
                    begin
                        mask_add[build_cnt][13] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[7:4]][7];
                        mask_add[build_cnt][8] <= mask_add[OUT_character[7:4]][8];
                        mask_add[build_cnt][9] <= mask_add[OUT_character[7:4]][9];
                        mask_add[build_cnt][10] <= mask_add[OUT_character[7:4]][10];
                        mask_add[build_cnt][11] <= mask_add[OUT_character[7:4]][11];
                        mask_add[build_cnt][12] <= mask_add[OUT_character[7:4]][12];
                        mask_add[build_cnt][14] <= mask_add[OUT_character[7:4]][14];

                    end

                    14:
                    begin
                        mask_add[build_cnt][14] <= 1;

                        mask_add[build_cnt][7] <= mask_add[OUT_character[7:4]][7];
                        mask_add[build_cnt][8] <= mask_add[OUT_character[7:4]][8];
                        mask_add[build_cnt][9] <= mask_add[OUT_character[7:4]][9];
                        mask_add[build_cnt][10] <= mask_add[OUT_character[7:4]][10];
                        mask_add[build_cnt][11] <= mask_add[OUT_character[7:4]][11];
                        mask_add[build_cnt][12] <= mask_add[OUT_character[7:4]][12];
                        mask_add[build_cnt][13] <= mask_add[OUT_character[7:4]][13];
                    end
                endcase
            end

            end

        end
    end
end

// huffman_out
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=7;i<15;i=i+1)
            huffman_out[i] <= 0;
    end

    else
    begin
        if(current_state == IDLE) 
        begin
            for(i=7;i<15;i=i+1)
                huffman_out[i] <= 0;
        end

        else if (next_state == BUILD || current_state == BUILD)
        begin
            if(OUT_character[7:4] >= 7 && OUT_character[3:0] >= 7)
            begin
                huffman_out[OUT_character[7:4]] <= {huffman_out[OUT_character[7:4]][5:0],1'b0};
                huffman_out[OUT_character[3:0]] <= {huffman_out[OUT_character[3:0]][5:0],1'b1};
            end

            else if(OUT_character[7:4] >= 7 && OUT_character[3:0] < 7)
            begin
                if(OUT_character[7:4] == 7) huffman_out[7] <= {huffman_out[7][5:0],1'b0};
                else
                begin
                    if(mask_add[OUT_character[3:0]][7] == 1) huffman_out[7] <= {huffman_out[7][5:0] , 1'b1};
                end

                if(OUT_character[7:4] == 8) huffman_out[8] <= {huffman_out[8][5:0],1'b0};
                else
                begin
                    if(mask_add[OUT_character[3:0]][8] == 1) huffman_out[8] <= {huffman_out[8][5:0] , 1'b1};
                end

                if(OUT_character[7:4] == 9) huffman_out[9] <= {huffman_out[9][5:0],1'b0};
                else
                begin
                    if(mask_add[OUT_character[3:0]][9] == 1) huffman_out[9] <= {huffman_out[9][5:0] , 1'b1};
                end

                if(OUT_character[7:4] == 10) huffman_out[10] <= {huffman_out[10][5:0],1'b0};
                else
                begin
                    if(mask_add[OUT_character[3:0]][10] == 1) huffman_out[10] <= {huffman_out[10][5:0] , 1'b1};
                end

                if(OUT_character[7:4] == 11) huffman_out[11] <= {huffman_out[11][5:0],1'b0};
                else
                begin
                    if(mask_add[OUT_character[3:0]][11] == 1) huffman_out[11] <= {huffman_out[11][5:0] , 1'b1};
                end

                if(OUT_character[7:4] == 12) huffman_out[12] <= {huffman_out[12][5:0],1'b0};
                else
                begin
                    if(mask_add[OUT_character[3:0]][12] == 1) huffman_out[12] <= {huffman_out[12][5:0] , 1'b1};
                end

                if(OUT_character[7:4] == 13) huffman_out[13] <= {huffman_out[13][5:0],1'b0};
                else
                begin
                    if(mask_add[OUT_character[3:0]][13] == 1) huffman_out[13] <= {huffman_out[13][5:0] , 1'b1};
                end

                if(OUT_character[7:4] == 14) huffman_out[14] <= {huffman_out[14][5:0],1'b0};
                else
                begin
                    if(mask_add[OUT_character[3:0]][14] == 1) huffman_out[14] <= {huffman_out[14][5:0] , 1'b1};
                end
            end

            else if(OUT_character[7:4] <7 && OUT_character[3:0] >= 7)
            begin
                if(OUT_character[3:0] == 7) huffman_out[7] <= {huffman_out[7][5:0],1'b1};
                else
                begin
                    if(mask_add[OUT_character[7:4]][7] == 1) huffman_out[7] <= {huffman_out[7][5:0],1'b0}; 
                end

                if(OUT_character[3:0] == 8) huffman_out[8] <= {huffman_out[8][5:0],1'b1};
                else
                begin
                    if(mask_add[OUT_character[7:4]][8] == 1) huffman_out[8] <= {huffman_out[8][5:0],1'b0}; 
                end

                if(OUT_character[3:0] == 9) huffman_out[9] <= {huffman_out[9][5:0],1'b1};
                else
                begin
                    if(mask_add[OUT_character[7:4]][9] == 1) huffman_out[9] <= {huffman_out[9][5:0],1'b0}; 
                end

                if(OUT_character[3:0] == 10) huffman_out[10] <= {huffman_out[10][5:0],1'b1};
                else
                begin
                    if(mask_add[OUT_character[7:4]][10] == 1) huffman_out[10] <= {huffman_out[10][5:0],1'b0}; 
                end

                if(OUT_character[3:0] == 11) huffman_out[11] <= {huffman_out[11][5:0],1'b1};
                else
                begin
                    if(mask_add[OUT_character[7:4]][11] == 1) huffman_out[11] <= {huffman_out[11][5:0],1'b0}; 
                end

                if(OUT_character[3:0] == 12) huffman_out[12] <= {huffman_out[12][5:0],1'b1};
                else
                begin
                    if(mask_add[OUT_character[7:4]][12] == 1) huffman_out[12] <= {huffman_out[12][5:0],1'b0}; 
                end

                if(OUT_character[3:0] == 13) huffman_out[13] <= {huffman_out[13][5:0],1'b1};
                else
                begin
                    if(mask_add[OUT_character[7:4]][13] == 1) huffman_out[13] <= {huffman_out[13][5:0],1'b0}; 
                end

                if(OUT_character[3:0] == 14) huffman_out[14] <= {huffman_out[14][5:0],1'b1};
                else
                begin
                    if(mask_add[OUT_character[7:4]][14] == 1) huffman_out[14] <= {huffman_out[14][5:0],1'b0}; 
                end
            end

            else
            begin
                if(mask_add[OUT_character[7:4]][7] == 1 && mask_add[OUT_character[3:0]][7] == 0) huffman_out[7] <= {huffman_out[7][5:0],1'b0};
                else if(mask_add[OUT_character[7:4]][7] == 0 && mask_add[OUT_character[3:0]][7] == 1) huffman_out[7] <= {huffman_out[7][5:0],1'b1};

                if(mask_add[OUT_character[7:4]][8] == 1 && mask_add[OUT_character[3:0]][8] == 0) huffman_out[8] <= {huffman_out[8][5:0],1'b0};
                else if(mask_add[OUT_character[7:4]][8] == 0 && mask_add[OUT_character[3:0]][8] == 1) huffman_out[8] <= {huffman_out[8][5:0],1'b1};

                if(mask_add[OUT_character[7:4]][9] == 1 && mask_add[OUT_character[3:0]][9] == 0) huffman_out[9] <= {huffman_out[9][5:0],1'b0};
                else if(mask_add[OUT_character[7:4]][9] == 0 && mask_add[OUT_character[3:0]][9] == 1) huffman_out[9] <= {huffman_out[9][5:0],1'b1};

                if(mask_add[OUT_character[7:4]][10] == 1 && mask_add[OUT_character[3:0]][10] == 0) huffman_out[10] <= {huffman_out[10][5:0],1'b0};
                else if(mask_add[OUT_character[7:4]][10] == 0 && mask_add[OUT_character[3:0]][10] == 1) huffman_out[10] <= {huffman_out[10][5:0],1'b1};

                if(mask_add[OUT_character[7:4]][11] == 1 && mask_add[OUT_character[3:0]][11] == 0) huffman_out[11] <= {huffman_out[11][5:0],1'b0};
                else if(mask_add[OUT_character[7:4]][11] == 0 && mask_add[OUT_character[3:0]][11] == 1) huffman_out[11] <= {huffman_out[11][5:0],1'b1};

                if(mask_add[OUT_character[7:4]][12] == 1 && mask_add[OUT_character[3:0]][12] == 0) huffman_out[12] <= {huffman_out[12][5:0],1'b0};
                else if(mask_add[OUT_character[7:4]][12] == 0 && mask_add[OUT_character[3:0]][12] == 1) huffman_out[12] <= {huffman_out[12][5:0],1'b1};

                if(mask_add[OUT_character[7:4]][13] == 1 && mask_add[OUT_character[3:0]][13] == 0) huffman_out[13] <= {huffman_out[13][5:0],1'b0};
                else if(mask_add[OUT_character[7:4]][13] == 0 && mask_add[OUT_character[3:0]][13] == 1) huffman_out[13] <= {huffman_out[13][5:0],1'b1};

                if(mask_add[OUT_character[7:4]][14] == 1 && mask_add[OUT_character[3:0]][14] == 0) huffman_out[14] <= {huffman_out[14][5:0],1'b0};
                else if(mask_add[OUT_character[7:4]][14] == 0 && mask_add[OUT_character[3:0]][14] == 1) huffman_out[14] <= {huffman_out[14][5:0],1'b1};
            end
        end
    end
end

// out_len
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=7;i<15;i=i+1)
        begin
            out_len[i] <= 0;
        end
    end

    else
    begin
        if(current_state == IDLE)
        begin
            for(i=7; i<15;i=i+1)
                out_len[i] <= 0;
        end

        else if (next_state == BUILD || current_state == BUILD)
        begin
            if(OUT_character[7:4]>=7 && OUT_character[3:0] >= 7)
            begin
                out_len[OUT_character[7:4]] <= out_len[OUT_character[7:4]] + 1;
                out_len[OUT_character[3:0]] <= out_len[OUT_character[3:0]] + 1;
            end 

            else if(OUT_character[7:4] >= 7 && OUT_character[3:0] <7)
            begin
                if(OUT_character[7:4] == 7) out_len[7] <= out_len[7] + 1;
                else
                begin
                    if(mask_add[OUT_character[3:0]][7] == 1) out_len[7] <= out_len[7] + 1;
                end

                if(OUT_character[7:4] == 8) out_len[8] <= out_len[8] +1;
                else
                begin
                    if(mask_add[OUT_character[3:0]][8] == 1) out_len[8] <= out_len[8] + 1;
                end

                if(OUT_character[7:4] == 9) out_len[9] <= out_len[9] + 1;
                else
                begin
                    if(mask_add[OUT_character[3:0]][9] == 1) out_len[9] <= out_len[9] + 1;
                end

                if(OUT_character[7:4] == 10) out_len[10] <= out_len[10] + 1;
                else
                begin
                    if(mask_add[OUT_character[3:0]][10] == 1) out_len[10] <= out_len[10] + 1;
                end

                if(OUT_character[7:4] == 11) out_len[11] <= out_len[11] + 1;
                else
                begin
                    if(mask_add[OUT_character[3:0]][11] == 1) out_len[11] <= out_len[11] + 1;
                end

                if(OUT_character[7:4] == 12) out_len[12] <= out_len[12] + 1;
                else
                begin
                    if(mask_add[OUT_character[3:0]][12] == 1) out_len[12] <= out_len[12] + 1;
                end

                if(OUT_character[7:4] == 13) out_len[13] <= out_len[13] + 1;
                else
                begin
                    if(mask_add[OUT_character[3:0]][13] == 1) out_len[13] <= out_len[13] + 1;
                end

                if(OUT_character[7:4] == 14) out_len[14] <= out_len[14] + 1;
                else
                begin
                    if(mask_add[OUT_character[3:0]][14] == 1) out_len[14] <= out_len[14] + 1;
                end
            end

            else if(OUT_character[7:4] < 7 && OUT_character[3:0] >= 7)
            begin
                if(OUT_character[3:0] == 7) out_len[7] <= out_len[7] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][7] == 1) out_len[7] <= out_len[7] + 1;
                end

                if(OUT_character[3:0] == 8) out_len[8] <= out_len[8] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][8] == 1) out_len[8] <= out_len[8] + 1;
                end

                if(OUT_character[3:0] == 9) out_len[9] <= out_len[9] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][9] == 1) out_len[9] <= out_len[9] + 1;
                end

                if(OUT_character[3:0] == 10) out_len[10] <= out_len[10] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][10] == 1) out_len[10] <= out_len[10] + 1;
                end

                if(OUT_character[3:0] == 11) out_len[11] <= out_len[11] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][11] == 1) out_len[11] <= out_len[11] + 1;
                end

                if(OUT_character[3:0] == 12) out_len[12] <= out_len[12] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][12] == 1) out_len[12] <= out_len[12] + 1;
                end

                if(OUT_character[3:0] == 13) out_len[13] <= out_len[13] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][13] == 1) out_len[13] <= out_len[13] + 1;
                end

                if(OUT_character[3:0] == 14) out_len[14] <= out_len[14] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][14] == 1) out_len[14] <= out_len[14] + 1;
                end
            end

            else
            begin
                if(mask_add[OUT_character[3:0]][7] == 1) out_len[7] <= out_len[7] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][7] == 1) out_len[7] <= out_len[7] + 1;
                end   

                if(mask_add[OUT_character[3:0]][8] == 1) out_len[8] <= out_len[8] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][8] == 1) out_len[8] <= out_len[8] + 1;
                end    

                if(mask_add[OUT_character[3:0]][9] == 1) out_len[9] <= out_len[9] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][9] == 1) out_len[9] <= out_len[9] + 1;
                end       

                if(mask_add[OUT_character[3:0]][10] == 1) out_len[10] <= out_len[10] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][10] == 1) out_len[10] <= out_len[10] + 1;
                end               

                if(mask_add[OUT_character[3:0]][11] == 1) out_len[11] <= out_len[11] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][11] == 1) out_len[11] <= out_len[11] + 1;
                end    

                if(mask_add[OUT_character[3:0]][12] == 1) out_len[12] <= out_len[12] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][12] == 1) out_len[12] <= out_len[12] + 1;
                end     

                if(mask_add[OUT_character[3:0]][13] == 1) out_len[13] <= out_len[13] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][13] == 1) out_len[13] <= out_len[13] + 1;
                end   

                if(mask_add[OUT_character[3:0]][14] == 1) out_len[14] <= out_len[14] + 1;
                else
                begin
                    if(mask_add[OUT_character[7:4]][14] == 1) out_len[14] <= out_len[14] + 1;
                end        
            end
        end
    end
end


// build_cnt
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) build_cnt <= 6;
    else
    begin
        if(current_state == IDLE) build_cnt <= 6;
        else if(next_state == BUILD) 
        begin
            if(build_cnt == 0) build_cnt <= 0;
            else build_cnt <= build_cnt - 1;
        end
    end
end


// weight reg
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0;i<16;i=i+1)
        begin
            weight_reg[i] <= 0;
        end
    end

    else
    begin
        if(next_state == IDLE)
        begin
            for(i=0;i<15;i=i+1)
            begin
                weight_reg[i] <= 0;
            end

            weight_reg[15] <= 5'd31;
        end
        
        else if(next_state == INPUT)
        begin
            weight_reg[input_cnt] <= in_weight;
        end

        else if (next_state == BUILD || current_state == BUILD)
        begin
            weight_reg[build_cnt] <= weight_reg[OUT_character[7:4]] + weight_reg[OUT_character[3:0]];
        end
    end
end

//  input_cnt
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) input_cnt <= 4'd14;
    else
    begin
        if(next_state == IDLE)
        begin
            input_cnt <= 4'd14;
        end

        else if(next_state == INPUT)
        begin
            input_cnt <= input_cnt - 1;
        end
    end
end

// out_mode_reg
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) out_mode_reg <= 0;
    else
    begin
        if(current_state == IDLE && next_state == INPUT)
        begin
            out_mode_reg <= out_mode;
        end
    end
end

// FSM control
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

endmodule