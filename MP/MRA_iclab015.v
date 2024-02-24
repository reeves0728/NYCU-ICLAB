//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
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
	   bready_m_inf 
);
// ===============================================================
//  					Input / Output 
// ===============================================================
// ===============================================================
//  					Parameter Declaration 
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify AXI4 Parameter
parameter NUM_ROW = 64, NUM_COLUMN = 64; 				
parameter MAX_NUM_MACRO = 15;


// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;     
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

parameter IDLE = 4'd0;
parameter INPUT = 4'd1;
parameter DRAM_READ = 4'd2;
parameter DRAM_WRITE = 4'd3;
parameter INIT_BFS = 4'd4;
parameter BFS = 4'd5;
parameter TRACE_BACK = 4'd6;
parameter WAIT_WEIGHT = 4'd7;
parameter CLEAR_MAP = 4'd8;
parameter OUTPUT = 4'd9;

integer i;
integer j;

// ===============================================================
//  					Reg declaration 
// ===============================================================
reg [3:0] current_state, next_state;
reg [4:0] frame_id_reg;
reg [DATA_WIDTH-1:0] dram_read_out;
reg [DATA_WIDTH-1:0] dram_write_in;
reg input_cnt;
reg [5:0] start_x [0:14];
reg [5:0] target_x [0:14];
reg [5:0] start_y [0:14];
reg [5:0] target_y [0:14];
reg [3:0] net_num;
reg [3:0] net_id_reg [0:14];

reg [6:0] addr_location_map;
reg [127:0] DO_location_map;
reg [127:0] DI_location_map;
reg WEB_location_map;

reg [6:0] addr_weight_map;
reg [127:0] DO_weight_map;
reg [127:0] DI_weight_map;
reg WEB_weight_map;

reg [1:0] temp_map[0:63][0:63];
reg map_select;
reg [6:0] addr_location_cnt;
reg [3:0] op_net_num;
reg [1:0] cnt_4;
reg [1:0] fill_value;
reg back_1_cnt;


