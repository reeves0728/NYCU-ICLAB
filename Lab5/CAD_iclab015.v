module CAD(
    //Input Port
    clk,
    rst_n,
    in_valid,
    in_valid2,
    matrix_size,
    matrix,
    matrix_idx,
    mode,
    //Output Port
    out_valid,
    out_value
    );

input         clk, rst_n, in_valid, in_valid2;
input         mode;
input  [7:0]  matrix;
input  [3:0]  matrix_idx;
input  [1:0]  matrix_size;
output reg        out_valid;
output reg        out_value;

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
reg [14:0] Addr_img;
reg [8:0] Addr_kernel;
reg [10:0] Addr_out_read;
reg [10:0] Addr_out_write;
reg [7:0] DI_img, DI_kernel;
reg [7:0] DO_img, DO_kernel;
reg WEB_img, WEB_kernel, WEB_out_read, WEB_out_write;
reg [19:0]  DI_out_read,DO_out_read,DI_out_write, DO_out_write;

reg [1:0] matrix_size_reg;
reg [3:0] current_state, next_state;
reg [4:0] row_cnt;
reg [5:0] col_cnt; // plus 1 bit
reg [3:0] img_cnt;
reg [8:0] kernel_cnt;
reg [4:0] init_cnt;
reg [4:0] size_reg;
reg [2:0] conv_5_cnt;
reg [5:0] conv_offset; // plus 1 bit

reg mode_reg;
reg [4:0] kernel_index_reg;
reg [4:0] image_index_reg;
reg signed [7:0] img_25 [0:4][0:4];
reg signed [7:0] img_next_25[0:3][0:4];
reg signed [7:0] new_5 [0:4];
reg signed [7:0] kernel_25 [0:24];
reg [2:0] init_row_reg;
reg [2:0] init_col_reg;

reg signed [7:0] img_mul_reg [0:4];
reg signed [7:0] kernel_mul_reg [0:4];
reg signed [20:0] mul_result_reg;
reg signed [20:0] p5_mul_result_reg;

reg signed [20:0] temp_pooling [0:13];
reg save_or_pool ;
reg only_pool;
reg [3:0] index_temp_pool;

reg [3:0] write_out_cnt;
reg [7:0] addr_out_cnt;

reg [7:0] conv_out_cnt;
reg [4:0] conv_out_19_cnt;

reg [10:0] deconv_sram_write_cnt;

// reg [4:0] out_20_cnt;

reg [4:0] deconv_out_19_cnt;
reg [10:0] deconv_out_cnt;

reg signed [19:0] temp_out;
reg signed [19:0] deconv_temp_out;

reg [3:0] wait_invalid2_cnt;

parameter IDLE = 0;
parameter INPUT_1 = 1;
parameter INPUT_2 = 2;
parameter WAIT_INVALID_2 = 3;
parameter INVALID_2_1 = 4;
parameter INVALID_2_2 = 5;
parameter INIT_CONV = 6;
parameter CONV = 7;
parameter DECONV = 8;
parameter INIT_DECONV = 9;

integer i;
integer j;
// parameter IMG_8X8 = 4;
// parameter IMG_16X16 = 5;
// parameter IMG_32X32 = 6;
// parameter POOLING = ; 
// parameter OUTPUT_CONV = ;
// parameter OUTPUT_DECONV = ;

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
// SRAM_IMG sram0(.A(Addr_img),.DO(DO_img),.DI(DI_img),.CK(clk),.WEB(WEB_img),.OE(1'b1),.CS(1'b1));
// SRAM_KERNEL sram1(.A(Addr_kernel),.DO(DO_kernel),.DI(DI_kernel),.CK(clk),.WEB(WEB_kernel),.OE(1'b1),.CS(1'b1));
// SRAM_OUTPUT sram2(.A(Addr_out_write),.DOA(DO_out_write),.DIA(DI_out_write),.WEAN(WEB_out_write),.CKA(clk), .CSA(1'b1),.OEA(1'b1),
//                   .B(Addr_out_read),.DOB(DO_out_read),.DIB(DI_out_read),.WEBN(WEB_out_read),.CKB(clk),.CSB(1'b1),.OEB(1'b1));

SRAM_SP_IMG_16385 Img0 (.A0(Addr_img[0]), .A1(Addr_img[1]), .A2(Addr_img[2]), .A3(Addr_img[3]), .A4(Addr_img[4]), .A5(Addr_img[5]), .A6(Addr_img[6]), .A7(Addr_img[7]), .A8(Addr_img[8]), .A9(Addr_img[9]), .A10(Addr_img[10]), .A11(Addr_img[11]), .A12(Addr_img[12]), .A13(Addr_img[13]), .A14(Addr_img[14]),
            .DO0(DO_img[0]), .DO1(DO_img[1]), .DO2(DO_img[2]), .DO3(DO_img[3]), .DO4(DO_img[4]), .DO5(DO_img[5]), .DO6(DO_img[6]), .DO7(DO_img[7]), 
            .DI0(DI_img[0]), .DI1(DI_img[1]), .DI2(DI_img[2]), .DI3(DI_img[3]), .DI4(DI_img[4]), .DI5(DI_img[5]), .DI6(DI_img[6]), .DI7(DI_img[7]), 
            .CK(clk), .WEB(WEB_img), .OE(1'b1), .CS(1'b1));

SRAM_SP_KERNEL Kernel0 (.A0(Addr_kernel[0]), .A1(Addr_kernel[1]), .A2(Addr_kernel[2]), .A3(Addr_kernel[3]), .A4(Addr_kernel[4]), .A5(Addr_kernel[5]), .A6(Addr_kernel[6]), .A7(Addr_kernel[7]), .A8(Addr_kernel[8]), 
                    .DO0(DO_kernel[0]), .DO1(DO_kernel[1]), .DO2(DO_kernel[2]), .DO3(DO_kernel[3]), .DO4(DO_kernel[4]), .DO5(DO_kernel[5]), .DO6(DO_kernel[6]), .DO7(DO_kernel[7]), 
                    .DI0(DI_kernel[0]), .DI1(DI_kernel[1]), .DI2(DI_kernel[2]), .DI3(DI_kernel[3]), .DI4(DI_kernel[4]), .DI5(DI_kernel[5]), .DI6(DI_kernel[6]), .DI7(DI_kernel[7]), 
                    .CK(clk), .WEB(WEB_kernel), .OE(1'b1), .CS(1'b1));

