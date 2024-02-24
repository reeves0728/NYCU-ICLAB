//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/
// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################
//               reg & wire
//####################################################
parameter[3:0] IDLE = 4'd0;
parameter[3:0] DRAM_READ_INST = 4'd1;
parameter[3:0] FETCH_INST = 4'd2;
parameter[3:0] DECODE = 4'd3;
parameter[3:0] LOAD = 4'd4;
parameter[3:0] STORE = 4'd5;
parameter[3:0] EXECUTE = 4'd6;
parameter[3:0] WRITE_BACK = 4'd7;
parameter[3:0] DRAM_READ_DATA = 4'd8;
parameter[3:0] WAIT_SRAM_DATA = 4'd9;
parameter[3:0] CHECK_SRAM_RANGE = 4'd10;
parameter[3:0] BUFFER = 4'd11;
parameter[3:0] DRAM_READ_INST_BUFFER = 4'd12;
parameter[3:0] DRAM_READ_DATA_BUFFER = 4'd13;
parameter[3:0] WAIT_SRAM_DATA_BUFFER = 4'd14;
parameter[3:0] WRTIE_BACK_BUFFER = 4'd15;

reg [11:0] inst_pc;
wire signed [12:0] inst_pc_signed;
reg [11:0] inst_start_pc;
reg [11:0] data_pc;
reg [11:0] data_start_pc;

reg [6:0] addr_inst;
reg [15:0] DO_inst;
reg [15:0] DI_inst;
reg WEB_inst;


reg [6:0] addr_data;
reg [15:0] DO_data;
reg [15:0] DI_data;
reg WEB_data;
reg [15:0] dram_write_in;
reg [3:0] current_state, next_state;
reg [6:0] addr_cnt;

reg [2:0] opcode;
reg [3:0] rs, rt, rd;
reg func;
reg signed [4:0] imm;
reg [12:0] addr_jump;

reg  signed [15:0] rs_temp;
reg  signed [15:0] rt_temp;
reg  signed [15:0] rd_temp;
reg [63:0] r_data_temp;

reg data_sram_empty;

SPRAM INST(
 .A0  (addr_inst[0]),   .A1  (addr_inst[1]),   .A2  (addr_inst[2]),   .A3  (addr_inst[3]),   .A4  (addr_inst[4]),   .A5  (addr_inst[5]),   .A6  (addr_inst[6]),
 .DO0 (DO_inst[0]),   .DO1 (DO_inst[1]),   .DO2 (DO_inst[2]),   .DO3 (DO_inst[3]),   .DO4 (DO_inst[4]),   .DO5 (DO_inst[5]),   .DO6 (DO_inst[6]),   .DO7 (DO_inst[7]),
 .DO8 (DO_inst[8]),   .DO9 (DO_inst[9]),   .DO10(DO_inst[10]),  .DO11(DO_inst[11]),  .DO12(DO_inst[12]),  .DO13(DO_inst[13]),  .DO14(DO_inst[14]),  .DO15(DO_inst[15]),
 .DI0 (DI_inst[0]),   .DI1 (DI_inst[1]),   .DI2 (DI_inst[2]),   .DI3 (DI_inst[3]),   .DI4 (DI_inst[4]),   .DI5 (DI_inst[5]),   .DI6 (DI_inst[6]),   .DI7 (DI_inst[7]),
 .DI8 (DI_inst[8]),   .DI9 (DI_inst[9]),   .DI10(DI_inst[10]),  .DI11(DI_inst[11]),  .DI12(DI_inst[12]),  .DI13(DI_inst[13]),  .DI14(DI_inst[14]),  .DI15(DI_inst[15]),
 .CK(clk), .WEB(WEB_inst), .OE(1'b1), .CS(1'b1)
);