MAP_SP Location_Map(
.A0  (addr_location_map[0]),  .A1  (addr_location_map[1]),   .A2  (addr_location_map[2]),   .A3  (addr_location_map[3]),   .A4  (addr_location_map[4]),   .A5  (addr_location_map[5]),   .A6  (addr_location_map[6]),

.DO0 (DO_location_map[0]),   .DO1 (DO_location_map[1]),   .DO2 (DO_location_map[2]),   .DO3 (DO_location_map[3]),   .DO4 (DO_location_map[4]),   .DO5 (DO_location_map[5]),   .DO6 (DO_location_map[6]),   .DO7 (DO_location_map[7]),
.DO8 (DO_location_map[8]),   .DO9 (DO_location_map[9]),   .DO10(DO_location_map[10]),  .DO11(DO_location_map[11]),  .DO12(DO_location_map[12]),  .DO13(DO_location_map[13]),  .DO14(DO_location_map[14]),  .DO15(DO_location_map[15]),
.DO16(DO_location_map[16]),  .DO17(DO_location_map[17]),  .DO18(DO_location_map[18]),  .DO19(DO_location_map[19]),  .DO20(DO_location_map[20]),  .DO21(DO_location_map[21]),  .DO22(DO_location_map[22]),  .DO23(DO_location_map[23]),
.DO24(DO_location_map[24]),  .DO25(DO_location_map[25]),  .DO26(DO_location_map[26]),  .DO27(DO_location_map[27]),  .DO28(DO_location_map[28]),  .DO29(DO_location_map[29]),  .DO30(DO_location_map[30]),  .DO31(DO_location_map[31]),
.DO32(DO_location_map[32]),  .DO33(DO_location_map[33]),  .DO34(DO_location_map[34]),  .DO35(DO_location_map[35]),  .DO36(DO_location_map[36]),  .DO37(DO_location_map[37]),  .DO38(DO_location_map[38]),  .DO39(DO_location_map[39]),
.DO40(DO_location_map[40]),  .DO41(DO_location_map[41]),  .DO42(DO_location_map[42]),  .DO43(DO_location_map[43]),  .DO44(DO_location_map[44]),  .DO45(DO_location_map[45]),  .DO46(DO_location_map[46]),  .DO47(DO_location_map[47]),
.DO48(DO_location_map[48]),  .DO49(DO_location_map[49]),  .DO50(DO_location_map[50]),  .DO51(DO_location_map[51]),  .DO52(DO_location_map[52]),  .DO53(DO_location_map[53]),  .DO54(DO_location_map[54]),  .DO55(DO_location_map[55]),
.DO56(DO_location_map[56]),  .DO57(DO_location_map[57]),  .DO58(DO_location_map[58]),  .DO59(DO_location_map[59]),  .DO60(DO_location_map[60]),  .DO61(DO_location_map[61]),  .DO62(DO_location_map[62]),  .DO63(DO_location_map[63]),
.DO64(DO_location_map[64]),  .DO65(DO_location_map[65]),  .DO66(DO_location_map[66]),  .DO67(DO_location_map[67]),  .DO68(DO_location_map[68]),  .DO69(DO_location_map[69]),  .DO70(DO_location_map[70]),  .DO71(DO_location_map[71]),
.DO72(DO_location_map[72]),  .DO73(DO_location_map[73]),  .DO74(DO_location_map[74]),  .DO75(DO_location_map[75]),  .DO76(DO_location_map[76]),  .DO77(DO_location_map[77]),  .DO78(DO_location_map[78]),  .DO79(DO_location_map[79]),
.DO80(DO_location_map[80]),  .DO81(DO_location_map[81]),  .DO82(DO_location_map[82]),  .DO83(DO_location_map[83]),  .DO84(DO_location_map[84]),  .DO85(DO_location_map[85]),  .DO86(DO_location_map[86]),  .DO87(DO_location_map[87]),
.DO88(DO_location_map[88]),  .DO89(DO_location_map[89]),  .DO90(DO_location_map[90]),  .DO91(DO_location_map[91]),  .DO92(DO_location_map[92]),  .DO93(DO_location_map[93]),  .DO94(DO_location_map[94]),  .DO95(DO_location_map[95]),
.DO96(DO_location_map[96]),  .DO97(DO_location_map[97]),  .DO98(DO_location_map[98]),  .DO99(DO_location_map[99]),  .DO100(DO_location_map[100]),.DO101(DO_location_map[101]),.DO102(DO_location_map[102]),.DO103(DO_location_map[103]),
.DO104(DO_location_map[104]),.DO105(DO_location_map[105]),.DO106(DO_location_map[106]),.DO107(DO_location_map[107]),.DO108(DO_location_map[108]),.DO109(DO_location_map[109]),.DO110(DO_location_map[110]),.DO111(DO_location_map[111]),
.DO112(DO_location_map[112]),.DO113(DO_location_map[113]),.DO114(DO_location_map[114]),.DO115(DO_location_map[115]),.DO116(DO_location_map[116]),.DO117(DO_location_map[117]),.DO118(DO_location_map[118]),.DO119(DO_location_map[119]),
.DO120(DO_location_map[120]),.DO121(DO_location_map[121]),.DO122(DO_location_map[122]),.DO123(DO_location_map[123]),.DO124(DO_location_map[124]),.DO125(DO_location_map[125]),.DO126(DO_location_map[126]),.DO127(DO_location_map[127]),

.DI0 (DI_location_map[0]),   .DI1 (DI_location_map[1]),   .DI2 (DI_location_map[2]),   .DI3 (DI_location_map[3]),   .DI4 (DI_location_map[4]),   .DI5 (DI_location_map[5]),   .DI6 (DI_location_map[6]),   .DI7 (DI_location_map[7]),
.DI8 (DI_location_map[8]),   .DI9 (DI_location_map[9]),   .DI10(DI_location_map[10]),  .DI11(DI_location_map[11]),  .DI12(DI_location_map[12]),  .DI13(DI_location_map[13]),  .DI14(DI_location_map[14]),  .DI15(DI_location_map[15]),
.DI16(DI_location_map[16]),  .DI17(DI_location_map[17]),  .DI18(DI_location_map[18]),  .DI19(DI_location_map[19]),  .DI20(DI_location_map[20]),  .DI21(DI_location_map[21]),  .DI22(DI_location_map[22]),  .DI23(DI_location_map[23]),
.DI24(DI_location_map[24]),  .DI25(DI_location_map[25]),  .DI26(DI_location_map[26]),  .DI27(DI_location_map[27]),  .DI28(DI_location_map[28]),  .DI29(DI_location_map[29]),  .DI30(DI_location_map[30]),  .DI31(DI_location_map[31]),
.DI32(DI_location_map[32]),  .DI33(DI_location_map[33]),  .DI34(DI_location_map[34]),  .DI35(DI_location_map[35]),  .DI36(DI_location_map[36]),  .DI37(DI_location_map[37]),  .DI38(DI_location_map[38]),  .DI39(DI_location_map[39]),
.DI40(DI_location_map[40]),  .DI41(DI_location_map[41]),  .DI42(DI_location_map[42]),  .DI43(DI_location_map[43]),  .DI44(DI_location_map[44]),  .DI45(DI_location_map[45]),  .DI46(DI_location_map[46]),  .DI47(DI_location_map[47]),
.DI48(DI_location_map[48]),  .DI49(DI_location_map[49]),  .DI50(DI_location_map[50]),  .DI51(DI_location_map[51]),  .DI52(DI_location_map[52]),  .DI53(DI_location_map[53]),  .DI54(DI_location_map[54]),  .DI55(DI_location_map[55]),
.DI56(DI_location_map[56]),  .DI57(DI_location_map[57]),  .DI58(DI_location_map[58]),  .DI59(DI_location_map[59]),  .DI60(DI_location_map[60]),  .DI61(DI_location_map[61]),  .DI62(DI_location_map[62]),  .DI63(DI_location_map[63]),
.DI64(DI_location_map[64]),  .DI65(DI_location_map[65]),  .DI66(DI_location_map[66]),  .DI67(DI_location_map[67]),  .DI68(DI_location_map[68]),  .DI69(DI_location_map[69]),  .DI70(DI_location_map[70]),  .DI71(DI_location_map[71]),
.DI72(DI_location_map[72]),  .DI73(DI_location_map[73]),  .DI74(DI_location_map[74]),  .DI75(DI_location_map[75]),  .DI76(DI_location_map[76]),  .DI77(DI_location_map[77]),  .DI78(DI_location_map[78]),  .DI79(DI_location_map[79]),
.DI80(DI_location_map[80]),  .DI81(DI_location_map[81]),  .DI82(DI_location_map[82]),  .DI83(DI_location_map[83]),  .DI84(DI_location_map[84]),  .DI85(DI_location_map[85]),  .DI86(DI_location_map[86]),  .DI87(DI_location_map[87]),
.DI88(DI_location_map[88]),  .DI89(DI_location_map[89]),  .DI90(DI_location_map[90]),  .DI91(DI_location_map[91]),  .DI92(DI_location_map[92]),  .DI93(DI_location_map[93]),  .DI94(DI_location_map[94]),  .DI95(DI_location_map[95]),
.DI96(DI_location_map[96]),  .DI97(DI_location_map[97]),  .DI98(DI_location_map[98]),  .DI99(DI_location_map[99]),  .DI100(DI_location_map[100]),.DI101(DI_location_map[101]),.DI102(DI_location_map[102]),.DI103(DI_location_map[103]),
.DI104(DI_location_map[104]),.DI105(DI_location_map[105]),.DI106(DI_location_map[106]),.DI107(DI_location_map[107]),.DI108(DI_location_map[108]),.DI109(DI_location_map[109]),.DI110(DI_location_map[110]),.DI111(DI_location_map[111]),
.DI112(DI_location_map[112]),.DI113(DI_location_map[113]),.DI114(DI_location_map[114]),.DI115(DI_location_map[115]),.DI116(DI_location_map[116]),.DI117(DI_location_map[117]),.DI118(DI_location_map[118]),.DI119(DI_location_map[119]),
.DI120(DI_location_map[120]),.DI121(DI_location_map[121]),.DI122(DI_location_map[122]),.DI123(DI_location_map[123]),.DI124(DI_location_map[124]),.DI125(DI_location_map[125]),.DI126(DI_location_map[126]),.DI127(DI_location_map[127]),

.CK(clk), .WEB(WEB_location_map), .OE(1'b1), .CS(1'b1));