SRAM_DP_OUT Output0 (.A0(Addr_out_write[0]),.A1(Addr_out_write[1]),.A2(Addr_out_write[2]),.A3(Addr_out_write[3]),.A4(Addr_out_write[4]),.A5(Addr_out_write[5]),.A6(Addr_out_write[6]),.A7(Addr_out_write[7]),.A8(Addr_out_write[8]),.A9(Addr_out_write[9]),.A10(Addr_out_write[10]),
                .B0(Addr_out_read[0]),.B1(Addr_out_read[1]),.B2(Addr_out_read[2]),.B3(Addr_out_read[3]),.B4(Addr_out_read[4]),.B5(Addr_out_read[5]),.B6(Addr_out_read[6]),.B7(Addr_out_read[7]),.B8(Addr_out_read[8]),.B9(Addr_out_read[9]),.B10(Addr_out_read[10]),
                .DOA0(DO_out_write[0]),.DOA1(DO_out_write[1]),.DOA2(DO_out_write[2]),.DOA3(DO_out_write[3]),.DOA4(DO_out_write[4]),.DOA5(DO_out_write[5]),.DOA6(DO_out_write[6]),.DOA7(DO_out_write[7]),.DOA8(DO_out_write[8]),.DOA9(DO_out_write[9]),.DOA10(DO_out_write[10]),.DOA11(DO_out_write[11]),.DOA12(DO_out_write[12]),.DOA13(DO_out_write[13]),.DOA14(DO_out_write[14]),.DOA15(DO_out_write[15]),.DOA16(DO_out_write[16]),.DOA17(DO_out_write[17]),.DOA18(DO_out_write[18]),.DOA19(DO_out_write[19]),
                .DOB0(DO_out_read[0]),.DOB1(DO_out_read[1]),.DOB2(DO_out_read[2]),.DOB3(DO_out_read[3]),.DOB4(DO_out_read[4]),.DOB5(DO_out_read[5]),.DOB6(DO_out_read[6]),.DOB7(DO_out_read[7]),.DOB8(DO_out_read[8]),.DOB9(DO_out_read[9]),.DOB10(DO_out_read[10]),.DOB11(DO_out_read[11]),.DOB12(DO_out_read[12]),.DOB13(DO_out_read[13]),.DOB14(DO_out_read[14]),.DOB15(DO_out_read[15]),.DOB16(DO_out_read[16]),.DOB17(DO_out_read[17]),.DOB18(DO_out_read[18]),.DOB19(DO_out_read[19]),
                .DIA0(DI_out_write[0]),.DIA1(DI_out_write[1]),.DIA2(DI_out_write[2]),.DIA3(DI_out_write[3]),.DIA4(DI_out_write[4]),.DIA5(DI_out_write[5]),.DIA6(DI_out_write[6]),.DIA7(DI_out_write[7]),.DIA8(DI_out_write[8]),.DIA9(DI_out_write[9]),.DIA10(DI_out_write[10]),.DIA11(DI_out_write[11]),.DIA12(DI_out_write[12]),.DIA13(DI_out_write[13]),.DIA14(DI_out_write[14]),.DIA15(DI_out_write[15]),.DIA16(DI_out_write[16]),.DIA17(DI_out_write[17]),.DIA18(DI_out_write[18]),.DIA19(DI_out_write[19]),
                .DIB0(DI_out_read[0]),.DIB1(DI_out_read[1]),.DIB2(DI_out_read[2]),.DIB3(DI_out_read[3]),.DIB4(DI_out_read[4]),.DIB5(DI_out_read[5]),.DIB6(DI_out_read[6]),.DIB7(DI_out_read[7]),.DIB8(DI_out_read[8]),.DIB9(DI_out_read[9]),.DIB10(DI_out_read[10]),.DIB11(DI_out_read[11]),.DIB12(DI_out_read[12]),.DIB13(DI_out_read[13]),.DIB14(DI_out_read[14]),.DIB15(DI_out_read[15]),.DIB16(DI_out_read[16]),.DIB17(DI_out_read[17]),.DIB18(DI_out_read[18]),.DIB19(DI_out_read[19]),
                .WEAN(WEB_out_write),.WEBN(WEB_out_read),.CKA(clk),.CKB(clk),.CSA(1'b1),.OEA(1'b1),.CSB(1'b1),.OEB(1'b1));
//FSM
always @ (*)
begin
  next_state = current_state;
  case(current_state)
    IDLE:
    begin
      if(in_valid) next_state = INPUT_1;
      else next_state = IDLE;
    end

    INPUT_1:
    begin
      if(img_cnt == 15 && row_cnt == size_reg && col_cnt == size_reg) next_state = INPUT_2;
      else next_state = INPUT_1;
    end

    INPUT_2:
    begin
      if(kernel_cnt == 399) next_state = WAIT_INVALID_2;
      else next_state = INPUT_2;
    end

    WAIT_INVALID_2:
    begin
      if(in_valid2) next_state = INVALID_2_1;
      else next_state = WAIT_INVALID_2;
    end

    INVALID_2_1: next_state = INVALID_2_2;

    INVALID_2_2:
    begin
      if(mode_reg == 1'b0) next_state = INIT_CONV;
      else next_state = INIT_DECONV;
    end 

    INIT_CONV:
    begin
      if(init_cnt == 26) next_state = CONV;
      else next_state = INIT_CONV;
    end

    CONV:
    begin
     if (conv_out_cnt > ((size_reg -3)/2) *((size_reg -3)/2) && conv_out_19_cnt == 3)
     begin 
      if(wait_invalid2_cnt == 0) next_state = IDLE;
      else next_state = WAIT_INVALID_2;
     end
    end

    INIT_DECONV:
    begin
      if(init_cnt == 26) next_state = DECONV;
      else next_state = INIT_DECONV;
    end

    DECONV:
    begin
      if(deconv_out_cnt == (size_reg+5) * (size_reg+5) + 1 && deconv_out_19_cnt == 3) 
      begin
        if(wait_invalid2_cnt == 0) next_state = IDLE;
        else next_state = WAIT_INVALID_2;
      end
      else next_state = DECONV;
    end
  endcase
end

//wait_invalid2_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) wait_invalid2_cnt <= 0;
  else
  begin
    if(current_state == IDLE) wait_invalid2_cnt <= 0;

    else if(current_state == INVALID_2_1) wait_invalid2_cnt <= wait_invalid2_cnt + 1;
  end
end

// temp_pooling
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) 
  begin
    for(i=0;i<14;i=i+1)
    begin
      temp_pooling[i] <= 0;
    end
  end

  else
  begin
      if(next_state == WAIT_INVALID_2 || next_state == IDLE)
      begin
        for(i=0;i<14;i=i+1)
        begin
          temp_pooling[i] <= 0;
        end
      end

      else if(current_state == CONV && !(conv_offset == 0 && row_cnt == 2 && col_cnt == 5))
      begin
        if(row_cnt == 2)
        begin
          if(only_pool == 1) temp_pooling[index_temp_pool] <= temp_pooling[index_temp_pool] > p5_mul_result_reg ? temp_pooling[index_temp_pool] : p5_mul_result_reg;
          else if(save_or_pool == 0) temp_pooling[index_temp_pool] <= p5_mul_result_reg;
          else temp_pooling[index_temp_pool] <= temp_pooling[index_temp_pool] > p5_mul_result_reg ? temp_pooling[index_temp_pool] : p5_mul_result_reg;
        end
      end
  end