SPRAM DATA(
 .A0  (addr_data[0]),   .A1  (addr_data[1]),   .A2  (addr_data[2]),   .A3  (addr_data[3]),   .A4  (addr_data[4]),   .A5  (addr_data[5]),   .A6  (addr_data[6]),
 .DO0 (DO_data[0]),   .DO1 (DO_data[1]),   .DO2 (DO_data[2]),   .DO3 (DO_data[3]),   .DO4 (DO_data[4]),   .DO5 (DO_data[5]),   .DO6 (DO_data[6]),   .DO7 (DO_data[7]),
 .DO8 (DO_data[8]),   .DO9 (DO_data[9]),   .DO10(DO_data[10]),  .DO11(DO_data[11]),  .DO12(DO_data[12]),  .DO13(DO_data[13]),  .DO14(DO_data[14]),  .DO15(DO_data[15]),
 .DI0 (DI_data[0]),   .DI1 (DI_data[1]),   .DI2 (DI_data[2]),   .DI3 (DI_data[3]),   .DI4 (DI_data[4]),   .DI5 (DI_data[5]),   .DI6 (DI_data[6]),   .DI7 (DI_data[7]),
 .DI8 (DI_data[8]),   .DI9 (DI_data[9]),   .DI10(DI_data[10]),  .DI11(DI_data[11]),  .DI12(DI_data[12]),  .DI13(DI_data[13]),  .DI14(DI_data[14]),  .DI15(DI_data[15]),
 .CK(clk), .WEB(WEB_data), .OE(1'b1), .CS(1'b1)
);

AXI4_READ INF_AXI4_READ ( .clk(clk), .rst_n(rst_n), .arid_m_inf(arid_m_inf), .araddr_m_inf(araddr_m_inf), .arlen_m_inf(arlen_m_inf), .arsize_m_inf(arsize_m_inf), .arburst_m_inf(arburst_m_inf),
      .arvalid_m_inf(arvalid_m_inf), .arready_m_inf(arready_m_inf), .rid_m_inf(rid_m_inf), .rdata_m_inf(rdata_m_inf), .rresp_m_inf(rresp_m_inf),.rlast_m_inf(rlast_m_inf),  .rvalid_m_inf(rvalid_m_inf),  .rready_m_inf(rready_m_inf),
      .current_state_CPU(current_state), .inst_pc(inst_pc), .inst_start_pc(inst_start_pc), .data_pc(data_pc), .data_start_pc(data_start_pc)
    );

AXI_WRITE INF_AXI4_WRITE(
    .clk(clk), .rst_n(rst_n), .awid_m_inf(awid_m_inf), .awaddr_m_inf(awaddr_m_inf), .awsize_m_inf(awsize_m_inf), .awburst_m_inf(awburst_m_inf), .awlen_m_inf(awlen_m_inf), .awvalid_m_inf(awvalid_m_inf), .awready_m_inf(awready_m_inf),
    .wdata_m_inf(wdata_m_inf), .wlast_m_inf(wlast_m_inf), .wvalid_m_inf(wvalid_m_inf), .wready_m_inf(wready_m_inf), .bid_m_inf(bid_m_inf), .bresp_m_inf(bresp_m_inf), .bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf),
    .current_state_CPU(current_state), .dram_write_in(dram_write_in), .data_pc(data_pc)
    );