MAP_SP Weight_Map(
.A0  (addr_weight_map[0]),   .A1  (addr_weight_map[1]),   .A2  (addr_weight_map[2]),   .A3  (addr_weight_map[3]),   .A4  (addr_weight_map[4]),   .A5  (addr_weight_map[5]),   .A6  (addr_weight_map[6]),

.DO0 (DO_weight_map[0]),   .DO1 (DO_weight_map[1]),   .DO2 (DO_weight_map[2]),   .DO3 (DO_weight_map[3]),   .DO4 (DO_weight_map[4]),   .DO5 (DO_weight_map[5]),   .DO6 (DO_weight_map[6]),   .DO7 (DO_weight_map[7]),
.DO8 (DO_weight_map[8]),   .DO9 (DO_weight_map[9]),   .DO10(DO_weight_map[10]),  .DO11(DO_weight_map[11]),  .DO12(DO_weight_map[12]),  .DO13(DO_weight_map[13]),  .DO14(DO_weight_map[14]),  .DO15(DO_weight_map[15]),
.DO16(DO_weight_map[16]),  .DO17(DO_weight_map[17]),  .DO18(DO_weight_map[18]),  .DO19(DO_weight_map[19]),  .DO20(DO_weight_map[20]),  .DO21(DO_weight_map[21]),  .DO22(DO_weight_map[22]),  .DO23(DO_weight_map[23]),
.DO24(DO_weight_map[24]),  .DO25(DO_weight_map[25]),  .DO26(DO_weight_map[26]),  .DO27(DO_weight_map[27]),  .DO28(DO_weight_map[28]),  .DO29(DO_weight_map[29]),  .DO30(DO_weight_map[30]),  .DO31(DO_weight_map[31]),
.DO32(DO_weight_map[32]),  .DO33(DO_weight_map[33]),  .DO34(DO_weight_map[34]),  .DO35(DO_weight_map[35]),  .DO36(DO_weight_map[36]),  .DO37(DO_weight_map[37]),  .DO38(DO_weight_map[38]),  .DO39(DO_weight_map[39]),
.DO40(DO_weight_map[40]),  .DO41(DO_weight_map[41]),  .DO42(DO_weight_map[42]),  .DO43(DO_weight_map[43]),  .DO44(DO_weight_map[44]),  .DO45(DO_weight_map[45]),  .DO46(DO_weight_map[46]),  .DO47(DO_weight_map[47]),
.DO48(DO_weight_map[48]),  .DO49(DO_weight_map[49]),  .DO50(DO_weight_map[50]),  .DO51(DO_weight_map[51]),  .DO52(DO_weight_map[52]),  .DO53(DO_weight_map[53]),  .DO54(DO_weight_map[54]),  .DO55(DO_weight_map[55]),
.DO56(DO_weight_map[56]),  .DO57(DO_weight_map[57]),  .DO58(DO_weight_map[58]),  .DO59(DO_weight_map[59]),  .DO60(DO_weight_map[60]),  .DO61(DO_weight_map[61]),  .DO62(DO_weight_map[62]),  .DO63(DO_weight_map[63]),
.DO64(DO_weight_map[64]),  .DO65(DO_weight_map[65]),  .DO66(DO_weight_map[66]),  .DO67(DO_weight_map[67]),  .DO68(DO_weight_map[68]),  .DO69(DO_weight_map[69]),  .DO70(DO_weight_map[70]),  .DO71(DO_weight_map[71]),
.DO72(DO_weight_map[72]),  .DO73(DO_weight_map[73]),  .DO74(DO_weight_map[74]),  .DO75(DO_weight_map[75]),  .DO76(DO_weight_map[76]),  .DO77(DO_weight_map[77]),  .DO78(DO_weight_map[78]),  .DO79(DO_weight_map[79]),
.DO80(DO_weight_map[80]),  .DO81(DO_weight_map[81]),  .DO82(DO_weight_map[82]),  .DO83(DO_weight_map[83]),  .DO84(DO_weight_map[84]),  .DO85(DO_weight_map[85]),  .DO86(DO_weight_map[86]),  .DO87(DO_weight_map[87]),
.DO88(DO_weight_map[88]),  .DO89(DO_weight_map[89]),  .DO90(DO_weight_map[90]),  .DO91(DO_weight_map[91]),  .DO92(DO_weight_map[92]),  .DO93(DO_weight_map[93]),  .DO94(DO_weight_map[94]),  .DO95(DO_weight_map[95]),
.DO96(DO_weight_map[96]),  .DO97(DO_weight_map[97]),  .DO98(DO_weight_map[98]),  .DO99(DO_weight_map[99]),  .DO100(DO_weight_map[100]),.DO101(DO_weight_map[101]),.DO102(DO_weight_map[102]),.DO103(DO_weight_map[103]),
.DO104(DO_weight_map[104]),.DO105(DO_weight_map[105]),.DO106(DO_weight_map[106]),.DO107(DO_weight_map[107]),.DO108(DO_weight_map[108]),.DO109(DO_weight_map[109]),.DO110(DO_weight_map[110]),.DO111(DO_weight_map[111]),
.DO112(DO_weight_map[112]),.DO113(DO_weight_map[113]),.DO114(DO_weight_map[114]),.DO115(DO_weight_map[115]),.DO116(DO_weight_map[116]),.DO117(DO_weight_map[117]),.DO118(DO_weight_map[118]),.DO119(DO_weight_map[119]),
.DO120(DO_weight_map[120]),.DO121(DO_weight_map[121]),.DO122(DO_weight_map[122]),.DO123(DO_weight_map[123]),.DO124(DO_weight_map[124]),.DO125(DO_weight_map[125]),.DO126(DO_weight_map[126]),.DO127(DO_weight_map[127]),

.DI0 (DI_weight_map[0]),   .DI1 (DI_weight_map[1]),   .DI2 (DI_weight_map[2]),   .DI3 (DI_weight_map[3]),   .DI4 (DI_weight_map[4]),   .DI5 (DI_weight_map[5]),   .DI6 (DI_weight_map[6]),   .DI7 (DI_weight_map[7]),
.DI8 (DI_weight_map[8]),   .DI9 (DI_weight_map[9]),   .DI10(DI_weight_map[10]),  .DI11(DI_weight_map[11]),  .DI12(DI_weight_map[12]),  .DI13(DI_weight_map[13]),  .DI14(DI_weight_map[14]),  .DI15(DI_weight_map[15]),
.DI16(DI_weight_map[16]),  .DI17(DI_weight_map[17]),  .DI18(DI_weight_map[18]),  .DI19(DI_weight_map[19]),  .DI20(DI_weight_map[20]),  .DI21(DI_weight_map[21]),  .DI22(DI_weight_map[22]),  .DI23(DI_weight_map[23]),
.DI24(DI_weight_map[24]),  .DI25(DI_weight_map[25]),  .DI26(DI_weight_map[26]),  .DI27(DI_weight_map[27]),  .DI28(DI_weight_map[28]),  .DI29(DI_weight_map[29]),  .DI30(DI_weight_map[30]),  .DI31(DI_weight_map[31]),
.DI32(DI_weight_map[32]),  .DI33(DI_weight_map[33]),  .DI34(DI_weight_map[34]),  .DI35(DI_weight_map[35]),  .DI36(DI_weight_map[36]),  .DI37(DI_weight_map[37]),  .DI38(DI_weight_map[38]),  .DI39(DI_weight_map[39]),
.DI40(DI_weight_map[40]),  .DI41(DI_weight_map[41]),  .DI42(DI_weight_map[42]),  .DI43(DI_weight_map[43]),  .DI44(DI_weight_map[44]),  .DI45(DI_weight_map[45]),  .DI46(DI_weight_map[46]),  .DI47(DI_weight_map[47]),
.DI48(DI_weight_map[48]),  .DI49(DI_weight_map[49]),  .DI50(DI_weight_map[50]),  .DI51(DI_weight_map[51]),  .DI52(DI_weight_map[52]),  .DI53(DI_weight_map[53]),  .DI54(DI_weight_map[54]),  .DI55(DI_weight_map[55]),
.DI56(DI_weight_map[56]),  .DI57(DI_weight_map[57]),  .DI58(DI_weight_map[58]),  .DI59(DI_weight_map[59]),  .DI60(DI_weight_map[60]),  .DI61(DI_weight_map[61]),  .DI62(DI_weight_map[62]),  .DI63(DI_weight_map[63]),
.DI64(DI_weight_map[64]),  .DI65(DI_weight_map[65]),  .DI66(DI_weight_map[66]),  .DI67(DI_weight_map[67]),  .DI68(DI_weight_map[68]),  .DI69(DI_weight_map[69]),  .DI70(DI_weight_map[70]),  .DI71(DI_weight_map[71]),
.DI72(DI_weight_map[72]),  .DI73(DI_weight_map[73]),  .DI74(DI_weight_map[74]),  .DI75(DI_weight_map[75]),  .DI76(DI_weight_map[76]),  .DI77(DI_weight_map[77]),  .DI78(DI_weight_map[78]),  .DI79(DI_weight_map[79]),
.DI80(DI_weight_map[80]),  .DI81(DI_weight_map[81]),  .DI82(DI_weight_map[82]),  .DI83(DI_weight_map[83]),  .DI84(DI_weight_map[84]),  .DI85(DI_weight_map[85]),  .DI86(DI_weight_map[86]),  .DI87(DI_weight_map[87]),
.DI88(DI_weight_map[88]),  .DI89(DI_weight_map[89]),  .DI90(DI_weight_map[90]),  .DI91(DI_weight_map[91]),  .DI92(DI_weight_map[92]),  .DI93(DI_weight_map[93]),  .DI94(DI_weight_map[94]),  .DI95(DI_weight_map[95]),
.DI96(DI_weight_map[96]),  .DI97(DI_weight_map[97]),  .DI98(DI_weight_map[98]),  .DI99(DI_weight_map[99]),  .DI100(DI_weight_map[100]),.DI101(DI_weight_map[101]),.DI102(DI_weight_map[102]),.DI103(DI_weight_map[103]),
.DI104(DI_weight_map[104]),.DI105(DI_weight_map[105]),.DI106(DI_weight_map[106]),.DI107(DI_weight_map[107]),.DI108(DI_weight_map[108]),.DI109(DI_weight_map[109]),.DI110(DI_weight_map[110]),.DI111(DI_weight_map[111]),
.DI112(DI_weight_map[112]),.DI113(DI_weight_map[113]),.DI114(DI_weight_map[114]),.DI115(DI_weight_map[115]),.DI116(DI_weight_map[116]),.DI117(DI_weight_map[117]),.DI118(DI_weight_map[118]),.DI119(DI_weight_map[119]),
.DI120(DI_weight_map[120]),.DI121(DI_weight_map[121]),.DI122(DI_weight_map[122]),.DI123(DI_weight_map[123]),.DI124(DI_weight_map[124]),.DI125(DI_weight_map[125]),.DI126(DI_weight_map[126]),.DI127(DI_weight_map[127]),

.CK(clk), .WEB(WEB_weight_map), .OE(1'b1), .CS(1'b1));

