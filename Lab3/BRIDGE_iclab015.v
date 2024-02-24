//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
reg [4:0] current_state, next_state;
reg direction_reg;
reg [31:0] addr_dram_reg;
reg [31:0] addr_sd_reg;
reg [6:0] crc7_sd_read_reg;
reg [6:0] crc7_sd_write_reg;
reg [15:0] crc16_read_write_reg;
reg [15:0] crc16_sd_write_reg;
reg [47:0] command;
reg [101:0] sd_write_MOSI;

reg [63:0] dram_2_sd_data;
reg [79:0] sd_2_dram_data;

reg [5:0] command_cnt;
reg [6:0] sd_read_MISO_cnt;
reg [6:0] sd_write_MISO_cnt;
reg [3:0] data_response_cnt;
reg [7:0] out_data_cnt;

reg [2:0] sd_read_wait_response_cnt;

reg sd_write_flag;
reg output_flag;

parameter IDLE = 0;
parameter DRAM_READ = 1;
parameter DRAM_READ_SEND_COMMAND = 2;
parameter DRAM_READ_WAIT_RESPONSE = 3;
parameter SD_WRITE = 4;
parameter SD_WRITE_RESPONSE = 5;
parameter WAIT_BUSY = 6;
parameter DATA_OUTPUT = 7;


parameter SD_READ = 8;
parameter SD_READ_WAIT_RESPONSE = 9;
parameter SD_READ_RESPONSE = 10;
parameter SD_READ_WAIT_DATA = 11;
parameter SD_READ_DATA = 12;
parameter DRAM_WRITE_1 = 13;
parameter DRAM_WRITE_2 = 14;
parameter DATA_OUTPUT_2= 15;

parameter INPUT_STATE_1 = 16;
//==============================================//
//           reg & wire declaration             //
//==============================================//