assign dram_write_in = rt_temp;
// next_state
always @ (*)
begin
  next_state = current_state;
  case(current_state)
    IDLE: 
    begin
      next_state = DRAM_READ_INST;
    end

    DRAM_READ_INST:
    begin
      if(rlast_m_inf[1]) next_state = DRAM_READ_INST_BUFFER;
    end

    DRAM_READ_INST_BUFFER:
    begin
      next_state = FETCH_INST;
    end

    FETCH_INST:
    begin
      next_state = DECODE;
    end

    DECODE:
    begin
      next_state = EXECUTE;
    end

    BUFFER:
    begin
      if(data_sram_empty == 0 ||data_pc>=data_start_pc+256||data_pc<data_start_pc)
      begin
        next_state = DRAM_READ_DATA;
      end

      else
      begin
        next_state = WAIT_SRAM_DATA;
      end
    end

    EXECUTE:
    begin
      case(opcode)
        3'b010: 
        begin
          next_state = BUFFER;
        end

        3'b011:
        begin
          next_state = STORE;
        end

        3'b100:
        begin
          next_state = CHECK_SRAM_RANGE;
        end

        3'b101:
        begin
          next_state = CHECK_SRAM_RANGE;
        end

        default:
          next_state = WRITE_BACK;
      endcase
    end

    DRAM_READ_DATA:
    begin
      if(rlast_m_inf[0]) next_state = DRAM_READ_DATA_BUFFER;
    end

    DRAM_READ_DATA_BUFFER:
    begin
      next_state = WAIT_SRAM_DATA;
    end

    WAIT_SRAM_DATA:
    begin
      next_state = WAIT_SRAM_DATA_BUFFER;
    end

    WAIT_SRAM_DATA_BUFFER:
    begin
      next_state = LOAD;
    end

    LOAD:
    begin
      if(inst_pc>=inst_start_pc+256||inst_pc<inst_start_pc)
      begin
        next_state = DRAM_READ_INST;
      end
      else
      begin
        next_state = DECODE;
      end
    end


    WRITE_BACK:
    begin
      next_state = WRTIE_BACK_BUFFER;
    end

    WRTIE_BACK_BUFFER:
    begin
      if(inst_pc>=inst_start_pc+256||inst_pc<inst_start_pc)
      begin
        next_state = DRAM_READ_INST;
      end
      else
      begin
        next_state = FETCH_INST;
      end
    end

    STORE:
    begin
      if(bvalid_m_inf)
      begin
        if(inst_pc>=inst_start_pc+256||inst_pc<inst_start_pc)
        begin
          next_state = DRAM_READ_INST;
        end
        else
        begin
          next_state = FETCH_INST;
        end
      end
    end

    CHECK_SRAM_RANGE:
    begin
      if(inst_pc>=inst_start_pc+256||inst_pc<inst_start_pc)
      begin
        next_state = DRAM_READ_INST;
      end
      else
      begin
        next_state = FETCH_INST;
      end
    end
  endcase
end

// data_sram_empty
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    data_sram_empty <= 0;
  end

  else
  begin
    if(current_state == LOAD)
    begin
      data_sram_empty <= 1;
    end
  end
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) IO_stall <= 1;
  else
  begin
    if(current_state == CHECK_SRAM_RANGE) IO_stall <= 0;
    else if(current_state == WRTIE_BACK_BUFFER ) IO_stall <= 0;
    else if(current_state == STORE && bvalid_m_inf) IO_stall <= 0;
    else if(current_state == LOAD) IO_stall <= 0;
    else IO_stall <= 1;
  end
end

// core
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    core_r0 <= 0;
    core_r1 <= 0;
    core_r2 <= 0;
    core_r3 <= 0;
    core_r4 <= 0;
    core_r5 <= 0;
    core_r6 <= 0;
    core_r7 <= 0;
    core_r8 <= 0;
    core_r9 <= 0;
    core_r10 <= 0;
    core_r11 <= 0;
    core_r11 <= 0;
    core_r12 <= 0;
    core_r13 <= 0;
    core_r14 <= 0;
    core_r15 <= 0;
  end

  else
  begin
    if(current_state == LOAD)
    begin
      case(rt)
        0: core_r0 <= DO_data;
        1: core_r1 <= DO_data;
        2: core_r2 <= DO_data;
        3: core_r3 <= DO_data;
        4: core_r4 <= DO_data;
        5: core_r5 <= DO_data;
        6: core_r6 <= DO_data;
        7: core_r7 <= DO_data;
        8: core_r8 <= DO_data;
        9: core_r9 <= DO_data;
        10: core_r10 <= DO_data;
        11: core_r11 <= DO_data;
        12: core_r12 <= DO_data;
        13: core_r13 <= DO_data;
        14: core_r14 <= DO_data;
        15: core_r15 <= DO_data;
      endcase
    end
    if(current_state == WRITE_BACK)
    begin
      case(rd)
        0: core_r0 <= rd_temp;
        1: core_r1 <= rd_temp;
        2: core_r2 <= rd_temp;
        3: core_r3 <= rd_temp;
        4: core_r4 <= rd_temp;
        5: core_r5 <= rd_temp;
        6: core_r6 <= rd_temp;
        7: core_r7 <= rd_temp;
        8: core_r8 <= rd_temp;
        9: core_r9 <= rd_temp;
        10: core_r10 <= rd_temp;
        11: core_r11 <= rd_temp;
        12: core_r12 <= rd_temp;
        13: core_r13 <= rd_temp;
        14: core_r14 <= rd_temp;
        15: core_r15 <= rd_temp;
      endcase
    end
  end