AXI4_READ INF_AXI4_READ(
	.clk(clk), .rst_n(rst_n), .current_state(current_state), .map_select(map_select) ,.frame_id_reg(frame_id_reg), .dram_read_out(dram_read_out),
	.arid_m_inf(arid_m_inf),
	.arburst_m_inf(arburst_m_inf), .arsize_m_inf(arsize_m_inf), .arlen_m_inf(arlen_m_inf), 
	.arvalid_m_inf(arvalid_m_inf), .arready_m_inf(arready_m_inf), .araddr_m_inf(araddr_m_inf),
	.rid_m_inf(rid_m_inf),
	.rvalid_m_inf(rvalid_m_inf), .rready_m_inf(rready_m_inf), .rdata_m_inf(rdata_m_inf),
	.rlast_m_inf(rlast_m_inf), .rresp_m_inf(rresp_m_inf)
);

AXI4_WRITE INF_AXI4_WRITE(
	.clk(clk),.rst_n(rst_n),.current_state(current_state),.dram_write_in(dram_write_in),.frame_id_reg(frame_id_reg),
	.awid_m_inf(awid_m_inf),.awaddr_m_inf(awaddr_m_inf),.awsize_m_inf(awsize_m_inf),.awburst_m_inf(awburst_m_inf),.awlen_m_inf(awlen_m_inf),.awvalid_m_inf(awvalid_m_inf),.awready_m_inf(awready_m_inf),
	.wdata_m_inf(wdata_m_inf),.wlast_m_inf(wlast_m_inf),.wvalid_m_inf(wvalid_m_inf),.wready_m_inf(wready_m_inf),
	.bid_m_inf(bid_m_inf),.bresp_m_inf(bresp_m_inf),.bvalid_m_inf(bvalid_m_inf),.bready_m_inf(bready_m_inf) 
);