end

// index_temp_pool
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) index_temp_pool <= 0;

  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE)
    begin
      index_temp_pool <= 0;
    end
    
    else if(current_state == CONV && !(conv_offset == 0 && row_cnt == 2 && col_cnt == 5))
    begin
      if(index_temp_pool == (((size_reg -3) /2) - 1) && save_or_pool == 1 && row_cnt == 2 && col_cnt == 5)
      begin
        index_temp_pool <= 0;
      end

      else if((row_cnt == 2 && save_or_pool == 1 && conv_offset <= size_reg -1) && !(col_cnt == 5 && row_cnt == 2 && conv_offset == 0))
      begin
          index_temp_pool <= index_temp_pool + 1;
      end
    end
  end
end

// only pool
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) only_pool <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE)
    begin
      only_pool <= 0;
    end
    
    else if(current_state == CONV && !(conv_offset == 0 && row_cnt == 2 && col_cnt == 5))
    begin
      if(index_temp_pool == (((size_reg -3) /2) - 1) && save_or_pool == 1 && row_cnt == 2) // original row_cnt == 2
      begin
        only_pool <= only_pool + 1;
      end
    end
  end
end


// save_or_pool
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    save_or_pool <= 0;
  end

  else 
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE)
    begin
      save_or_pool <= 0;
    end
    
    else if(current_state == CONV && !(conv_offset == 0 && row_cnt == 2 && col_cnt == 5))
    begin
      if(row_cnt == 2)
      begin
        save_or_pool <= save_or_pool + 1;
      end
    end
  end
end

// p5_mul_result_reg
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) p5_mul_result_reg <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE)
    begin
      p5_mul_result_reg <= 0;
    end

    else if(current_state == CONV || current_state == DECONV)
    begin
      if(row_cnt == 2) p5_mul_result_reg <= mul_result_reg;
      else p5_mul_result_reg <= p5_mul_result_reg + mul_result_reg;
    end
  end
end

// mul_result_reg
always @ (*)
begin
  mul_result_reg = img_mul_reg[0]*kernel_mul_reg[0] + img_mul_reg[1]*kernel_mul_reg[1] + img_mul_reg[2]*kernel_mul_reg[2] + img_mul_reg[3]*kernel_mul_reg[3]+img_mul_reg[4]*kernel_mul_reg[4];
end

//img_mul_reg && kernel_mul_reg
always @ (*)
begin

  if(current_state == CONV || current_state == DECONV)
  begin
    case(row_cnt)
      2:
      begin
          img_mul_reg[0] = img_25[0][0];
          img_mul_reg[1] = img_25[0][1];
          img_mul_reg[2] = img_25[0][2];
          img_mul_reg[3] = img_25[0][3];
          img_mul_reg[4] = img_25[0][4];

          kernel_mul_reg[0] = kernel_25[0];
          kernel_mul_reg[1] = kernel_25[1];
          kernel_mul_reg[2] = kernel_25[2];
          kernel_mul_reg[3] = kernel_25[3];
          kernel_mul_reg[4] = kernel_25[4];
      end

      3:
      begin
          img_mul_reg[0] = img_25[1][0];
          img_mul_reg[1] = img_25[1][1];
          img_mul_reg[2] = img_25[1][2];
          img_mul_reg[3] = img_25[1][3];
          img_mul_reg[4] = img_25[1][4];

          kernel_mul_reg[0] = kernel_25[5];
          kernel_mul_reg[1] = kernel_25[6];
          kernel_mul_reg[2] = kernel_25[7];
          kernel_mul_reg[3] = kernel_25[8];
          kernel_mul_reg[4] = kernel_25[9];
      end

      4:
      begin
          img_mul_reg[0] = img_25[2][0];
          img_mul_reg[1] = img_25[2][1];
          img_mul_reg[2] = img_25[2][2];
          img_mul_reg[3] = img_25[2][3];
          img_mul_reg[4] = img_25[2][4];

          kernel_mul_reg[0] = kernel_25[10];
          kernel_mul_reg[1] = kernel_25[11];
          kernel_mul_reg[2] = kernel_25[12];
          kernel_mul_reg[3] = kernel_25[13];
          kernel_mul_reg[4] = kernel_25[14];
      end

      0:
      begin
          img_mul_reg[0] = img_25[3][0];
          img_mul_reg[1] = img_25[3][1];
          img_mul_reg[2] = img_25[3][2];
          img_mul_reg[3] = img_25[3][3];
          img_mul_reg[4] = img_25[3][4];

          kernel_mul_reg[0] = kernel_25[15];
          kernel_mul_reg[1] = kernel_25[16];
          kernel_mul_reg[2] = kernel_25[17];
          kernel_mul_reg[3] = kernel_25[18];
          kernel_mul_reg[4] = kernel_25[19];
      end  

      1:
      begin
          img_mul_reg[0] = img_25[4][0];
          img_mul_reg[1] = img_25[4][1];
          img_mul_reg[2] = img_25[4][2];
          img_mul_reg[3] = img_25[4][3];
          img_mul_reg[4] = img_25[4][4];

          kernel_mul_reg[0] = kernel_25[20];
          kernel_mul_reg[1] = kernel_25[21];
          kernel_mul_reg[2] = kernel_25[22];
          kernel_mul_reg[3] = kernel_25[23];
          kernel_mul_reg[4] = kernel_25[24];
      end    

      default:
      begin
        for(i=0;i<5;i=i+1) begin
          img_mul_reg[i] = 0;
          kernel_mul_reg[i] = 0;
        end
      end
    endcase
  end

  else begin
    for(i=0;i<5;i=i+1) begin
      img_mul_reg[i] = 0;
      kernel_mul_reg[i] = 0;
    end
  end