end

// opcode && rs && rt && rd && func && imm && addr_jump
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    opcode <= 0;
    rs <= 0;
    rt <= 0;
    rd <= 0;
    func <= 0;
    imm <= 0;
    addr_jump <= 0;
    
  end

  else
  begin
    if(current_state == DECODE)
    begin
      opcode <= DO_inst[15:13];
      rs <= DO_inst[12:9] ;
      rt <= DO_inst[8:5] ;
      rd <= DO_inst[4:1] ;
      func <= DO_inst[0] ;
      imm <= DO_inst[4:0] ;
      addr_jump <= DO_inst[12:0];
    end
  end
end

// rs_temp && rt_temp
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    rs_temp <= 0;
    rt_temp <= 0;
  end

  else
  begin
    if(current_state == DECODE)
    begin
      case(DO_inst[12:9])
        4'd0 : rs_temp <= core_r0;
        4'd1 : rs_temp <= core_r1;
        4'd2 : rs_temp <= core_r2;
        4'd3 : rs_temp <= core_r3;
        4'd4 : rs_temp <= core_r4;
        4'd5 : rs_temp <= core_r5;
        4'd6 : rs_temp <= core_r6;
        4'd7 : rs_temp <= core_r7;
        4'd8 : rs_temp <= core_r8;
        4'd9 : rs_temp <= core_r9;
        4'd10 : rs_temp <= core_r10;
        4'd11 : rs_temp <= core_r11;
        4'd12 : rs_temp <= core_r12;
        4'd13 : rs_temp <= core_r13;
        4'd14 : rs_temp <= core_r14;
        4'd15 : rs_temp <= core_r15;
      endcase

      case(DO_inst[8:5])
        4'd0 : rt_temp <= core_r0;
        4'd1 : rt_temp <= core_r1;
        4'd2 : rt_temp <= core_r2;
        4'd3 : rt_temp <= core_r3;
        4'd4 : rt_temp <= core_r4;
        4'd5 : rt_temp <= core_r5;
        4'd6 : rt_temp <= core_r6;
        4'd7 : rt_temp <= core_r7;
        4'd8 : rt_temp <= core_r8;
        4'd9 : rt_temp <= core_r9;
        4'd10 : rt_temp <= core_r10;
        4'd11 : rt_temp <= core_r11;
        4'd12 : rt_temp <= core_r12;
        4'd13 : rt_temp <= core_r13;
        4'd14 : rt_temp <= core_r14;
        4'd15 : rt_temp <= core_r15;
      endcase
    end
  end
end