wire [5:0] offset;
assign offset = addr_location_cnt[0] ? 6'd32 : 6'd0;

reg trace_back_d1;
reg trace_back_d2;
wire  next_state_IDLE;
wire  next_state_INPUT;
assign next_state_IDLE = next_state == IDLE;
assign next_state_INPUT = next_state == INPUT;


wire  current_state_trace_back;
assign current_state_trace_back = current_state == TRACE_BACK;

wire  current_state_BFS;
assign current_state_BFS = current_state == BFS;

wire current_state_clear_map;
assign current_state_clear_map = current_state == CLEAR_MAP;


reg [5:0] trace_back_x;
reg [5:0] trace_back_y;
reg [3:0] weight_reg;




// next_state
always @ (*)
begin
	next_state = 0;
	case(current_state)
	IDLE:
	begin
		if(in_valid == 1'b1) next_state = INPUT;
		else next_state = IDLE;
	end

	INPUT:
	begin
		if(in_valid == 1'b0) next_state = DRAM_READ;
		else next_state = INPUT;
	end

	DRAM_READ:
	begin
		if(rlast_m_inf == 1) next_state = INIT_BFS;
		else next_state = DRAM_READ;
	end	

	INIT_BFS:
	begin
		next_state = BFS;
	end

	BFS:
	begin
		if(temp_map[target_y[op_net_num]][target_x[op_net_num]][1] && op_net_num==0) next_state = WAIT_WEIGHT;
		else if(temp_map[target_y[op_net_num]][target_x[op_net_num]][1]) next_state = TRACE_BACK;
		else next_state = BFS;
	end

	WAIT_WEIGHT:
	begin
		if(rlast_m_inf == 1) next_state = TRACE_BACK;
		else next_state = WAIT_WEIGHT;
	end

	TRACE_BACK:
	begin
		if(start_x[op_net_num] == trace_back_x && start_y[op_net_num] == trace_back_y)
		begin
			if(op_net_num+1 == net_num) next_state = DRAM_WRITE;
			else next_state = CLEAR_MAP;
		end
		else next_state = TRACE_BACK;
	end

	CLEAR_MAP:
	begin
		next_state = INIT_BFS;
	end

	DRAM_WRITE:
	begin
		if(bvalid_m_inf) next_state = OUTPUT;
		else next_state = DRAM_WRITE;
	end

	OUTPUT:
	begin
		next_state = IDLE;
	end
	endcase
end

wire start_weight;
reg [1:0] delay_cnt;

assign start_weight = delay_cnt == 3;

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) delay_cnt <= 0;
	else
	begin
		if(current_state_BFS) delay_cnt <= 0; 
		else if(delay_cnt == 3) delay_cnt <= delay_cnt;
		else if(trace_back_d2 == 1) delay_cnt <= delay_cnt + 1;
	end
end



// map_select
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) map_select <= 0;
	else
	begin
		if(map_select == 0 && rlast_m_inf == 1) map_select <= 1;
		else if(map_select == 1 && rlast_m_inf == 1) map_select <= 0;
	end
end

// addr_weight_map && DI_weight_map && WEB_weight_map
always @ (*)
begin
	addr_weight_map = 0;
	DI_weight_map = 0;
	WEB_weight_map = 1;
	if(rvalid_m_inf == 1 && map_select == 1)
	begin
		WEB_weight_map = 0;
		addr_weight_map = addr_location_cnt;
		DI_weight_map = dram_read_out;
	end

	else if(trace_back_d2 && !back_1_cnt)
	begin
		addr_weight_map = {trace_back_y,trace_back_x[5]};
	end
end

assign weight_reg = DO_weight_map[4*trace_back_x[4:0]+:4];

wire [6:0] addr_location_cnt_p1;
assign addr_location_cnt_p1 = addr_location_cnt + 1;

// addr_location_map && DI_location_map && WEB_location_map
always @ (*)
begin
	addr_location_map = 0;
	if(rvalid_m_inf == 1 && map_select == 0)
	begin
		addr_location_map = addr_location_cnt;
	end

	else if(current_state_trace_back && !back_1_cnt)
	begin
		addr_location_map = {trace_back_y,trace_back_x[5]};
	end

	else if(current_state_trace_back && back_1_cnt)
	begin
		addr_location_map = {trace_back_y,trace_back_x[5]};
	end

	else if(current_state == DRAM_WRITE)
	begin
		if(wready_m_inf) addr_location_map = addr_location_cnt_p1;
		else addr_location_map = addr_location_cnt;
	end
end

always @ (*)
begin
	DI_location_map = 0;
	if(rvalid_m_inf == 1 && map_select == 0)
	begin
		DI_location_map = dram_read_out;
	end


	else if(current_state_trace_back && back_1_cnt)
	begin
		for(i=0;i<32;i=i+1)
		begin
			if(trace_back_x[4:0] == i)
				DI_location_map[i*4+:4] = net_id_reg[op_net_num];
			else
				DI_location_map[i*4+:4] = DO_location_map[i*4+:4];
		end
	end