end

// img_next_25
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    for(i=0; i<4; i=i+1)
      for(j=0; j<5; j=j+1)
        img_next_25[i][j] <= 0; 
  end

  else
  begin
    if(next_state == WAIT_INVALID_2 && next_state == IDLE)
    begin
      for(i=0; i<4; i=i+1)
        for(j=0; j<5; j=j+1)
          img_next_25[i][j] <= 0; 
    end

    else if(current_state == CONV && col_cnt == 5 && row_cnt == 2)
    begin
        for(i=0;i<4;i=i+1)
          for(j=0;j<5;j=j+1)
            img_next_25[i][j] <= img_25[i+1][j];
    end

    else if(current_state == DECONV && col_cnt == 5 && row_cnt == 2)
    begin
        for(i=0;i<4;i=i+1)
          for(j=0;j<5;j=j+1)
            img_next_25[i][j] <= img_25[i+1][j];
    end

  end
end

// init_row_reg && init_col_reg
always @ (posedge  clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    init_row_reg <= 0;
    init_col_reg <= 0;
  end

  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE)
    begin
      init_row_reg <= 0;
      init_col_reg <= 0;
    end

    else if(next_state == INIT_CONV)
    begin
      init_row_reg <= row_cnt;
      init_col_reg <= col_cnt;
    end
  end
end

//image_25
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) 
  begin
    for(i=0; i<5; i=i+1)
      for(j=0; j<5; j=j+1)
        img_25[i][j] <= 0;
  end

  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE)
    begin
      for(i=0; i<5; i=i+1)
        for(j=0; j<5; j=j+1)
          img_25[i][j] <= 0;
    end

    else if(next_state == INIT_CONV)
    begin
      img_25[init_row_reg][init_col_reg] <= DO_img;
    end

    else if(current_state == CONV && conv_offset >0 && row_cnt == 1 && col_cnt == 5)
    begin
      for(i=0; i<4;i=i+1)
        for(j=0;j<5;j=j+1)
          img_25[i][j] <= img_next_25[i][j];

      img_25[4][0] <= new_5[0];
      img_25[4][1] <= new_5[1];
      img_25[4][2] <= new_5[2];
      img_25[4][3] <= new_5[3];
      img_25[4][4] <= new_5[4];
    end

    else if(current_state == CONV&&!((row_cnt ==1 || row_cnt ==0)&& conv_offset == 0 && col_cnt == 5))
    begin
      case(row_cnt)
        2:
        begin
          for(i=1;i<5;i=i+1)
              img_25[0][i-1] <= img_25[0][i];

          img_25[0][4] <= new_5[0];
        end
        3:
        begin
          for(i=1;i<5;i=i+1)
              img_25[1][i-1] <= img_25[1][i];

          img_25[1][4] <= new_5[1];
        end

        4:
        begin
          for(i=1;i<5;i=i+1)
              img_25[2][i-1] <= img_25[2][i];

          img_25[2][4] <= new_5[2]; 
        end

        0:
        begin
          for(i=1;i<5;i=i+1)
              img_25[3][i-1] <= img_25[3][i];

          img_25[3][4] <= new_5[3];
        end

        1:
        begin
          for(i=1;i<5;i=i+1)
              img_25[4][i-1] <= img_25[4][i];

          img_25[4][4] <= new_5[4];
        end
      endcase
    end

    else if(next_state == INIT_DECONV)
    begin
      for(i=0;i<4;i=i+1)
        for(j=0;j<5;j=j+1)
          img_25[i][j] <= 0;

      img_25[4][0] <= 0;
      img_25[4][1] <= 0;
      img_25[4][2] <= 0;
      img_25[4][3] <= 0;
      img_25[4][4] <= DO_img;
    end

    else if(current_state == DECONV && conv_offset >0 && row_cnt == 1 && col_cnt == 5)
    begin
      for(i=0; i<4;i=i+1)
        for(j=0;j<5;j=j+1)
          img_25[i][j] <= img_next_25[i][j];

      img_25[4][0] <= new_5[0];
      img_25[4][1] <= new_5[1];
      img_25[4][2] <= new_5[2];
      img_25[4][3] <= new_5[3];
      img_25[4][4] <= new_5[4];
    end

   else if(current_state == DECONV&&!((row_cnt ==1 || row_cnt ==0)&& conv_offset == 0 && col_cnt == 5))
    begin
      case(row_cnt)
        2:
        begin
          for(i=1;i<5;i=i+1)
              img_25[0][i-1] <= img_25[0][i];

          img_25[0][4] <= new_5[0];
        end
        3:
        begin
          for(i=1;i<5;i=i+1)
              img_25[1][i-1] <= img_25[1][i];

          img_25[1][4] <= new_5[1];
        end

        4:
        begin
          for(i=1;i<5;i=i+1)
              img_25[2][i-1] <= img_25[2][i];

          img_25[2][4] <= new_5[2]; 
        end

        0:
        begin
          for(i=1;i<5;i=i+1)
              img_25[3][i-1] <= img_25[3][i];

          img_25[3][4] <= new_5[3];
        end

        1:
        begin
          for(i=1;i<5;i=i+1)
              img_25[4][i-1] <= img_25[4][i];

          img_25[4][4] <= new_5[4];
        end
      endcase
    end
  end