// rd_temp
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    rd_temp <= 0;
  end

  else
  begin
    if(current_state == EXECUTE)
    begin
      if(opcode == 3'b000)
      begin
        if(func) rd_temp <= rs_temp - rt_temp;
        else rd_temp <= rs_temp + rt_temp;
      end

      else if(opcode === 3'b001)
      begin
        if(func) 
        begin
          rd_temp <= rs_temp * rt_temp;
        end

        else 
        begin
          if(rs_temp<rt_temp) rd_temp <= 16'd1;
          else rd_temp <= 16'd0;
        end
      end
    end
  end
end

assign inst_pc_signed = {1'b0,inst_pc};

// inst_pc
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) 
  begin
    inst_pc <= 0;
  end

  else
  begin
    if(current_state == EXECUTE)
    begin
      if(opcode == 3'b100 && rs_temp == rt_temp)
      begin
        inst_pc <= inst_pc_signed+2+imm*2;
      end

      else if(opcode == 3'b101)
      begin
        inst_pc <= addr_jump;
      end

      else
      begin
        inst_pc <= inst_pc + 2;
      end
    end
  end
end

// data_pc
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    data_pc <= 0;
  end

  else
  begin
    if(current_state == EXECUTE && opcode[1]==1'b1) // load && store
    begin
      data_pc<=(rs_temp+imm)<<1;
    end
  end
end

// // addr_data && DI_data && WEB_data
// always @ (*)
// begin
//   addr_data = 0;
//   DI_data = 0;
//   WEB_data = 1;
//   if(current_state == DRAM_READ_DATA)
//   begin
//     addr_data = addr_cnt;
//     WEB_data = 0;
//     DI_data = rdata_m_inf[15:0];
//   end

//   if(current_state == WAIT_SRAM_DATA)
//   begin
//     addr_data = (data_pc-data_start_pc)/2;
//   end

//   if(current_state == STORE && (data_pc>= data_start_pc && data_pc <= data_start_pc+255))
//   begin
//     addr_data = (data_pc-data_start_pc)/2;
//     WEB_data = 0;
//     DI_data = rt_temp;
//   end
// end

// r_data_temp
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    r_data_temp <= 0;
  end

  else
  begin
    r_data_temp <= rdata_m_inf;
  end
end

// addr_data && DI_data && WEB_data
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    addr_data <= 0;
    WEB_data <= 1;
    DI_data <= 0;
  end

  else
  begin
    if(current_state == DRAM_READ_DATA)
    begin
      addr_data <= addr_cnt;
      WEB_data <= 0;
      DI_data <= rdata_m_inf[15:0];
    end

    else if(current_state == WAIT_SRAM_DATA)
    begin
      addr_data <= (data_pc-data_start_pc)/2;
      WEB_data <= 1;
    end

    else if(current_state == STORE && (data_pc>= data_start_pc && data_pc <= data_start_pc+255))
    begin
      addr_data <= (data_pc-data_start_pc)/2;
      WEB_data <= 0;
      DI_data <= rt_temp;
    end

    else
    begin
      addr_data <= 0;
      WEB_data <= 1;
      DI_data <= 0;
    end
  end
end

// // addr_inst && DI_inst && WEB_inst
// always @ (*)
// begin
//   // DI_inst = 0;
//   // WEB_inst = 1;
//   // addr_inst = (inst_pc - inst_start_pc) / 2;
//   if(current_state == DRAM_READ_INST)
//   begin
//     if(rvalid_m_inf[1])
//     begin
//       addr_inst = addr_cnt;
//       WEB_inst = 0;
//       DI_inst = rdata_m_inf[31:16];
//     end
//     else
//     begin
//         DI_inst = 0;
//         WEB_inst = 1;
//         addr_inst = 0;
//     end
//   end

//   else
//   begin
//     addr_inst = (inst_pc - inst_start_pc) / 2;
//     DI_inst = 0;
//     WEB_inst = 1;
//   end
// end

// addr_inst && DI_inst && WEB_inst
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
      addr_inst <= 0;
      WEB_inst <= 1;
      DI_inst <= 0;
  end

  else
  begin
    if(current_state == DRAM_READ_INST)
    begin
      if(rvalid_m_inf[1])
      begin
        addr_inst <= addr_cnt;
        WEB_inst <= 0;
        DI_inst <= rdata_m_inf[31:16];
      end
    end

    else
    begin
      addr_inst <= (inst_pc - inst_start_pc) / 2;
      DI_inst <= 0;
      WEB_inst <= 1;
    end
  end
end


// addr_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    addr_cnt <= 0;
  end

  else
  begin
    if(|rvalid_m_inf) addr_cnt <= addr_cnt + 1;
  end
end

// current_state
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

endmodule

module AXI4_READ(
      // must port
      clk,
      rst_n,

      arid_m_inf,
      araddr_m_inf,
      arlen_m_inf,
      arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
      arready_m_inf,

      rid_m_inf,
      rdata_m_inf,
      rresp_m_inf,
      rlast_m_inf,
      rvalid_m_inf,
      rready_m_inf,

      // outside port
      current_state_CPU,
      inst_pc,
      inst_start_pc,
      data_pc,
      data_start_pc
    );

  //####################################################
  //               reg & wire & parameter
  //####################################################

  parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;
  parameter AR_VALID = 1'd0, R_VALID = 1'd1;

  // -----------------------------
  // axi read address channel 
  output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
  output  reg [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
  output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
  output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
  output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
  output  reg [DRAM_NUMBER-1:0]               arvalid_m_inf;
  input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
  // -----------------------------
  // axi read data channel 
  input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
  input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
  input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
  input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
  input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
  output  reg [DRAM_NUMBER-1:0]                 rready_m_inf;
  // -----------------------------
  input clk, rst_n;
  input wire [3:0] current_state_CPU;
  input wire [11:0] inst_pc;
  output reg [11:0] inst_start_pc;
  input wire [11:0] data_pc;
  output reg [11:0] data_start_pc;

  reg current_state, next_state;
  //####################################################
  //                   Design
  //####################################################
  assign arid_m_inf = 8'd0;
  assign arsize_m_inf = {3'b001,3'b001};
  assign arburst_m_inf = {2'd1,2'd1};
  assign arlen_m_inf = {7'd127,7'd127};

  // next_state
  always @ (*)
  begin
    next_state = current_state;
    // arvalid_m_inf = 2'b0;
    // araddr_m_inf = 0;
    rready_m_inf = 0;

    case(current_state)
      AR_VALID:
      begin
        if(current_state_CPU ==  4'd1 /* CPU DRAM READ INST aka DRAM_READ_INST*/)
        begin
          // arvalid_m_inf = 2'b10;
          // if (inst_pc>12'd3840) // celling's floor
          // begin
          //   araddr_m_inf = {20'h00001,12'd3840,16'd0,16'h1000};
          // end
          
          // else
          // begin
          //   araddr_m_inf = {20'h00001,inst_pc,16'd0,16'h1000};
          // end

          if(arready_m_inf[1])
          begin
            next_state = R_VALID;
          end
        end

        else if (current_state_CPU == 4'd8 /* CPU DRAM READ DATA aka DRAM_READ_DATA*/)
        begin
          // arvalid_m_inf = 2'b01;

          // if (data_pc>12'd3840) // celling's floor
          // begin
          //   araddr_m_inf = {20'h00001,12'd0,20'h00001,12'd3840};
          // end
          
          // else
          // begin
          //   araddr_m_inf = {20'h00001,12'd0,20'h00001,data_pc};
          // end

          if(arready_m_inf[0])
          begin
            next_state = R_VALID;
          end
        end

      end

      R_VALID:
      begin
        if(current_state_CPU == 4'd1 /* CPU DRAM READ INST aka DRAM_READ_INST*/)
        begin
          rready_m_inf = 2'b10;
          if(rlast_m_inf[1]) next_state = AR_VALID;
        end

        else if(current_state_CPU == 4'd8 /* CPU DRAM READ DATA aka DRAM_READ_DATA*/)
        begin
          rready_m_inf = 2'b01;
          if(rlast_m_inf[0]) next_state = AR_VALID;
        end
      end
    endcase
  end

  always @ (posedge clk or negedge rst_n)
  begin
    if(!rst_n)
    begin
      araddr_m_inf <= 0;
      arvalid_m_inf <= 0;
    end

    else
    begin
      if(next_state == R_VALID)
      begin
        araddr_m_inf <= 0;
        arvalid_m_inf <= 0;
      end
      else if(current_state_CPU ==  4'd1 /* CPU DRAM READ INST aka DRAM_READ_INST*/ && current_state == AR_VALID)
      begin
        arvalid_m_inf <= 2'b10;
        if (inst_pc>12'd3840) // celling's floor
        begin
          araddr_m_inf <= {20'h00001,12'd3840,16'd0,16'h1000};
        end
        else
        begin
          araddr_m_inf <= {20'h00001,inst_pc,16'd0,16'h1000};
        end
      end

      else if(current_state_CPU == 4'd8 /* CPU DRAM READ DATA aka DRAM_READ_DATA*/ && current_state == AR_VALID)
      begin
          arvalid_m_inf <= 2'b01;
          if (data_pc>12'd3840) // celling's floor
          begin
            araddr_m_inf <= {20'h00001,12'd0,20'h00001,12'd3840};
          end
          
          else
          begin
            araddr_m_inf <= {20'h00001,12'd0,20'h00001,data_pc};
          end
      end
    end
  end

  // inst_start_pc
  always @ (posedge clk or negedge rst_n)
  begin
    if(!rst_n)
    begin
      inst_start_pc <= 0;
    end

    else
    begin
      if(current_state == AR_VALID && current_state_CPU == 4'd1 /* CPU DRAM READ INST aka DRAM_READ_INST*/)
      begin
        if(inst_pc>12'd3840)
        begin
          inst_start_pc <= 12'd3840;
        end

        else
        begin
          inst_start_pc <= inst_pc;
        end
      end
    end
  end

  // data_start_pc
  always @ (posedge clk or negedge rst_n)
  begin
    if(!rst_n)
    begin
      data_start_pc <= 0;
    end

    else
    begin
      if(current_state == AR_VALID && current_state_CPU == 4'd8 /* CPU DRAM READ DATA aka DRAM_READ_DATA*/)
      begin
        if(data_pc>12'd3840)
        begin
          data_start_pc <= 12'd3840;
        end

        else
        begin
          data_start_pc <= data_pc;
        end
      end
    end
  end

  // current_state
  always @ (posedge clk or negedge rst_n)
  begin
    if(!rst_n)
    begin
      current_state <= AR_VALID;
    end
    
    else
    begin
      current_state <= next_state;
    end
  end
endmodule

module AXI_WRITE(
    clk,
		rst_n,

    awid_m_inf,
    awaddr_m_inf,
    awsize_m_inf,
    awburst_m_inf,
    awlen_m_inf,
    awvalid_m_inf,
    awready_m_inf,

    wdata_m_inf,
    wlast_m_inf,
    wvalid_m_inf,
    wready_m_inf,

    bid_m_inf,
    bresp_m_inf,
    bvalid_m_inf,
    bready_m_inf,

    current_state_CPU,
    dram_write_in,

    data_pc
    );

    parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

    // axi write address channel 
    output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
    output  reg [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
    output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
    output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
    output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
    output  reg [WRIT_NUMBER-1:0]                awvalid_m_inf;
    input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
    // axi write data channel 
    output  reg [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
    output  reg [WRIT_NUMBER-1:0]                  wlast_m_inf;
    output  reg [WRIT_NUMBER-1:0]                 wvalid_m_inf;
    input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
    // axi write response channel
    input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
    input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
    input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
    output  reg [WRIT_NUMBER-1:0]                 bready_m_inf;

    input clk, rst_n;
    input wire [3:0] current_state_CPU;
    input wire [15:0] dram_write_in;
    input wire [11:0] data_pc;

  //####################################################
  //               reg & wire & parameter
  //####################################################
  parameter AW_VALID = 2'd0;
	parameter W_VALID = 2'd1;

  reg current_state, next_state;
  reg [15:0] w_data;
  assign awid_m_inf = 4'b0;
	assign awburst_m_inf = 2'b01;
	assign awsize_m_inf = 3'b001;
  assign awlen_m_inf = 8'b0;

  assign wdata_m_inf = dram_write_in;

  always @ (*)
  begin
    next_state = current_state;
    awvalid_m_inf = 0;
    awaddr_m_inf = 0;
    wvalid_m_inf = 0;
    bready_m_inf = 0;
    wlast_m_inf = 0;
    case(current_state)
      AW_VALID:
      begin
        if(current_state_CPU ==  4'd5 /*DRAM WRITE DATA aka STORE*/)
        begin
          awvalid_m_inf = 1;
          awaddr_m_inf = {20'h00001,12'd0,20'h00001,data_pc};
          if(awready_m_inf) next_state = W_VALID;
        end
      end

      W_VALID:
      begin
        wvalid_m_inf = 1;
        bready_m_inf = 1;
        wlast_m_inf = 1;
        if(bvalid_m_inf) next_state = AW_VALID;
      end
    endcase
  end

  always @ (posedge clk or negedge rst_n)
  begin
    if(!rst_n)
    begin
      current_state <= AW_VALID;
    end

    else
    begin
      current_state <= next_state;
    end
  end
endmodule