end

always @ (*)
begin
	WEB_location_map = 1;
	if(rvalid_m_inf == 1 && map_select == 0)
	begin
		WEB_location_map = 0;
	end

	else if(current_state_trace_back && back_1_cnt)
	begin
		WEB_location_map = 0;
	end
end


// addr_location_cnt
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) addr_location_cnt <= 0;
	else
	begin	
		if(next_state_IDLE) addr_location_cnt <= 0;

		else if(rvalid_m_inf == 1)
		begin
			addr_location_cnt <= addr_location_cnt + 1;
		end

		else if(wready_m_inf == 1)
		begin
			addr_location_cnt <= addr_location_cnt + 1;
		end
	end
end

// dram_write_in
assign dram_write_in = DO_location_map;

// temp_map
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		for(i=0;i<64;i=i+1)
			for(j=0;j<64;j=j+1)
				temp_map[i][j] <= 0;
	end

	else
	begin
		if(current_state == DRAM_READ)
		begin
			if(rvalid_m_inf == 1)
			begin
				temp_map[addr_location_cnt[6:1]][offset + 0]  <= dram_read_out[3:0] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 1]  <= dram_read_out[7:4] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 2]  <= dram_read_out[11:8] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 3]  <= dram_read_out[15:12] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 4]  <= dram_read_out[19:16] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 5]  <= dram_read_out[23:20] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 6]  <= dram_read_out[27:24] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 7]  <= dram_read_out[31:28] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 8]  <= dram_read_out[35:32] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 9]  <= dram_read_out[39:36] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 10] <= dram_read_out[43:40] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 11] <= dram_read_out[47:44] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 12] <= dram_read_out[51:48] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 13] <= dram_read_out[55:52] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 14] <= dram_read_out[59:56] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 15] <= dram_read_out[63:60] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 16] <= dram_read_out[67:64] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 17] <= dram_read_out[71:68] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 18] <= dram_read_out[75:72] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 19] <= dram_read_out[79:76] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 20] <= dram_read_out[83:80] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 21] <= dram_read_out[87:84] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 22] <= dram_read_out[91:88] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 23] <= dram_read_out[95:92] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 24] <= dram_read_out[99:96] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 25] <= dram_read_out[103:100] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 26] <= dram_read_out[107:104] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 27] <= dram_read_out[111:108] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 28] <= dram_read_out[115:112] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 29] <= dram_read_out[119:116] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 30] <= dram_read_out[123:120] ? 2'd1 : 2'd0;
				temp_map[addr_location_cnt[6:1]][offset + 31] <= dram_read_out[127:124] ? 2'd1 : 2'd0;
			end
		end

		else if(current_state == INIT_BFS)
		begin
			temp_map[start_y[op_net_num]][start_x[op_net_num]] <= 2'd2;
			temp_map[target_y[op_net_num]][target_x[op_net_num]] <= 2'd0;
		end

		else if(current_state_BFS)
		begin
			for(i=1;i<63;i=i+1) 
			begin
				for(j=1;j<63;j=j+1)
				begin
					if(temp_map[i][j] == 0 && (temp_map[i-1][j][1] | temp_map[i+1][j][1] | temp_map[i][j-1][1] | temp_map[i][j+1][1])) temp_map[i][j] <= fill_value;
				end
			end

			for(j=1;j<63;j=j+1)
			begin
				if(temp_map[0][j] == 0 && (temp_map[1][j][1] | temp_map[0][j-1][1] | temp_map[0][j+1][1])) temp_map[0][j] <= fill_value;
				if(temp_map[63][j] == 0 && (temp_map[62][j][1] | temp_map[63][j-1][1] | temp_map[63][j+1][1])) temp_map[63][j] <= fill_value;
			end

			for(i=1;i<63;i=i+1)
			begin
				if(temp_map[i][0] == 0 && (temp_map[i][1][1] | temp_map[i-1][0][1] | temp_map[i+1][0][1])) temp_map[i][0] <= fill_value;
				if(temp_map[i][63] == 0 && (temp_map[i][62][1] | temp_map[i+1][63][1] | temp_map[i-1][63][1])) temp_map[i][63] <= fill_value;
			end

			if(temp_map[0][0] == 0 && (temp_map[0][1][1] | temp_map[1][0][1])) temp_map[0][0] <= fill_value;
			if(temp_map[63][0] == 0 && (temp_map[63][1][1] | temp_map[62][0][1])) temp_map[63][0] <= fill_value;
			if(temp_map[0][63] == 0 && (temp_map[1][63][1] | temp_map[0][62][1])) temp_map[0][63] <= fill_value;
			if(temp_map[63][63] == 0 && (temp_map[62][63][1] | temp_map[63][62][1])) temp_map[63][63] <= fill_value;
		end

		else if(current_state_trace_back && back_1_cnt)
		begin
			temp_map[trace_back_y][trace_back_x] <= 1;
		end

		// else if(trace_back_d2 && !back_1_cnt)
		// begin
		// 	temp_map[trace_back_y][trace_back_x] <= 1;
		// end

		else if(current_state_clear_map)
		begin
			for(i=0;i<64;i=i+1)
				for(j=0;j<64;j=j+1)
				begin
					if(temp_map[i][j][1] == 1) temp_map[i][j] <= 0;
				end
		end
	end	
end

// fill_value
always @ (*)
begin
	fill_value = 0;
	case(cnt_4)
	0: fill_value = 2;
	1: fill_value = 2;
	2: fill_value = 3;
	3: fill_value = 3;
	endcase
end


// cnt_4
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) cnt_4 <= 1;
	else
	begin
		if(next_state_IDLE) cnt_4 <= 1;
		else if(current_state_clear_map) cnt_4 <= 1;
		else if(current_state_BFS) cnt_4 <= cnt_4 + 1;
		else if(current_state_trace_back && trace_back_d1 != 1) cnt_4 <= cnt_4 - 2;
		else if(back_1_cnt == 1) cnt_4 <= cnt_4 - 1; 
	end