end

//kernel_25
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) begin
    for(i=0;i<25;i=i+1)
      kernel_25[i] <= 0;
  end

  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE)
    begin
      for(i=0;i<25;i=i+1)
        kernel_25[i] <= 0;
    end

    if(next_state == INIT_CONV && init_cnt > 0 && init_cnt < 26)
    begin
      kernel_25[init_cnt - 1] <= DO_kernel;
    end

    if(next_state == INIT_DECONV && init_cnt > 0 && init_cnt < 26)
    begin
      kernel_25[25-init_cnt] <= DO_kernel;
    end
  end
end

//kernel_index_reg
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) kernel_index_reg <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) kernel_index_reg <= 0;
    else if(next_state == INVALID_2_2) kernel_index_reg <= matrix_idx;
  end
end

//image_index_reg
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) image_index_reg <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) image_index_reg <= 0;
    else if(next_state == INVALID_2_1) image_index_reg <= matrix_idx;
  end
end

//mode_reg
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) mode_reg <= 0;
  else 
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) mode_reg <= 0;
    else if(next_state == INVALID_2_1) mode_reg  <= mode;
  end
end

// addr_out_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) addr_out_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) addr_out_cnt <= 0;
    // else if(current_state == CONV && write_out_cnt <= (size_reg -3) / 2 -1 && conv_offset[0] == 0 && conv_offset != 0&& ((col_cnt == 5 && row_cnt >=3) || col_cnt ==6 || col_cnt ==7|| (col_cnt == 8 && row_cnt <=1)))//&& conv_offset[0] ==0 && conv_offset != 0 &&((col_cnt == 5 && row_cnt >=3) || (col_cnt >5 && col_cnt<9)))
    // begin
    //   addr_out_cnt <= addr_out_cnt + 1;
    // end
    else if(row_cnt == 3 && col_cnt >=7 && col_cnt <= size_reg && col_cnt[0] == 1 && conv_offset >= 1 && conv_offset <= size_reg-4 && conv_offset[0] == 1) addr_out_cnt <= addr_out_cnt + 1;
    else if(row_cnt == 3 && col_cnt==5 && conv_offset>=2 && conv_offset <= size_reg-3 && conv_offset[0] == 0)addr_out_cnt <= addr_out_cnt + 1;

  end
end

// write_out_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) write_out_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) write_out_cnt <= 0;
    else if(current_state == CONV)
    begin
      if(row_cnt == 2 && col_cnt == 5)
      begin
        write_out_cnt <= 0;
      end
      else
      begin
        write_out_cnt <= write_out_cnt + 1;
      end
    end
  end
end

// conv_out_19_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) conv_out_19_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) conv_out_19_cnt <= 0;
    else if(current_state == CONV)
    begin
      if(conv_out_19_cnt == 19) conv_out_19_cnt <= 0; 
      else if(addr_out_cnt >= 1) conv_out_19_cnt<=conv_out_19_cnt+1;
    end
  end
end

// conv_out_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) conv_out_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) conv_out_cnt <= 0;
    else if(conv_out_19_cnt == 1) conv_out_cnt <= conv_out_cnt + 1;
  end
end

// temp_out
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) temp_out <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) temp_out <= 0;
    else if(conv_out_19_cnt == 2) temp_out <= DO_out_read;
    else temp_out <= temp_out >> 1;
  end
end

//sram_out read
always @ (*)
begin
  Addr_out_read = 0;
  DI_out_read = 0;
  WEB_out_read = 1;

  if(Addr_out_write == 0 && WEB_out_write == 0)
  begin
    Addr_out_read = 1;
  end


  else if(current_state == CONV && conv_out_19_cnt == 1 && conv_out_cnt < (size_reg+5) * (size_reg+5)) // change
  begin
    Addr_out_read = conv_out_cnt;
  end

  else if(current_state == DECONV && deconv_out_19_cnt == 1 && deconv_out_cnt < (size_reg+5) * (size_reg+5))
  begin
    Addr_out_read = deconv_out_cnt;
  end
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) deconv_temp_out <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) deconv_temp_out <= 0;
    else if(deconv_out_19_cnt == 2) deconv_temp_out <= DO_out_read;
    else deconv_temp_out <= deconv_temp_out >> 1;
  end
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) deconv_out_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) deconv_out_cnt <= 0;
    else if (current_state == DECONV)
    begin
      if(deconv_out_19_cnt == 1) deconv_out_cnt <= deconv_out_cnt + 1;
    end
  end
end

//deconv_out_19_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) deconv_out_19_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE)
    begin
      deconv_out_19_cnt <= 0;
    end

    else if(current_state == DECONV)
    begin
      if(deconv_sram_write_cnt >= 1)
      begin
        if(deconv_out_19_cnt == 19) deconv_out_19_cnt <= 0;
        else deconv_out_19_cnt <= deconv_out_19_cnt + 1;
      end
    end
  end
end

//sram_out write
always @ (*)
begin
  Addr_out_write = 0;
  DI_out_write = 0;
  WEB_out_write = 1;
  if(current_state == CONV && row_cnt == 3 && col_cnt >=7 && col_cnt <= size_reg && col_cnt[0] == 1 && conv_offset >= 1 && conv_offset <= size_reg-4 && conv_offset[0] == 1)
  begin
      WEB_out_write = 0;
      DI_out_write =  temp_pooling[addr_out_cnt % ((size_reg -3) / 2)];//temp_pooling[addr_out_cnt % ((size_reg -3) / 2)];
      Addr_out_write = addr_out_cnt;
  end

  else if(current_state == CONV && row_cnt == 3 && col_cnt==5 && conv_offset>=2 && conv_offset <= size_reg-3 && conv_offset[0] == 0)
  begin
      WEB_out_write = 0;
      DI_out_write =  temp_pooling[addr_out_cnt % ((size_reg -3) / 2)];//temp_pooling[addr_out_cnt % ((size_reg -3) / 2)];
      Addr_out_write = addr_out_cnt;
  end

  else if(deconv_sram_write_cnt == (size_reg+5) * (size_reg+5))
  begin
    WEB_out_write = 1;
  end

  else if(current_state == DECONV && !(conv_offset == 0 && row_cnt == 2 && col_cnt == 5))
  begin
    if(row_cnt == 2)
    begin
      WEB_out_write = 0;
      DI_out_write = p5_mul_result_reg;
      Addr_out_write = deconv_sram_write_cnt;
    end
  end
