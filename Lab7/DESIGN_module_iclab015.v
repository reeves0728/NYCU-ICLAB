module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) out_valid <= 0;
    else begin
        if(in_valid) out_valid <= 1;
        else out_valid <= 0; 
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) seed_out <= 0;
    else
    begin
        if(in_valid) seed_out <= seed_in;
    end
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output reg out_valid;
output reg [31:0] rand_num;
output reg busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

input clk2_fifo_flag1;
input clk2_fifo_flag2;
output reg clk2_fifo_flag3;
output clk2_fifo_flag4;

reg [31:0] seed_reg;
reg [31:0] seed_syn;
reg in_valid_d1;
reg in_valid_d2;
reg in_valid_d3;

reg [31:0] x_step1;
reg [31:0] x_step2;
reg [31:0] x_step3;
reg [31:0] x_step4;

// reg [6:0] addr_bin_write;
// reg [6:0] addr_gray_write;

// reg [7:0] out_cnt;

// integer i;
parameter IDLE = 0;
parameter PAUSE = 1;
parameter OUTPUT = 2;

reg [1:0] current_state, next_state;
reg [7:0] out_256_cnt; 

NDFF_BUS_syn #(32) NDFF_bus_syn(.D(seed),.Q(seed_syn),.clk(clk),.rst_n(rst_n));

// next_state
always @ (*)
begin
    next_state = 0;
    case(current_state)
        IDLE:
        begin
            if(in_valid_d3) next_state = OUTPUT;
            else next_state = IDLE;
        end

        OUTPUT:
        begin
            if(out_256_cnt == 255) next_state = IDLE;
            else next_state = PAUSE;
        end

        PAUSE:
        begin
            if(!fifo_full) next_state = OUTPUT;
            else next_state = PAUSE;
        end
    endcase
end

// out_256_cnt
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) out_256_cnt <= 0;
    else
    begin
        if(current_state == OUTPUT) out_256_cnt <= out_256_cnt + 1;
    end
end

// seed_reg
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) seed_reg <= 0;
    else
    begin
        if(in_valid_d3)  seed_reg <= seed_syn;
        else if(current_state == OUTPUT) seed_reg <= x_step4;
    end
end

// in_valid
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) in_valid_d1 <= 0;
    else in_valid_d1 <= in_valid;
end

// in_valid_d2
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) 
    begin
        in_valid_d2 <= 0;
    end
    else 
    begin
        in_valid_d2 <= in_valid_d1;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) 
    begin
        in_valid_d3 <= 0;
    end
    else 
    begin
        in_valid_d3 <= in_valid_d2;
    end
end

// busy
always @ (*)
begin
    busy = in_valid & ~in_valid_d1;
end


// x_step1, x_step2, x_step3, x_step4
always @ (*)
begin
    x_step1 = seed_reg;
end

always @ (*)
begin
    x_step2 = x_step1 ^ (x_step1 << 13);
end

always @ (*)
begin
    x_step3 = x_step2 ^ (x_step2 >> 17);
end


always @ (*)
begin
    x_step4 = x_step3 ^ (x_step3 << 5);
end

// current_state
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always @ (*)
begin
    out_valid = (current_state == OUTPUT && !fifo_full);
end

always @ (*)
begin
    rand_num = x_step4;
end

endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output reg fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

parameter SRAM_N_EMPTY = 0;
parameter R_DATA = 1;
parameter OUTPUT = 2;

reg [1:0] current_state, next_state;

always @ (*)
begin
    fifo_rinc = (current_state == R_DATA && !fifo_empty);
end


always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) current_state <= SRAM_N_EMPTY;
    else current_state <= next_state;
end

always @ (*)
begin
    next_state = 0;
    case(current_state)
        SRAM_N_EMPTY:
        begin
            if(fifo_empty) next_state = SRAM_N_EMPTY;
            else next_state = R_DATA;
        end

        R_DATA: next_state = OUTPUT;
        OUTPUT: 
        begin
            if(fifo_empty) next_state = SRAM_N_EMPTY;
            else next_state = R_DATA;
        end
    endcase
end



always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) rand_num <= 0;
    else
    begin
        if(current_state == OUTPUT) rand_num <= fifo_rdata;
        else rand_num <= 0;
    end
end


always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) out_valid <= 0;
    else
    begin
        if(current_state == OUTPUT) out_valid <= 1;
        else out_valid <= 0;
    end
end


endmodule