end

// back_1_cnt
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) back_1_cnt <= 0;
	else
	begin
		if(next_state_IDLE) back_1_cnt <= 0;
		else if(current_state_clear_map) back_1_cnt <= 0;
		else if(current_state_trace_back)
		begin
			back_1_cnt <= back_1_cnt + 1;
		end
	end
end

// trace_back_d1 && trace_back_d2
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) 
	begin
		trace_back_d1 <= 0;
	end
	else
	begin
		trace_back_d1 <= current_state_trace_back;
	end
end

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) 
	begin
		trace_back_d2 <= 0;
	end
	else
	begin
		trace_back_d2 <= trace_back_d1;
	end
end

// trace_back_x & trace_back_y
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		trace_back_x <= 0;
		trace_back_y <= 0;
	end

	else
	begin
		if(next_state_IDLE)
		begin
			trace_back_x <= 0;
			trace_back_y <= 0;
		end

		else if(current_state_BFS)
		begin
			trace_back_x <= target_x[op_net_num];
			trace_back_y <= target_y[op_net_num];
		end

		else if(trace_back_d2 && back_1_cnt)
		begin
			if(temp_map[trace_back_y+1][trace_back_x] == fill_value && ~&trace_back_y)
			begin
				trace_back_y <= trace_back_y + 1;
			end

			else if (temp_map[trace_back_y - 1][trace_back_x] == fill_value &&  |trace_back_y)
			begin
				trace_back_y <= trace_back_y - 1;
			end

			else if (temp_map[trace_back_y][trace_back_x + 1] == fill_value && ~&trace_back_x)
			begin
				trace_back_x <= trace_back_x + 1;
			end

			else
			begin
				trace_back_x <= trace_back_x - 1;
			end
		end	
	end
end

// op_net_num
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) op_net_num <= 0;
	else
	begin
		if(next_state_IDLE) op_net_num <= 0;
		else if(current_state_clear_map) op_net_num <= op_net_num + 1;
	end
end

// net_id_reg
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		for(i=0;i<15;i=i+1)
			net_id_reg[i] <= 0;
	end

	else
	begin
		if(next_state_IDLE)
		begin
			for(i=0;i<15;i=i+1)
				net_id_reg[i] <= 0;			
		end

		else if(next_state_INPUT) net_id_reg[net_num] <= net_id;
	end
end

// frame_id_reg
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		frame_id_reg <= 0;
	end

	else
	begin
		if(next_state_IDLE)
		begin
			frame_id_reg <= 0;
		end

		else if(next_state_INPUT) frame_id_reg <= frame_id;
	end
end

// target_x && target_y && start_x && start_y
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) 
	begin
		for(i=0;i<15;i=i+1)
		begin
			target_x[i] <= 0;
			target_y[i] <= 0;
			start_x[i] <= 0;
			start_y[i] <= 0;
		end
	end

	else
	begin
		if(next_state_IDLE)
		begin
			for(i=0;i<16;i=i+1)
			begin
				target_x[i] <= 0;
				target_y[i] <= 0;
				start_x[i] <= 0;
				start_y[i] <= 0;
			end
		end

		else if(next_state_INPUT)
		begin
			if(input_cnt == 1)
			begin
				target_x[net_num] <= loc_x;
				target_y[net_num] <= loc_y;
			end 

			else if(input_cnt == 0)
			begin
				start_x[net_num] <= loc_x;
				start_y[net_num] <= loc_y;
			end
		end
	end
end

// net_num
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) net_num <= 0;
	else
	begin
		if(next_state_IDLE) net_num <= 0;
		else if(next_state_INPUT)
		begin
			if(input_cnt) net_num <= net_num + 1;
		end
	end
end

// input_cnt
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) input_cnt <= 0;
	else
	begin
		if(next_state_IDLE) input_cnt <= 0;
		else if(next_state_INPUT) input_cnt <= input_cnt + 1;
	end
end

// busy
always @ (*)
begin

	busy = 1;
	if(current_state == IDLE || current_state == INPUT || current_state == OUTPUT) busy = 0;
end

// cost
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cost<=0;
	end
	else begin
		if(next_state_IDLE) cost <= 0;
		else if(!(current_state_trace_back)) cost <= cost;
		else if(start_weight && back_1_cnt) cost <= cost + weight_reg;
	end
end

// current_state
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) current_state <= IDLE;
	else current_state <= next_state;
end

endmodule



