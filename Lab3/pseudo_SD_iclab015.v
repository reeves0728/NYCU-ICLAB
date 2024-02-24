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
//   File Name   : pseudo_SD.v
//   Module Name : pseudo_SD
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_SD (
    clk,
    MOSI,
    MISO
);

input clk;
input MOSI;
output reg MISO;

integer i;

parameter SD_p_r = "../00_TESTBED/SD_init.dat";

reg [63:0] SD [0:65535];
initial $readmemh(SD_p_r, SD);

reg [47:0] temp;
reg [6:0] command;
reg [31:0] address;
reg [6:0] crc7;
reg [6:0] crc7_f;
reg [15:0] crc16;
reg [16:0] golden_crc16;
reg end_bit;
reg [7:0] start_token;
reg [63:0] data;
reg [7:0] wait_response;


integer pat_read;
integer PAT_NUM;
integer i_pat;
integer count;


//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
initial
begin
    while(1)
    begin
        temp = 0;
        MISO = 1;
        INPUT;
        if(temp[45:40] == 6'd17)
        begin
            // $display("**************************************************************************************************************");
            // $display("                                                 IN command == 6'd17                                          ");
            // $display("**************************************************************************************************************");         
            READ_RESPONSE;
            SDREAD;
        end
        else if(temp[45:40] == 6'd24)
        begin
            // $display("**************************************************************************************************************");
            // $display("                                                 IN command == 6'd24                                          ");
            // $display("**************************************************************************************************************");        
            WRITE_RESPONSE;
            SDWRITE;
            SDRESPONSE;
        end
    end
end


//////////////////////////////////////////////////////////////////////

task INPUT; begin

    while(MOSI === 1'b1 || MOSI === 1'bx) 
    begin 
        @(posedge clk);
        #(2);
    end

    for(i = 47; i >= 1 ; i = i-1) begin
        MISO = 1;
        temp[i] = MOSI;
        @(posedge clk);
        #(2);
    end

    temp[0] = MOSI;
    @(posedge clk);

    end_bit = temp[0];

    // $display("**************************************************************************************************************");
    // $display("temp = %b", temp);
    // $display("**************************************************************************************************************");

    if(temp[47:46] !== 2'd01 || end_bit !== 1'd1)
    begin
        $display("**************************************************************************************************************");
        $display("                start wrong, end bit wrong             SPEC SD-1 FAIL                                         ");
        $display("**************************************************************************************************************");
        $finish;
    end


    // command = temp[45:40];
    if(temp[45:40] !== 6'b010001 && temp[45:40] !== 6'b011000)
    begin
        $display("**************************************************************************************************************");
        $display("                  command wrong                        SPEC SD-1 FAIL                                         ");
        $display("                  command = %b ", temp[45:40]);        
        $display("**************************************************************************************************************");
        $finish;
    end

    address = temp[39:8];
    if(address<0 || address >65535)
    begin
        $display("**************************************************************************************************************");
        $display("                                               SPEC SD-2 FAIL                                                 ");
        $display("**************************************************************************************************************");
        $finish;
    end

    crc7 = temp[7:1];
    crc7_f = CRC7(temp[47:8]);

    if(crc7 !== crc7_f)
    begin
        $display("**************************************************************************************************************");
        $display("                                               SPEC SD-3 FAIL                                                 ");
        $display("**************************************************************************************************************");
        $finish;
    end

end endtask


task READ_RESPONSE; begin
    // repeat(8) @(posedge clk); // wait 1 unit
    MISO = 0;
    repeat(8) @(posedge clk); // reponse for 1 unit;
    MISO = 1; 
    repeat(8) @(posedge clk); // wait 1 unit

end endtask


task WRITE_RESPONSE; begin

    // $display("**************************************************************************************************************");
    // $display("                                                 IN WRITE_RESPONSE input                                      ");
    // $display("**************************************************************************************************************");
    // repeat(8) @(posedge clk); // wait 1 unit

    wait_response = 8'b0;
    for(i = 0;i<8;i=i+1)
    begin
        MISO = wait_response[i];
        @(posedge clk);
    end
    // MISO = 0;
    // repeat(8) @(posedge clk); // reponse for 1 unit;
    MISO = 1; 
    // repeat(8) @(posedge clk); // wait 1 unit

end endtask


task SDWRITE; begin
    // $display("**************************************************************************************************************");
    // $display("                                                 IN SDWRITE input                                             ");
    // $display("**************************************************************************************************************");
    data = 0;
    count = 0;
    #(2);
    while(MOSI === 1)begin
        count = count + 1;
        @(posedge clk);
        #(2);
    end

    if(count < 15) begin

    $display("**************************************************************************************************************");
    $display("                    count < 16                             SPEC SD-5 FAIL                                     ");
    $display("**************************************************************************************************************");
    $finish;        
    end

    if(count > 263) begin
    $display("**************************************************************************************************************");
    $display("                    count > 264                             SPEC SD-5 FAIL                                    ");
    $display("**************************************************************************************************************");
    $finish; 
    end
    
    if( ((count+1) % 8) !== 0) begin
    $display("**************************************************************************************************************");
    $display("                                               SPEC SD-5 FAIL                         ");
    $display("                                               count = %d                       ",count);    
    $display("**************************************************************************************************************");
    $finish;
    end


    @(posedge clk); // end recieving the start token
    #(2);
    for(i = 63; i >=0;i=i-1)begin
        data[i] = MOSI;
        @(posedge clk);
        #(2);
    end

    for(i=15; i>=0;i=i-1) begin
        crc16[i] = MOSI;
        @(posedge clk);
        #(2);
    end


    golden_crc16 = CRC16_CCITT(data);

    if(crc16 !== golden_crc16) begin
        $display("**************************************************************************************************************");
        $display("                                               SPEC SD-4 FAIL                                                 ");
        $display("**************************************************************************************************************");
        $finish;
    end
    
    // SD[address] = data;
end endtask



task SDREAD; begin
    data = 0;
    
    start_token = 8'hFE;
    for(i = 7; i>=0; i=i-1)begin
        MISO = start_token[i];
        @(posedge clk);
    end

    data = SD[address];


    for(i = 63; i >= 0; i=i-1)begin
        MISO = data[i];
        @(posedge clk);
    end

    golden_crc16 = CRC16_CCITT(data);

    for(i = 15 ; i >=0; i = i-1) begin
        MISO = golden_crc16[i];
        @(posedge clk);
    end
end endtask



task SDRESPONSE; begin // 8'b00000101
    MISO = 0;
    repeat(5) @(posedge clk);
    MISO = 1;
    @(posedge clk);
    MISO = 0;
    @(posedge clk);
    MISO = 1;
    @(posedge clk);
    MISO = 0;
    repeat (8) @(posedge clk);
    SD[address] = data;
    MISO = 1;

end endtask

// task YOU_FAIL_task; begin
//     $display("*                              FAIL!                                    *");
//     $display("*                 Error message from pseudo_SD.v                        *");
// end endtask

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