end

// deconv_sram_write_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) deconv_sram_write_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) deconv_sram_write_cnt <= 0;
    else if(current_state == DECONV && !(conv_offset == 0 && row_cnt == 2 && col_cnt == 5))
    begin
      if(deconv_sram_write_cnt == (size_reg+5) * (size_reg+5)) deconv_sram_write_cnt <= deconv_sram_write_cnt;
      else if(row_cnt == 2)
      begin
        deconv_sram_write_cnt <= deconv_sram_write_cnt + 1;
      end
    end
  end
end


//sram_img
always @ (*)
begin
  Addr_img = 15'd16384;
  DI_img = 0;
  WEB_img = 1;

  if(current_state == INPUT_2)
  begin
    Addr_img = 15'd16384;
    DI_img = 0;
    WEB_img = 0;
  end

  else if(next_state == INPUT_1 || current_state == INPUT_1)
  begin
    WEB_img = 0;
    DI_img = matrix;
    begin
      case(size_reg)
        5'd7: Addr_img = {img_cnt,row_cnt[2:0],col_cnt[2:0]};
        5'd15: Addr_img = {img_cnt,row_cnt[3:0],col_cnt[3:0]};
        5'd31: Addr_img = {img_cnt,row_cnt[4:0],col_cnt[4:0]};
      endcase
    end
  end

  else if(next_state == INIT_CONV)
  begin
    if(init_cnt == 25) Addr_img = {image_index_reg,3'd0,3'd5};
    else 
    begin
      begin
        case(size_reg)
          5'd7: Addr_img = {image_index_reg,row_cnt[2:0],col_cnt[2:0]};
          5'd15: Addr_img = {image_index_reg,row_cnt[3:0],col_cnt[3:0]};
          5'd31: Addr_img = {image_index_reg,row_cnt[4:0],col_cnt[4:0]};
        endcase
      end
    end
  end

  else if (current_state == CONV && col_cnt == 4)
  begin
    begin
      case(size_reg)
        5'd7: Addr_img = {image_index_reg,(col_cnt[2:0]+conv_offset[2:0]) ,row_cnt[2:0]};
        5'd15: Addr_img = {image_index_reg,(col_cnt[3:0]+conv_offset[3:0]),row_cnt[3:0]};
        5'd31: Addr_img = {image_index_reg,(col_cnt[4:0]+conv_offset[4:0]),row_cnt[4:0]};
      endcase
    end
  end

  else if (current_state == CONV)
  begin
    begin
      case(size_reg)
        5'd7: Addr_img = {image_index_reg,(row_cnt[2:0] + conv_offset[2:0]),col_cnt[2:0]};
        5'd15: Addr_img = {image_index_reg,(row_cnt[3:0] + conv_offset[3:0]),col_cnt[3:0]};
        5'd31: Addr_img = {image_index_reg,(row_cnt[4:0] + conv_offset[4:0]),col_cnt[4:0]};
      endcase
    end
  end  

  else if(next_state == INIT_DECONV)
  begin
      case(size_reg)
        5'd7: Addr_img = {image_index_reg,3'b0 ,3'b0};
        5'd15: Addr_img = {image_index_reg,4'b0,4'b0};
        5'd31: Addr_img = {image_index_reg,5'b0,5'b0};
      endcase
  end

  else if(current_state == DECONV && col_cnt == 4)
  begin
    if(col_cnt+conv_offset <4 || row_cnt <4 || col_cnt+conv_offset> size_reg+4 || row_cnt > size_reg+4)
    begin
      Addr_img = 15'd16384;
    end
    else
    begin
      case(size_reg)
        5'd7: Addr_img = {image_index_reg,(col_cnt[2:0]+conv_offset[2:0] - 3'd4) ,row_cnt[2:0] - 3'd4};
        5'd15: Addr_img = {image_index_reg,(col_cnt[3:0]+conv_offset[3:0]- 3'd4),row_cnt[3:0] - 3'd4};
        5'd31: Addr_img = {image_index_reg,(col_cnt[4:0]+conv_offset[4:0]- 3'd4),row_cnt[4:0] - 3'd4};
      endcase
    end
  end

  else if(current_state == DECONV)
  begin
    if(row_cnt+conv_offset <4 || col_cnt <4 || row_cnt+conv_offset> size_reg+4 || col_cnt > size_reg+4)
    begin
        Addr_img = 15'd16384;
    end
    else
    begin
      case(size_reg)
        5'd7: Addr_img = {image_index_reg,(row_cnt[2:0] + conv_offset[2:0] - 3'd4), col_cnt[2:0] - 3'd4};
        5'd15: Addr_img = {image_index_reg,(row_cnt[3:0] + conv_offset[3:0] - 3'd4), col_cnt[3:0] - 3'd4};
        5'd31: Addr_img = {image_index_reg,(row_cnt[4:0] + conv_offset[4:0] - 3'd4), col_cnt[4:0] - 3'd4};
      endcase
    end
  end

end

// new_5
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) 
  begin
    for(i=0;i<5;i=i+1) 
      new_5[i] <= 0;
  end

  else
  begin
    if(current_state == CONV)
    begin
      case(row_cnt)
      1: new_5[0] <= DO_img;
      2: new_5[1] <= DO_img;
      3: new_5[2] <= DO_img;
      4: new_5[3] <= DO_img;
      0: new_5[4] <= DO_img;
      endcase
    end

    else if (current_state == DECONV)
    begin
      case(row_cnt)
      1: new_5[0] <= DO_img;
      2: new_5[1] <= DO_img;
      3: new_5[2] <= DO_img;
      4: new_5[3] <= DO_img;
      0: new_5[4] <= DO_img;
      endcase
    end
  end
end

