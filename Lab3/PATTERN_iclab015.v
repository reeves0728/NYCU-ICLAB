`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
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

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [12:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data; 

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;

real CYCLE = `CYCLE_TIME;
integer pat_read;
integer PAT_NUM;
integer total_latency, latency;
integer i_pat;
integer cycle;
integer i;

reg [12:0] data_a;
reg [15:0] data_b;
reg [63:0] dram_data_check;
reg [63:0] sd_data_check;
reg data_c;

always #(CYCLE/2.0) clk = ~clk;

parameter SD_p_r = "../00_TESTBED/SD_init.dat";
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
parameter SD_p_f = "../00_TESTBED/SD_final.dat";
parameter DRAM_p_f = "../00_TESTBED/DRAM_final.dat";
reg [63:0] SD_golden [0:65535];
reg [63:0] DRAM_golden [0:8191];
reg [63:0] SD_final [0:65535];
reg [63:0] DRAM_final [0:8191];
initial $readmemh(SD_p_r, SD_golden);
initial $readmemh(DRAM_p_r, DRAM_golden);

initial begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r");
    reset_signal_task;

    i_pat = 0;
    total_latency = 0;
    $fscanf(pat_read, "%d", PAT_NUM);
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);

    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM);
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);
    $readmemh(SD_p_f, SD_final);
    $readmemh(DRAM_p_f, DRAM_final);
    check_final;
    YOU_PASS_task;
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
task check_final; begin
        // $display("**************************************************************************************************************");
        // $display("                                      IN CHECK FINAL                                             ");
        // $display("**************************************************************************************************************");     
    for(i=0; i<8192;i=i+1)
    begin
        if(DRAM_golden[i] !== DRAM_final[i])
        begin
            $display("**************************************************************************************************************");
            $display("                                      DRAM FINAL DAT FILE FAIL                                             ");
            $display("**************************************************************************************************************"); 
            $finish;           
        end
    end

    for(i=0;i<65536;i=i+1)
    begin
        if(SD_golden[i] !== SD_final[i])
        begin
            $display("**************************************************************************************************************");
            $display("                                           SD FINAL DAT FILE FAIL                                             ");
            $display("**************************************************************************************************************"); 
            $finish;               
        end
    end

end
endtask



task input_task; begin
    repeat($urandom_range(3, 5)) @(negedge clk);
    in_valid = 1;
    $fscanf(pat_read,"%d %d %d",data_c,data_a,data_b);
    direction = data_c;
    addr_dram = data_a;
    addr_sd = data_b;

    if (direction === 0)
    begin
        SD_golden[addr_sd] = DRAM_golden[addr_dram];
    end
    else
    begin
        DRAM_golden[addr_dram] = SD_golden[addr_sd];       
    end

    @(negedge clk);
    in_valid = 0;
    direction = 1'bx;
    addr_dram = 13'bx;
    addr_sd = 16'bx;
end
endtask


task wait_out_valid_task; begin
    latency = 0 ;
    // $display("**************************************************************************************************************");
    // $display("                            wait_out_valid_task                                              ");
    // $display("**************************************************************************************************************");   
    while(out_valid!==1) begin 
    // $display("**************************************************************************************************************");
    // $display("                            in while                                              ");
    // $display("**************************************************************************************************************");  

    // $display("**************************************************************************************************************");
    // $display("                            out_data   = %d                                           ",out_data);
    // $display("**************************************************************************************************************");       
        latency = latency + 1 ;
        if (latency==10000) begin
            // The execution latency is limited in 300 cycles. 
            // The latency is the clock cycles between the falling edge of the last cycle of in_valid and the rising edge of the out_valid. 
            $display("**************************************************************************************************************");
            $display("                                               SPEC MAIN-3 FAIL                                               ");
            $display("**************************************************************************************************************");
            repeat(5)  @(negedge clk);            
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end
endtask