//==============================================//
//                  design                      //
//==============================================//
//==============================================//
//               combinational                  //
//==============================================//
always @(*) begin
    sd_write_MOSI = 0;
    command = 0;
    case(current_state)
        IDLE:
        begin
            if(in_valid == 1'b1)
            begin
                if(direction == 1'b0)
                begin
                    next_state = INPUT_STATE_1;
                end

                else
                begin
                    next_state = SD_READ;
                end
            end

            else
            begin
                next_state = IDLE;
            end
        end

        INPUT_STATE_1:
        begin
            next_state = DRAM_READ;
        end

        DRAM_READ:
        begin
            if(sd_write_flag == 0)
            begin
                next_state = DRAM_READ;
            end

            else
            begin
                next_state = DRAM_READ_SEND_COMMAND;
            end            
        end

        DRAM_READ_SEND_COMMAND:
        begin
            command = {1'b0,1'b1,6'd24,addr_sd_reg,crc7_sd_write_reg,1'b1};
            if(command_cnt == 0)
            begin
                next_state = DRAM_READ_WAIT_RESPONSE;
            end

            else
            begin
                next_state = DRAM_READ_SEND_COMMAND;
            end
        end

        DRAM_READ_WAIT_RESPONSE:
        begin
            if(MISO == 1)
            begin
                next_state = DRAM_READ_WAIT_RESPONSE;
            end

            else
            begin
                next_state = SD_WRITE;
            end
        end

        SD_WRITE:
        begin
            sd_write_MOSI = {6'b111111,8'b11111111,7'b1111111,1'b0,dram_2_sd_data,crc16_sd_write_reg};
            if(sd_write_MISO_cnt == 0)
            begin
                next_state = SD_WRITE_RESPONSE;
            end

            else
            begin
                next_state = SD_WRITE;
            end
        end

        SD_WRITE_RESPONSE:
        begin
            if(data_response_cnt == 8)
            begin
                next_state = WAIT_BUSY;
            end

            else
            begin
                next_state = SD_WRITE_RESPONSE;
            end
        end

        WAIT_BUSY:
        begin
            if(MISO == 1)
            begin
                next_state = DATA_OUTPUT;
            end

            else
            begin
                next_state = WAIT_BUSY;
            end
        end

        DATA_OUTPUT:
        begin
            if(out_data_cnt == 7)
            begin
                next_state = IDLE;
            end

            else
            begin
                next_state = DATA_OUTPUT;
            end
        end

        //////////////////// SD_READ ////////////////////////////////////////////

        SD_READ:
        begin
            command = {2'b01,6'd17,addr_sd_reg,crc7_sd_read_reg,1'b1};
            if(command_cnt == 0)
            begin
                next_state = SD_READ_WAIT_RESPONSE;
            end

            else
            begin
                next_state = SD_READ;
            end
        end

        SD_READ_WAIT_RESPONSE:
        begin
            if(MISO == 0)
            begin
                next_state = SD_READ_RESPONSE;
            end

            else
            begin
                next_state = SD_READ_WAIT_RESPONSE;
            end
        end

        SD_READ_RESPONSE:
        begin
            if(sd_read_wait_response_cnt == 7)
            begin
                next_state = SD_READ_WAIT_DATA;
            end

            else 
            begin
                next_state = SD_READ_RESPONSE;
            end
        end

        SD_READ_WAIT_DATA:
        begin
            if(MISO == 0)
            begin
                next_state = SD_READ_DATA;
            end

            else
            begin
                next_state = SD_READ_WAIT_DATA;
            end
        end

        SD_READ_DATA:
        begin
            if(sd_read_MISO_cnt == 0)
            begin
                next_state = DRAM_WRITE_1;                
            end

            else
            begin
                next_state = SD_READ_DATA;
            end
        end

        DRAM_WRITE_1:
        begin
            next_state = DRAM_WRITE_2;
        end

        DRAM_WRITE_2:
        begin
            if(output_flag == 1) 
            begin
                next_state = DATA_OUTPUT_2;
            end
            else
            begin
                next_state = DRAM_WRITE_2;
            end
        end

        DATA_OUTPUT_2:
        begin
            if(out_data_cnt == 7)
            begin
                next_state = IDLE;
            end

            else
            begin
                next_state = DATA_OUTPUT_2;
            end            
        end

        default: begin
            next_state = current_state;
        end
    endcase
end


always @ (*) begin
    crc7_sd_read_reg = CRC7({2'b01,6'd17,addr_sd_reg});
end

always @ (*) begin
    crc7_sd_write_reg = CRC7({2'b01,6'd24,addr_sd_reg});
end

always @ (*) begin
    crc16_sd_write_reg = CRC16_CCITT({dram_2_sd_data});
end


always @ (*) begin
    if(current_state == DRAM_READ && R_READY == 1 && R_VALID == 1 )
    begin
        sd_write_flag = 1;
    end

    else
    begin
        sd_write_flag = 0;
    end
end

always @ (*) begin
    if(current_state == DRAM_WRITE_2 && B_READY == 1 && B_VALID == 1 )
    begin
        output_flag = 1;
    end

    else
    begin
        output_flag = 0;
    end
end

//==============================================//
//                 sequential                   //
//==============================================//
///////////////////// state control ////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        current_state <= IDLE;
    end

    else
    begin
        current_state <= next_state;
    end
end


/////////////////////////// get input //////////////////////////

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_dram_reg <= 0;
    end
    else begin
        if(in_valid == 1'b1) 
        begin
            addr_dram_reg <= addr_dram;
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_sd_reg <= 0;
    end
    else begin
        if(in_valid == 1'b1) begin
            addr_sd_reg <= addr_sd;
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        direction_reg <= 0;
    end
    else begin
        if(in_valid == 1'b1) begin
            direction_reg <= direction;
        end
    end
end

////////////////////// output signal /////////////////////////////////

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        out_valid <= 0;            
    end

    else
    begin
        if(current_state == DATA_OUTPUT || current_state == DATA_OUTPUT_2)
        begin
            out_valid <= 1;
        end

        else
        begin
            out_valid <= 0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        out_data <= 0;             
    end

    else
    begin
        if(current_state == DATA_OUTPUT)
        begin
            case(out_data_cnt)
                0: out_data <= dram_2_sd_data[63:56];
                1: out_data <= dram_2_sd_data[55:48];
                2: out_data <= dram_2_sd_data[47:40];
                3: out_data <= dram_2_sd_data[39:32];
                4: out_data <= dram_2_sd_data[31:24];
                5: out_data <= dram_2_sd_data[23:16];
                6: out_data <= dram_2_sd_data[15:8];
                7: out_data <= dram_2_sd_data[7:0];
            endcase
        end

        else if(current_state == DATA_OUTPUT_2)
        begin
            case(out_data_cnt)
                0: out_data <= sd_2_dram_data[78:71];
                1: out_data <= sd_2_dram_data[70:63];
                2: out_data <= sd_2_dram_data[62:55];
                3: out_data <= sd_2_dram_data[54:47];
                4: out_data <= sd_2_dram_data[46:39];
                5: out_data <= sd_2_dram_data[38:31];
                6: out_data <= sd_2_dram_data[30:23];
                7: out_data <= sd_2_dram_data[22:15];
            endcase            
        end
        else
        begin
            out_data <= 0;
        end
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_data_cnt <= 0;
    end

    else
    begin
        if(in_valid == 1)
        begin
            out_data_cnt <= 0;
        end

        if(current_state == DATA_OUTPUT || current_state == DATA_OUTPUT_2)
        begin
            out_data_cnt <= out_data_cnt + 1;
        end
    end
end


/////////////////////// MOSI control ///////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        MOSI <= 1;              
    end

    else
    begin

        if(current_state == SD_READ)
        begin
            MOSI <= command[command_cnt];
        end

        if(current_state == DRAM_READ_SEND_COMMAND)
        begin
            MOSI <= command[command_cnt];
        end

        if(current_state == SD_WRITE)
        begin
            MOSI <= sd_write_MOSI[sd_write_MISO_cnt];
        end

        if(current_state == SD_WRITE_RESPONSE || current_state == WAIT_BUSY)
        begin
            MOSI <= 1;
        end
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        command_cnt <= 0;
    end

    else
    begin
        if(in_valid == 1)
        begin
            command_cnt <= 47;        
        end

        if(current_state == SD_READ || current_state == DRAM_READ_SEND_COMMAND)
        begin
            command_cnt <= command_cnt - 1;
        end

        if(command_cnt == 6'd0)
        begin
            command_cnt <= 47;
        end
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sd_write_MISO_cnt <= 0;
    end

    else
    begin
        if(in_valid)
        begin
            sd_write_MISO_cnt <= 101;
        end

        if(current_state == SD_WRITE)
        begin
            sd_write_MISO_cnt <= sd_write_MISO_cnt - 1;
        end

        if(sd_write_MISO_cnt == 7'b0)
        begin
            sd_write_MISO_cnt <= 101;
        end
    end
end

/////////////////////// DRAM_READ //////////////////////////////////////

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        AR_ADDR <= 0;          
    end

    else
    begin
        if(AR_VALID == 1'b1 && AR_READY == 1'b1)
        begin
            AR_ADDR <= 0;
        end
        
        else if(direction_reg == 1'b0  && current_state == INPUT_STATE_1)
        begin
            AR_ADDR <= addr_dram_reg;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        AR_VALID <= 0;          
    end

    else
    begin
        if(AR_VALID == 1'b1 && AR_READY == 1'b1)
        begin
            AR_VALID <= 0;
        end
        
        else if(direction_reg == 1'b0 && current_state == INPUT_STATE_1)
        begin
            AR_VALID <= 1'b1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        R_READY <= 0;           
    end

    else
    begin
        if(current_state == DRAM_READ) 
        begin
            if(R_READY == 1 && R_VALID == 1)
            begin
                R_READY <= 0;
            end
            
            else if(AR_VALID == 0 && AR_READY == 0)
            begin
                R_READY <= 1;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        dram_2_sd_data <= 0;           
    end

    else
    begin
        if(current_state == DRAM_READ) 
        begin
            if(R_READY == 1 && R_VALID == 1)
            begin
                dram_2_sd_data <= R_DATA;
            end
        end
    end
end

///////////////////////////////// SD_WRITE ////////////////////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        data_response_cnt <= 0;
    end

    else
    begin
        if(in_valid)
        begin
            data_response_cnt <= 0;
        end

        if(current_state == SD_WRITE_RESPONSE)
        begin
            data_response_cnt <= data_response_cnt + 1;
        end

        if(data_response_cnt == 8)
        begin
            data_response_cnt <= 0;
        end
    end
end

/////////////////////////////// SD_READ /////////////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sd_read_wait_response_cnt <= 0;
    end

    else
    begin
        if(current_state == SD_READ_RESPONSE)
        begin
            sd_read_wait_response_cnt <= sd_read_wait_response_cnt + 1;
        end

        if(in_valid == 1)
        begin
            sd_read_wait_response_cnt <= 0;
        end

        if(sd_read_wait_response_cnt == 7)
        begin
            sd_read_wait_response_cnt <= 0;          
        end
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sd_2_dram_data <= 0;
    end

    else
    begin
        if(next_state == SD_READ_DATA)
        begin
            sd_2_dram_data[sd_read_MISO_cnt] <= MISO;
        end  
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sd_read_MISO_cnt <= 0;
    end

    else
    begin
        if(in_valid == 1)
        begin
            sd_read_MISO_cnt <= 79;
        end

        else
        begin
            if(next_state == SD_READ_DATA)
            begin
                sd_read_MISO_cnt <= sd_read_MISO_cnt - 1;
            end

            if(sd_read_MISO_cnt == 0)
            begin
                sd_read_MISO_cnt <= 0;
            end
        end
    end

end




////////////////////////// DRAM_WRITE ////////////////////////////

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        AW_ADDR <= 0;           
    end

    else
    begin
        if(current_state == DRAM_WRITE_1)
        begin
            AW_ADDR <= addr_dram_reg;
        end

        if(AW_VALID == 1 && AW_READY == 1)
        begin
            AW_ADDR <= 0;
        end
    end

end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        AW_VALID <= 0;            
    end

    else
    begin
        if(current_state == DRAM_WRITE_1)
        begin
            AW_VALID <= 1;
        end

        if(AW_VALID == 1 && AW_READY == 1)
        begin
            AW_VALID <= 0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        W_VALID <= 0;         
    end

    else
    begin
        if(current_state == DRAM_WRITE_2)
        begin
            if(AW_VALID == 1 & AW_READY == 1)
            begin
                W_VALID <= 1;
            end

            if(W_VALID == 1 && W_READY == 1)
            begin
                W_VALID <=0;
            end
        end
    end

end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        W_DATA <= 0;           
    end

    else
    begin
        if(current_state == DRAM_WRITE_2)
        begin
            if(AW_VALID == 1 && AW_READY == 1)
            begin
            W_DATA <= sd_2_dram_data[78:15];
            end
            if(W_VALID == 1 && W_READY == 1)
            begin
                W_DATA <=0;
            end
        end
    end

end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        B_READY <= 0;           
    end

    else
    begin
        if(current_state == DRAM_WRITE_2)
        begin
            if(AW_VALID == 1 & AW_READY == 1)
            begin
                B_READY <= 1;
            end
            if(B_READY == 1 && B_VALID == 1)
            begin
                B_READY <= 0;
            end
        end
    end

end


///////////////////////////////// function /////////////////////////////


function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT;
    // Try to implement CRC-16-CCITT function by yourself.
    input [63:0] data;  // 40-bit data input
    reg [15:0] crc16;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'h1021;  // x^7 + x^3 + 1 7'b10001001

    begin
        crc16 = 16'd0;
        for (i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc16[15];
            crc16 = crc16 << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc16 = crc16 ^ polynomial;
            end
        end
        CRC16_CCITT = crc16;
    end
endfunction

endmodule