// sram_kernel
always @ (*)
begin
  Addr_kernel = 9'b0;
  DI_kernel = 0;
  WEB_kernel = 1;

  if(current_state == INPUT_2)
  begin
    WEB_kernel = 0;
    DI_kernel = matrix;
    Addr_kernel = kernel_cnt;
  end

  else if(next_state == INIT_CONV)
  begin
    if(init_cnt == 25) Addr_kernel = 0;
    else Addr_kernel = kernel_index_reg * 25 + init_cnt;
  end

  else if (next_state == INIT_DECONV)
  begin
    if(init_cnt == 25) Addr_kernel = 0;
    else Addr_kernel = kernel_index_reg * 25 + init_cnt;
  end
end

//init_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) init_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) init_cnt <= 0;
    else if(init_cnt == 27) init_cnt<=0; //27
    else if(next_state == INIT_CONV) init_cnt<=init_cnt+1;
    else if(next_state == INIT_DECONV) init_cnt <= init_cnt + 1;
    else init_cnt <= 0;
  end
end

// img_cnt
always @ (posedge clk or  negedge rst_n)
begin
  if(!rst_n) img_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) img_cnt <= 0;
    else if(next_state == INPUT_1 || current_state == INPUT_1)
    begin
      if(img_cnt == 15 && col_cnt == size_reg && row_cnt == size_reg) img_cnt <= 0;
      else if(col_cnt == size_reg && row_cnt == size_reg) img_cnt <= img_cnt + 1;  
    end  
    else if (next_state == INPUT_2 || current_state == INPUT_2)
    begin
      if (img_cnt == 15 && col_cnt == 4 && row_cnt == 4) img_cnt <= 0;
      else if(col_cnt == 4 && row_cnt == 4) img_cnt <= img_cnt + 1;
    end
  end
end

// conv_5_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) conv_5_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) conv_5_cnt <= 0;
    else if(current_state == CONV && row_cnt == 4 && col_cnt == size_reg)
    begin
        if(conv_5_cnt == 4) conv_5_cnt <= 0;
        else conv_5_cnt <= conv_5_cnt+1;
    end
  end
end

// conv_offset
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) conv_offset <= 0;
  else
  begin
    if(next_state == IDLE || next_state == WAIT_INVALID_2) conv_offset <= 0;
    else if(current_state == CONV && row_cnt == 4 && col_cnt == size_reg)
    begin
      conv_offset <= conv_offset + 1;
    end

    else if(current_state == DECONV && row_cnt == 4 && col_cnt == size_reg + 8)
    begin
      conv_offset <= conv_offset + 1;
    end
  end
end

// row_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) row_cnt <= 0;
  else
  begin
    if(next_state == IDLE || next_state == WAIT_INVALID_2) row_cnt <= 0;
    else if(next_state == INPUT_1 || current_state == INPUT_1)
    begin
      if (col_cnt == size_reg  && row_cnt == size_reg) row_cnt <= 0;
      else if(col_cnt == size_reg) row_cnt <= row_cnt + 1;
    end
    else if (next_state == INPUT_2 || current_state == INPUT_2)
    begin
      if(col_cnt == 4 && row_cnt == 4) row_cnt <= 0;
      else if(col_cnt == 4) row_cnt <= row_cnt + 1;
    end
    else if(init_cnt == 25) row_cnt <= 0;

    else if (next_state == INIT_CONV )
    begin
      if(row_cnt == 4) row_cnt <= 0;
      else row_cnt <= row_cnt +1;
    end

    else if (current_state == CONV)
    begin
      if(row_cnt == 4) row_cnt <= 0;
      else row_cnt <= row_cnt +1;
    end

    else if (current_state == DECONV)
    begin
      if(row_cnt == 4) row_cnt <= 0;
      else row_cnt <= row_cnt +1;
    end
  end
end

// col_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) col_cnt <= 0;
  else
  begin
    if(next_state == WAIT_INVALID_2 || next_state == IDLE) col_cnt <= 0;
    else if(next_state == INPUT_1 || current_state == INPUT_1)
    begin
      if(col_cnt == size_reg) col_cnt <= 0;
      else col_cnt <= col_cnt + 1;
    end

    else if (next_state == INPUT_2 || current_state == INPUT_2)
    begin
      if(col_cnt == 4) col_cnt <= 0;
      else col_cnt <= col_cnt + 1;
    end

    else if(next_state == INIT_CONV)// || current_state == INIT_CONV)
    begin
      if(col_cnt == 4 && row_cnt == 4) col_cnt <= 0;
      else if(row_cnt == 4) col_cnt <= col_cnt+1;
    end

    else if (next_state == CONV && current_state == INIT_CONV) col_cnt <= 5;


    else if (current_state == CONV)
    begin
      // if(col_cnt == (conv_offset+4) && row_cnt == 4) col_cnt <= 5;
      if(col_cnt == size_reg && row_cnt == 4) col_cnt <=  4;
      else if(row_cnt == 4) col_cnt <= col_cnt + 1;
    end

    else if(next_state == DECONV && current_state == INIT_DECONV) col_cnt <= 5;

    else if (current_state == DECONV)
    begin
      // if(col_cnt == (conv_offset+4) && row_cnt == 4) col_cnt <= 5;
      if(col_cnt == size_reg + 8 && row_cnt == 4) col_cnt <=  4;
      else if(row_cnt == 4) col_cnt <= col_cnt + 1;
    end
  end
end

// size_reg
always @ (*)
begin
  size_reg = 0;
  case(matrix_size_reg)
    2'd0: size_reg = 6'd7;
    2'd1: size_reg = 6'd15;
    2'd2: size_reg = 6'd31;
  endcase
end

// kernel_cnt
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) kernel_cnt <= 0;
  else
  begin
    if(current_state == INPUT_2 && kernel_cnt == 399) kernel_cnt <= kernel_cnt;
    else if(current_state == INPUT_2) kernel_cnt <= kernel_cnt + 1;
    else kernel_cnt <= 0;
  end
end

//matrix_size_reg
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) matrix_size_reg <= 0;
  else
  begin
    if(next_state == INPUT_1 && current_state == IDLE) matrix_size_reg <= matrix_size;
  end
end

// FSM filp-flop
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) current_state <= IDLE;
  else current_state <= next_state;
end

