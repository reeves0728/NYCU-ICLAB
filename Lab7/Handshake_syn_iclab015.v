module Handshake_syn #(parameter WIDTH=32) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;
reg sCtrl;
reg dCtrl;

reg [WIDTH-1:0] data;
reg [WIDTH-1:0] data_syn;
integer i;

reg dbusy_d1, dbusy_d2;
reg dCtrl_d1, dCtrl_d2;

NDFF_syn NDFF_TX(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn NDFF_RX(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));
NDFF_BUS_syn #(WIDTH) NDFF_bus(.D(data),.Q(data_syn),.clk(dclk),.rst_n(rst_n));

// sreq
always @ (posedge sclk or negedge rst_n)
begin
    if(!rst_n) sreq <= 0;
    else
    begin
        // if(sready) sreq <= 1;
        // else if (sack) sreq <= 0;
        sreq <= sready ? 1'b1 : 1'b0;        
    end
end

// data
always @ (posedge sclk or negedge rst_n)
begin
    if(!rst_n) 
    begin
        for(i=0;i<32;i=i+1)
        begin
            data[i] <= 0;
        end
    end
    else
    begin
        if(sCtrl) data <= din;
    end
end

// sCtrl
always @ (posedge sclk or negedge rst_n)
begin
    if(!rst_n) sCtrl <= 0;
    else
    begin
        sCtrl <= sready ? 1'b1 : 1'b0; 
    end
end

// dCtrl
always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n) dCtrl <= 0;
    else
    begin
        dCtrl <= dreq ? 1'b1 : 1'b0;
    end
end

// dout
always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0;i<32;i=i+1)
        begin
            dout[i]<= 0;
        end
    end

    else
    begin
        if(dCtrl_d2) dout <= data_syn;
    end
end

// dvalid
always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n) dvalid <= 0;
    else
    begin
        if(dbusy || dack) dvalid <= 0;
        // else if(dbusy) dvalid <= 0;
        else if(dCtrl_d2) dvalid <= 1;
    end
end

always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n) 
    begin
        dbusy_d1 <= 0;
        dbusy_d2 <= 0;
    end

    else
    begin
        dbusy_d1 <= dbusy;
        dbusy_d2 <= dbusy_d1;
    end
end

// dack
always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n) dack <= 0;
    else
    begin
        if(dbusy || dbusy_d1 || dbusy_d2) dack <= 1;
        else if (!dreq) dack <= 0;
    end
end

always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n)
    begin
        dCtrl_d1 <= 0;
        dCtrl_d2 <= 0;
    end

    else
    begin
        dCtrl_d1 <= dCtrl;
        dCtrl_d2 <= dCtrl_d1;
    end
end


// sidle
assign sidle = sreq & sack;

endmodule