module AXI4_READ(
		clk,
		rst_n,
		current_state,
		map_select,
		frame_id_reg,
		dram_read_out,

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

	// ===============================================================
	//  					Parameter Declaration 
	// ===============================================================
	parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;
	parameter AR_VALID = 1'd0;
	parameter DRAM_READ = 4'd2;
	parameter R_VALID = 1'd1;

	// ------------------------
	// <<<<< AXI READ >>>>>
	// ------------------------
	// (1)	axi read address channel 
	output wire [ID_WIDTH-1:0]      arid_m_inf;
	output wire [1:0]            arburst_m_inf;
	output wire [2:0]             arsize_m_inf;
	output wire [7:0]              arlen_m_inf;
	output reg                  arvalid_m_inf;
	input  wire                  arready_m_inf;
	output reg [ADDR_WIDTH-1:0]  araddr_m_inf;
	// ------------------------
	// (2)	axi read data channel 
	input  wire [ID_WIDTH-1:0]       rid_m_inf;
	input  wire                   rvalid_m_inf;
	output reg                   rready_m_inf;
	input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
	input  wire                    rlast_m_inf;
	input  wire [1:0]              rresp_m_inf;
	// ------------------------
	// from top module
	input wire [3:0] current_state;
	input wire map_select;
	input wire [4:0] frame_id_reg;
	output reg [DATA_WIDTH-1:0] dram_read_out;
	input clk, rst_n;

	// ===============================================================
	//  					Reg declaration 
	// ===============================================================
	reg axi_read_current_state, axi_read_next_state;

	// ===============================================================
	//  					    Design
	// ===============================================================
	assign arid_m_inf = 4'b0;
	assign arsize_m_inf = 3'b0;
	assign arburst_m_inf = 2'b01;
	assign arlen_m_inf = 8'd127;

	// FSM
	always @ (*)
	begin
		axi_read_next_state = axi_read_current_state;
		case(axi_read_current_state)
			AR_VALID:
			begin
				if(current_state == DRAM_READ || map_select == 1)
				begin
					if(arready_m_inf == 1) axi_read_next_state = R_VALID;
				end
			end

			R_VALID:
			begin
				if(rlast_m_inf == 1) axi_read_next_state = AR_VALID;
			end
		endcase
	end

	// araddr_m_inf
	always @ (*)
	begin
		araddr_m_inf = 0;
		if(axi_read_current_state == AR_VALID)
		begin
			if(current_state == DRAM_READ || map_select == 1)
			begin
				if(map_select == 0) araddr_m_inf = 20'h10000 + frame_id_reg * 12'h800;
				else if(map_select == 1) araddr_m_inf = 20'h20000 + frame_id_reg * 12'h800;
			end
		end

	end

	// arvalid_m_inf
	always @ (*)
	begin
		arvalid_m_inf = 0;
		if(axi_read_current_state == AR_VALID)
		begin
		if(current_state == DRAM_READ|| map_select == 1) arvalid_m_inf = 1;
		end
	end

	// rready_m_inf
	always @ (*)
	begin
		rready_m_inf = 0;
		if(axi_read_current_state == R_VALID) rready_m_inf = 1;
	end

	// dram_read_out
	always @ (*)
	begin
		dram_read_out = 0;
		if(axi_read_current_state == R_VALID)
		begin
			if(rvalid_m_inf == 1) dram_read_out = rdata_m_inf;
		end
	end


	// AXI_READ FSM control
	always @ (posedge clk or negedge rst_n)
	begin
		if(!rst_n) axi_read_current_state <= AR_VALID;
		else axi_read_current_state <= axi_read_next_state;
	end
endmodule




module AXI4_WRITE(
		clk,
		rst_n,
		current_state,
		dram_write_in,
		frame_id_reg,

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
	    bready_m_inf 
	);

	parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;
	// ------------------------
	// <<<<< AXI WRITE >>>>>
	// ------------------------
	// (1) 	axi write address channel 
	output wire [ID_WIDTH-1:0]      awid_m_inf;
	output wire [1:0]            awburst_m_inf;
	output wire [2:0]             awsize_m_inf;
	output wire [7:0]              awlen_m_inf;
	output reg                  awvalid_m_inf;
	input  wire                  awready_m_inf;
	output reg [ADDR_WIDTH-1:0]  awaddr_m_inf;
	// -------------------------
	// (2)	axi write data channel 
	output reg                   wvalid_m_inf;
	input  wire                   wready_m_inf;
	output wire [DATA_WIDTH-1:0]   wdata_m_inf;
	output reg                    wlast_m_inf;
	// -------------------------
	// (3)	axi write response channel 
	input  wire  [ID_WIDTH-1:0]      bid_m_inf;
	input  wire                   bvalid_m_inf;
	output reg                   bready_m_inf;
	input  wire  [1:0]             bresp_m_inf;
	// -----------------------------

	input wire [3:0] current_state;
	input wire [DATA_WIDTH-1:0] dram_write_in;
	input wire [4:0] frame_id_reg;
	input clk, rst_n;


	parameter AW_VALID = 2'd0;
	parameter W_VALID = 2'd1;
	parameter TEMP = 2'd2;
	parameter DRAM_WRITE = 4'd3;

	reg axi_write_current_state, axi_write_next_state;
	reg [6:0] len_cnt;

	assign awid_m_inf = 4'd0;
	assign awburst_m_inf = 2'b01;
	assign awsize_m_inf = 3'b100;
	assign wdata_m_inf = dram_write_in;

	assign awlen_m_inf = 8'd127;


	// axi_write_next_state
	always @ (*)
	begin
		axi_write_next_state = axi_write_current_state;
		case(axi_write_current_state)
			AW_VALID:
			begin
				if(current_state == DRAM_WRITE)
				begin
					if(awready_m_inf == 1) axi_write_next_state = W_VALID;
				end
			end

			W_VALID:
			begin
				if(bvalid_m_inf == 1) axi_write_next_state = AW_VALID;
			end
		endcase
	end

	// wlast_m_inf
	always @ (*)
	begin
		wlast_m_inf = 0;
		if(current_state == DRAM_WRITE && axi_write_current_state == W_VALID && len_cnt == awlen_m_inf) wlast_m_inf = 1;
	end

	// bready_m_inf
	always @ (*)
	begin
		bready_m_inf = 0;
		if(current_state == DRAM_WRITE && axi_write_current_state == W_VALID) bready_m_inf = 1;
	end

	// wvalid_m_inf
	always @ (*)
	begin
		wvalid_m_inf = 0;
		if(current_state == DRAM_WRITE && axi_write_current_state == W_VALID) wvalid_m_inf = 1;
	end
	// awaddr_m_inf
	always @ (*)
	begin
		awaddr_m_inf = 0;
		if(current_state == DRAM_WRITE && axi_write_current_state == AW_VALID) awaddr_m_inf = 20'h10000 + frame_id_reg * 12'h800;
	end

	// awvalid_m_inf
	always @ (*)
	begin
		awvalid_m_inf = 0;
		if(current_state == DRAM_WRITE && axi_write_current_state == AW_VALID) awvalid_m_inf = 1;
	end

	// axi_write_current_state
	always @ (posedge clk or negedge rst_n)
	begin
		if(!rst_n) axi_write_current_state <= AW_VALID;
		else axi_write_current_state <= axi_write_next_state;
	end

	// len_cnt
	always @ (posedge clk or negedge rst_n)
	begin
		if(!rst_n) len_cnt <= 0;
		else
		begin
			if(bvalid_m_inf == 1) len_cnt <= 0;
			else if(wready_m_inf == 1) len_cnt <= len_cnt + 1;
		end
	end

endmodule