// out_valid
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) out_valid <= 0;
  else
  begin
    if (current_state == CONV && conv_out_cnt > ((size_reg -3)/2) *((size_reg -3)/2) && conv_out_19_cnt == 3)
    begin
      out_valid <= 0;
    end
    else if(current_state == CONV && conv_out_19_cnt == 3)
    begin
      out_valid <= 1;
    end

    else if (current_state == DECONV && deconv_out_cnt == (size_reg+5) * (size_reg+5) + 1 && deconv_out_19_cnt == 3)
    begin
      out_valid <= 0;
    end

    else if(current_state == DECONV && deconv_out_19_cnt == 3)
    begin
      out_valid <= 1;
    end
  end
end

// out_value
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) out_value <= 0;
  else
  begin
    // if(next_state == WAIT_INVALID_2 || next_state == IDLE) out_value <= 0;
    if(current_state == CONV && conv_out_cnt > ((size_reg -3)/2) *((size_reg -3)/2) && conv_out_19_cnt == 3) out_value <= 0;
    else if(current_state == DECONV && deconv_out_cnt == (size_reg+5) * (size_reg+5) + 1 && deconv_out_19_cnt == 3) out_value <= 0;
    else if(current_state == CONV) out_value <= temp_out[0];
    else if(current_state == DECONV) out_value <= deconv_temp_out[0];
  end
end

endmodule






// module SRAM_IMG(A,DO,DI,CK,WEB,OE,CS);
// input [13:0] A;
// input [7:0] DI;
// input CK, WEB,OE,CS;

// output [7:0] DO;

// SRAM_IMG_16384 Img (A[0],A[1],A[2],A[3],A[4],A[5],A[6],A[7],A[8],A[9],A[10],A[11],A[12],A[13],DO[0],
//                        DO[1],DO[2],DO[3],DO[4],DO[5],DO[6],DO[7],DI[0],DI[1],DI[2],DI[3],
//                        DI[4],DI[5],DI[6],DI[7],CK,WEB,OE, CS);

// endmodule

// module SRAM_KERNEL(A,DO,DI,CK,WEB,OE,CS);
//   output     [7:0] DO;
//   input      [7:0] DI;
//   input      [8:0] A;
//   input      WEB;                                     
//   input      CK;                                      
//   input      CS;                                      
//   input      OE;      


// SRAM_SP_KERNEL Kernel (A[0],A[1],A[2],A[3],A[4],A[5],A[6],A[7],A[8],DO[0],DO[1],DO[2],DO[3],DO[4],
//                        DO[5],DO[6],DO[7],DI[0],DI[1],DI[2],DI[3],DI[4],DI[5],DI[6],DI[7],
//                        CK,WEB,OE, CS);
// endmodule

// module SRAM_OUTPUT(A, DOA, DIA, WEAN, CKA, CSA, OEA, B, DOB, DIB, WEBN, CKB, CSB, OEB);
//     input [10:0] A, B;
//     input [19:0] DIA, DIB;
//     input WEAN, WEBN, CKA, CKB, CSA, CSB, OEA, OEB;
//     output [19:0] DOA, DOB;

//     SRAM_DP_OUT S0 (.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.A5(A[5]),.A6(A[6]),.A7(A[7]),.A8(A[8]),.A9(A[9]),.A10(A[10]),.B0(B[0]),.B1(B[1]),.B2(B[2]),.B3(B[3]),.B4(B[4]),
//                     .B5(B[5]),.B6(B[6]),.B7(B[7]),.B8(B[8]),.B9(B[9]),.B10(B[10]),.DOA0(DOA[0]),.DOA1(DOA[1]),.DOA2(DOA[2]),.DOA3(DOA[3]),.DOA4(DOA[4]),
//                     .DOA5(DOA[5]),.DOA6(DOA[6]),.DOA7(DOA[7]),.DOA8(DOA[8]),.DOA9(DOA[9]),.DOA10(DOA[10]),.DOA11(DOA[11]),.DOA12(DOA[12]),
//                     .DOA13(DOA[13]),.DOA14(DOA[14]),.DOA15(DOA[15]),.DOA16(DOA[16]),.DOA17(DOA[17]),.DOA18(DOA[18]),.DOA19(DOA[19]),
//                     .DOB0(DOB[0]),.DOB1(DOB[1]),.DOB2(DOB[2]),.DOB3(DOB[3]),.DOB4(DOB[4]),.DOB5(DOB[5]),.DOB6(DOB[6]),.DOB7(DOB[7]),
//                     .DOB8(DOB[8]),.DO89(DOB[9]),.DOB10(DOB[10]),.DOB11(DOB[11]),.DOB12(DOB[12]),.DOB13(DOB[13]),.DOB14(DOB[14]),
//                     .DOB15(DOB[15]),.DOB16(DOB[16]),.DOB17(DOB[17]),.DOB18(DOB[18]),.DOB19(DOB[19]),.DIA0(DIA[0]),.DIA1(DIA[1]),
//                     .DIA2(DIA[2]),.DIA3(DIA[3]),.DIA4(DIA[4]),.DIA5(DIA[5]),.DIA6(DIA[6]),.DIA7(DIA[7]),.DIA8(DIA[8]),.DIA9(DIA[9]),
//                     .DIA10(DIA[10]),.DIA11(DIA[11]),.DIA12(DIA[12]),.DIA13(DIA[13]),.DIA14(DIA[14]),.DIA15(DIA[15]),.DIA16(DIA[16]),
//                     .DIA17(DIA[17]),.DIA18(DIA[18]),.DIA19(DIA[19]),.DIB0(DIB[0]),.DIB1(DIB[1]),.DIB2(DIB[2]),.DIB3(DIB[3]),
//                     .DIB4(DIB[4]),,DIB5(DIB[5]),.DIB6(DIB[6]),.DIB7(DIB[7]),.DIB8(DIB[8]),.DIB9(DIB[9]),.DIB10(DIB[10]),.DIB11(DIB[11]),
//                     .DIB12(DIB[12]),.DIB13(DIB[13]),.DIB14(DIB[14]),.DIB15(DIB[15]),.DIB16(DIB[16]),.DIB17(DIB[17]),.DIB18(DIB[18]),
//                     .DIB19(DIB[19]),.WEAN(WEAN),.WEBN(WEBN),.CKA(CKA),.CKB(CKB),.CSA(CSA),.CSB(CSB),.OEA(OEA),.OEB(OEB));
// endmodule