task check_ans_task; 
begin
    cycle = 0;
    // $display("**************************************************************************************************************");
    // $display("                                               check_and_task                                                 ");
    // $display("**************************************************************************************************************");  
    dram_data_check = u_DRAM.DRAM[data_a];
    sd_data_check = u_SD.SD[data_b];
    while(out_valid === 1) 
    begin
        // if(out_data !== 0) begin
        cycle = cycle + 1;
        // $display("latency = %d", cycle);

        if(u_DRAM.DRAM[data_a] !== u_SD.SD[data_b]) 
        begin
            // $display("u_DRAM.DRAM[addr_dram] = %b", u_DRAM.DRAM[data_a]);
            // $display("u_SD.SD[addr_sd] = %b", u_SD.SD[data_b]);
            $display("**************************************************************************************************************");
            $display("                                               SPEC MAIN-6 FAIL                                               ");
            $display("**************************************************************************************************************");
            $finish;     
        end


        if(data_c === 0)
        begin
            // $display("**************************************************************************************************************");
            // $display("                  Dram ---> SD                             direction === 0                                    ");
            // $display("**************************************************************************************************************");

            if(out_data != dram_data_check[63:56])
            begin
                $display("**************************************************************************************************************");
                $display("                                               SPEC MAIN-5 FAIL                                               ");
                $display("**************************************************************************************************************"); 
                $finish;   
            end
        
            dram_data_check = dram_data_check << 8;
        end

        if(data_c === 1)
        begin
            // $display("**************************************************************************************************************");
            // $display("                  SD ---> DREAN                            direction === 1                                    ");
            // $display("**************************************************************************************************************");

            if(out_data != sd_data_check[63:56])
            begin
                $display("**************************************************************************************************************");
                $display("                                               SPEC MAIN-5 FAIL                                               ");
                $display("**************************************************************************************************************"); 
                $finish;   
            end
            sd_data_check = sd_data_check << 8;
        end

        if(cycle === 9) begin
            $display("**************************************************************************************************************");
            $display("                      latency != 8                         SPEC MAIN-4 FAIL                                   ");
            $display("**************************************************************************************************************"); 
            $finish;  
        end


        @(negedge clk);
    end

    if(cycle !== 8) begin
        $display("**************************************************************************************************************");
        $display("                      latency != 8                         SPEC MAIN-4 FAIL                                   ");
        $display("**************************************************************************************************************"); 
        $finish;       
    end
    
end
endtask


always @ (negedge clk) begin
    if(out_valid === 0) begin
        // $display("in out data check");
        if(out_data !== 0) 
        begin
            $display("**************************************************************************************************************");
            $display("                                               SPEC MAIN-2 FAIL                                               ");
            $display("**************************************************************************************************************");
            $finish;
        end
    end
end

task reset_signal_task; begin
    rst_n = 'b1;
    in_valid = 'b0;
    total_latency = 0;
    direction = 'b0;
    addr_dram = 'b0;
    addr_sd = 'b0;
    clk = 'b0;
    force clk = 0;

    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    
    if(out_valid !== 1'b0 || out_data !== 'b0 || AW_ADDR !== 'b0 || AW_VALID !== 1'b0 || W_VALID !== 'b0 || W_DATA !== 'b0 || B_READY !== 'b0 || AR_ADDR !== 'b0 || AR_VALID !== 'b0 || R_READY !== 'b0 || MOSI !== 'b1) begin //out!==0
        $display("**************************************************************************************************************");
        $display("                                               SPEC MAIN-1 FAIL                                               ");
        $display("**************************************************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end

	#CYCLE; release clk;

end
endtask

//////////////////////////////////////////////////////////////////////

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    // write address channel
    .AW_ADDR(AW_ADDR),
    .AW_VALID(AW_VALID),
    .AW_READY(AW_READY),
    // write data channel
    .W_VALID(W_VALID),
    .W_DATA(W_DATA),
    .W_READY(W_READY),
    // write response channel
    .B_VALID(B_VALID),
    .B_RESP(B_RESP),
    .B_READY(B_READY),
    // read address channel
    .AR_ADDR(AR_ADDR),
    .AR_VALID(AR_VALID),
    .AR_READY(AR_READY),
    // read data channel
    .R_DATA(R_DATA),
    .R_VALID(R_VALID),
    .R_RESP(R_RESP),
    .R_READY(R_READY)
);

pseudo_SD u_SD (
    .clk(clk),
    .MOSI(MOSI),
    .MISO(MISO)
);

endmodule