module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated types.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system
//
// Each enumerated type defines a set of named states that the corresponding process can be in.
// typedef enum logic [1:0]{
//     IDLE,

//     MAKE_DRINK,
//     SUPPLY,
//     CHECK_DATE
// } state_t;

typedef enum logic [2:0]{
    M_IDLE,
    M_INPUT,
    M_WAIT_RESPONSE,
    M_CHECK,
    M_MAKE_DRINK,
    M_BUFFER_DRAM_WRITE,
    M_DRAM_WRITE,
    M_OUTPUT
} state_m;

typedef enum logic [2:0]{
    S_IDLE,
    S_INPUT,
    S_WAIT_RESPONSE,
    S_SUPPLY,
    S_BUFFER_DRAM_WRITE,
    S_DRAM_WRITE,
    S_OUTPUT
} state_s;

typedef enum logic [2:0]{
    C_IDLE,
    C_INPUT,
    C_WAIT_RESPONSE,
    C_CHECK,
    C_BUFFER,
    C_OUTPUT
} state_c;

// REGISTERS
// state_t state, nstate;
state_m make_state, make_nstate;
state_s supply_state, supply_nstate;
state_c check_state, check_nstate;
// logic [2:0] bev_type;
Bev_Type bev_type;
// logic [1:0] bev_size;
Bev_Size bev_size;
logic [7:0] barrel_no;


logic [3:0] today_mon;
logic [3:0] expire_mon;
logic [4:0] today_day;
logic [4:0] expire_day;

logic [11:0] Black_Tea_Vol, Green_Tea_Vol, Milk_Vol, Pineapple_Juice_Vol;
logic [12:0] Black_Tea_tot_Vol, Green_Tea_tot_Vol, Milk_tot_Vol, Pineapple_Juice_tot_Vol;
logic [3:0] Dram_expire_mon;
logic [4:0] Dram_exipre_day;

logic Black_Tea_enough, Green_tea_enough, Milk_enough, Pineapple_Juice_enough;
// logic [9:0] beverge_Vol;
logic [11:0] Black_Tea_supply_vol, Green_Tea_supply_vol, Milk_supply_vol, Pineapple_Juice_supply_vol;
logic [1:0] supply_vol_cnt;
logic Black_Tea_overflow, Green_Tea_overflow, Milk_overflow, Pineapple_Juice_overflow;
Error_Msg temp_err_msg;
logic [9:0] Black_Tea_need_Vol,Green_Tea_need_Vol, Milk_need_Vol, Pineapple_Juice_need_Vol;
logic [9:0] Black_Tea_need_Vol_reg,Green_Tea_need_Vol_reg, Milk_need_Vol_reg, Pineapple_Juice_need_Vol_reg;


// // STATE MACHINE
// always_ff @( posedge clk or negedge inf.rst_n) begin : TOP_FSM_SEQ
//     if (!inf.rst_n) state <= IDLE;
//     else state <= nstate;
// end

// always_comb begin : TOP_FSM_COMB
//     case(state)
//         IDLE: begin
//             if (inf.sel_action_valid)
//             begin
//                 case(inf.D.d_act[0])
//                     Make_drink: nstate = DRAM_READ;
//                     Supply: nstate = SUPPLY;
//                     Check_Valid_Date: nstate = CHECK_DATE;
//                     default: nstate = IDLE;
//                 endcase
//             end
//             else
//             begin
//                 nstate = IDLE;
//             end
//         end
//         default: nstate = IDLE;
//     endcase
// end

// assign Black_Tea_enough = (bev_type == Green_Milk_Tea) || (bev_type == Green_Tea) || (bev_type == Pineapple_Juice) || 
//                         (bev_type == Black_Tea && Black_Tea_Vol >= beverge_Vol) || (bev_type == Milk_Tea && Black_Tea_Vol >= 3*beverge_Vol/4) ||
//                         (bev_type == Extra_Milk_Tea && Black_Tea_Vol >= beverge_Vol/2) || (bev_type == Super_Pineapple_Tea && Black_Tea_Vol >= beverge_Vol/2) ||
//                         (bev_type == Super_Pineapple_Milk_Tea && Black_Tea_Vol >= beverge_Vol/2);

// assign Green_tea_enough = (bev_type == Black_Tea) || (bev_type == Milk_Tea) || (bev_type == Extra_Milk_Tea) || (bev_type == Green_Tea && Green_Tea_Vol >= beverge_Vol) ||
//                         (bev_type == Green_Milk_Tea && Green_Tea_Vol >= beverge_Vol/2) || (bev_type == Pineapple_Juice)||
//                         (bev_type == Super_Pineapple_Tea) || (bev_type == Super_Pineapple_Milk_Tea);

// assign Milk_enough = (bev_type == Black_Tea) || (bev_type == Milk_Tea && Milk_Vol >= beverge_Vol/4) || (bev_type == Extra_Milk_Tea && Milk_Vol >= beverge_Vol/2) ||
//                     (bev_type == Green_Tea) || (bev_type == Green_Milk_Tea && Milk_Vol >= beverge_Vol/2) || (bev_type == Pineapple_Juice) ||
//                     (bev_type == Super_Pineapple_Tea) || (bev_type == Super_Pineapple_Milk_Tea && Milk_Vol >= beverge_Vol/4);

// assign Pineapple_Juice_enough = (bev_type == Black_Tea) || (bev_type == Milk_Tea) || (bev_type == Extra_Milk_Tea) || (bev_type == Green_Tea) ||
//                                 (bev_type == Green_Milk_Tea) || (bev_type == Pineapple_Juice && Pineapple_Juice_Vol >= beverge_Vol) ||
//                                 (bev_type == Super_Pineapple_Tea && Pineapple_Juice_Vol >= beverge_Vol/2) || (bev_type == Super_Pineapple_Milk_Tea && Pineapple_Juice_Vol >= beverge_Vol/4);
assign Pineapple_Juice_enough = Pineapple_Juice_Vol >= Pineapple_Juice_need_Vol_reg;
assign Milk_enough = Milk_Vol >= Milk_need_Vol_reg;
assign Green_tea_enough = Green_Tea_Vol >= Green_Tea_need_Vol_reg;
assign Black_Tea_enough = Black_Tea_Vol >= Black_Tea_need_Vol_reg;

assign Black_Tea_tot_Vol = Black_Tea_Vol + Black_Tea_supply_vol;
assign Green_Tea_tot_Vol = Green_Tea_Vol + Green_Tea_supply_vol ;
assign Milk_tot_Vol = Milk_Vol + Milk_supply_vol;
assign Pineapple_Juice_tot_Vol = Pineapple_Juice_Vol + Pineapple_Juice_supply_vol;

assign Black_Tea_overflow = Black_Tea_tot_Vol[12];
assign Green_Tea_overflow = Green_Tea_tot_Vol[12];
assign Milk_overflow = Milk_tot_Vol[12];
assign Pineapple_Juice_overflow = Pineapple_Juice_tot_Vol[12];

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        Black_Tea_need_Vol_reg <= 0;
        Green_Tea_need_Vol_reg <= 0;
        Milk_need_Vol_reg <= 0;
        Pineapple_Juice_need_Vol_reg <= 0; 
    end

    else
    begin
        Black_Tea_need_Vol_reg <= Black_Tea_need_Vol;
        Green_Tea_need_Vol_reg <= Green_Tea_need_Vol;
        Milk_need_Vol_reg <= Milk_need_Vol;
        Pineapple_Juice_need_Vol_reg <= Pineapple_Juice_need_Vol;
    end
end

always_comb
begin
    Black_Tea_need_Vol = 0;
    case(bev_type)
        Black_Tea:
        begin
            case(bev_size)
                L: Black_Tea_need_Vol =960;
                M: Black_Tea_need_Vol =720;
                S: Black_Tea_need_Vol =480;
            endcase
        end
        Milk_Tea:
        begin
            case(bev_size)
                L: Black_Tea_need_Vol =720;
                M:Black_Tea_need_Vol = 540;
                S: Black_Tea_need_Vol =360;
            endcase
        end
        Extra_Milk_Tea:
        begin
            case(bev_size)
                L: Black_Tea_need_Vol =480;
                M: Black_Tea_need_Vol =360;
                S: Black_Tea_need_Vol =240;
            endcase
        end
        Super_Pineapple_Tea:
        begin
            case(bev_size)
                L: Black_Tea_need_Vol =480;
                M: Black_Tea_need_Vol =360;
                S: Black_Tea_need_Vol =240;
            endcase
        end
        Super_Pineapple_Milk_Tea:
        begin
            case(bev_size)
                L: Black_Tea_need_Vol =480;
                M: Black_Tea_need_Vol =360;
                S: Black_Tea_need_Vol =240;
            endcase
        end
    endcase
end

always_comb
begin
    Green_Tea_need_Vol = 0;
    case(bev_type)
        Green_Tea:
        begin
            case(bev_size)
                L: Green_Tea_need_Vol = 960;
                M: Green_Tea_need_Vol = 720;
                S: Green_Tea_need_Vol = 480;
            endcase
        end
        Green_Milk_Tea:
        begin
            case(bev_size)
                L: Green_Tea_need_Vol = 480;
                M: Green_Tea_need_Vol = 360;
                S: Green_Tea_need_Vol = 240;
            endcase
        end
    endcase
end

always_comb
begin
    Milk_need_Vol = 0;
    case(bev_type)
        Milk_Tea:
        begin
            case(bev_size)
                L: Milk_need_Vol = 240;
                M: Milk_need_Vol = 180;
                S: Milk_need_Vol = 120;
            endcase
        end

        Extra_Milk_Tea:
        begin
            case(bev_size)
                L: Milk_need_Vol = 480;
                M: Milk_need_Vol = 360;
                S: Milk_need_Vol = 240;
            endcase
        end

        Green_Milk_Tea:
        begin
            case(bev_size)
                L: Milk_need_Vol = 480;
                M: Milk_need_Vol = 360;
                S: Milk_need_Vol = 240;
            endcase
        end

        Super_Pineapple_Milk_Tea:
        begin
            case(bev_size)
                L: Milk_need_Vol = 240;
                M: Milk_need_Vol = 180;
                S: Milk_need_Vol = 120;
            endcase
        end
    endcase
end

always_comb
begin
    Pineapple_Juice_need_Vol = 0;
    case(bev_type)
        Pineapple_Juice:
        begin
            case(bev_size)
                L: Pineapple_Juice_need_Vol = 960;
                M: Pineapple_Juice_need_Vol = 720;
                S: Pineapple_Juice_need_Vol = 480;
            endcase
        end

        Super_Pineapple_Tea:
        begin
            case(bev_size)
                L: Pineapple_Juice_need_Vol = 480;
                M: Pineapple_Juice_need_Vol = 360;
                S: Pineapple_Juice_need_Vol = 240;
            endcase
        end

        Super_Pineapple_Milk_Tea:
        begin
            case(bev_size)
                L: Pineapple_Juice_need_Vol = 240;
                M: Pineapple_Juice_need_Vol = 180;
                S: Pineapple_Juice_need_Vol = 120;
            endcase
        end
    endcase
end

//check_nstate
always_comb
begin
    check_nstate = check_state;
    case(check_state)
        C_IDLE:
        begin
            if(inf.sel_action_valid && inf.D.d_act[0] == Check_Valid_Date)
            begin
                check_nstate = C_INPUT;
            end   
        end

        C_INPUT:
        begin
            if(inf.box_no_valid) check_nstate = C_WAIT_RESPONSE;
        end

        C_WAIT_RESPONSE:
        begin
            if(inf.C_out_valid) check_nstate = C_CHECK;
        end

        C_CHECK:
        begin
            check_nstate = C_BUFFER;
        end

        C_BUFFER:
        begin
            check_nstate = C_OUTPUT;
        end

        C_OUTPUT:
        begin
            check_nstate = C_IDLE;
        end
    endcase
end

// check_state
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        check_state <= C_IDLE;
    end

    else check_state <= check_nstate;
end

// supply_nstate
always_comb 
begin
    supply_nstate = supply_state;
    case(supply_state)
        S_IDLE:
        begin
            if(inf.sel_action_valid && inf.D.d_act[0] == Supply)
            begin
                supply_nstate = S_INPUT;
            end   
        end

        S_INPUT:
        begin
            if(inf.box_sup_valid && supply_vol_cnt == 3) supply_nstate = S_WAIT_RESPONSE;
        end

        S_WAIT_RESPONSE:
        begin
            if(inf.C_out_valid) supply_nstate = S_SUPPLY;
        end

        S_SUPPLY:
        begin
            supply_nstate = S_BUFFER_DRAM_WRITE;
        end

        S_BUFFER_DRAM_WRITE:
        begin
            supply_nstate = S_DRAM_WRITE;
        end

        S_DRAM_WRITE:
        begin
            if(inf.C_out_valid) supply_nstate = S_OUTPUT;
        end

        S_OUTPUT:
        begin
            supply_nstate = S_IDLE;
        end
    endcase
end

// supply_vol_cnt
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) supply_vol_cnt <= 0;
    else
    begin
        if(supply_state == S_INPUT && inf.box_sup_valid)
        begin
            supply_vol_cnt <= supply_vol_cnt + 1;
        end
    end
end

// Black_Tea_supply_vol && Green_Tea_supply_vol && Milk_supply_vol && Pineapple_Juice_supply_vol
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        Black_Tea_supply_vol <= 0;
        Green_Tea_supply_vol <= 0;
        Milk_supply_vol <= 0;
        Pineapple_Juice_supply_vol <= 0;
    end

    else
    begin
        if(inf.box_sup_valid)
        begin
            case(supply_vol_cnt)
                0: Black_Tea_supply_vol <= inf.D.d_ing[0];
                1: Green_Tea_supply_vol <= inf.D.d_ing[0];
                2: Milk_supply_vol <= inf.D.d_ing[0];
                3: Pineapple_Juice_supply_vol <= inf.D.d_ing[0];
            endcase
        end
    end
end

// supply_state
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) supply_state <= S_IDLE;
    else
    begin
        supply_state <= supply_nstate;
    end
end

// make_nstate
always_comb 
begin
    make_nstate = make_state;
    case(make_state)
        M_IDLE:
        begin
            if(inf.sel_action_valid && inf.D.d_act[0] == Make_drink)
            begin
                make_nstate = M_INPUT;
            end
        end

        M_INPUT:
        begin
            if(inf.box_no_valid)
            begin
                make_nstate = M_WAIT_RESPONSE;
            end  
        end

        M_WAIT_RESPONSE:
        begin
            if(inf.C_out_valid) make_nstate = M_CHECK;
        end

        M_CHECK:
        begin
            make_nstate = M_MAKE_DRINK;
        end

        M_MAKE_DRINK:
        begin
            if(temp_err_msg == 2'b00) make_nstate = M_BUFFER_DRAM_WRITE;
            else make_nstate = M_OUTPUT;
        end

        M_BUFFER_DRAM_WRITE:
        begin
            make_nstate = M_DRAM_WRITE;
        end

        M_DRAM_WRITE:
        begin
            if(inf.C_out_valid) make_nstate = M_OUTPUT;
        end

        M_OUTPUT:
        begin
            make_nstate = M_IDLE;
        end
    endcase
end

// // beverge_Vol
// always_comb
// begin
//     beverge_Vol = 0;
//     case(bev_size)
//         L: beverge_Vol = 960;
//         M: beverge_Vol = 720;
//         S: beverge_Vol = 480;
//     endcase
// end

// inf.out_valid && inf.complete
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        inf.out_valid <= 0;
        inf.complete <= 0;
    end

    else
    begin
        if(make_nstate == M_OUTPUT)
        begin
            inf.out_valid <= 1;
            if(temp_err_msg == 2'b00) 
            begin
                inf.complete <= 1;
            end

            else
            begin
                inf.complete <= 0;
            end
        end

        else if(supply_nstate == S_OUTPUT)
        begin
            inf.out_valid <= 1;
            if(temp_err_msg == 2'b00) 
            begin
                inf.complete <= 1;
            end

            else
            begin
                inf.complete <= 0;
            end
        end

        else if(check_nstate == C_OUTPUT)
        begin
            inf.out_valid <= 1;
            if(temp_err_msg == 2'b00) 
            begin
                inf.complete <= 1;
            end

            else
            begin
                inf.complete <= 0;
            end
        end

        else if(make_nstate == M_IDLE || supply_nstate == S_IDLE || check_nstate == C_IDLE)
        begin
            inf.out_valid <= 0;
            inf.complete <= 0;
        end
    end
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)inf.err_msg <= No_Err;
    else
    begin
        if(make_nstate == M_OUTPUT)
        begin
            inf.err_msg <= temp_err_msg;
        end

        else if(supply_nstate == S_OUTPUT)
        begin
            inf.err_msg <= temp_err_msg;
        end

        else if(check_nstate == C_OUTPUT)
        begin
            inf.err_msg <= temp_err_msg;
        end

        else if(make_nstate == M_IDLE || supply_nstate == S_IDLE || check_nstate == C_IDLE)
        begin
            inf.err_msg <= No_Err;
        end
    end
end

// inf.err_msg
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) temp_err_msg <= No_Err;
    else
    begin
        if(make_state == M_OUTPUT || supply_state == S_OUTPUT || check_state == C_OUTPUT)
        begin
            temp_err_msg <= No_Err;
        end
        else if (make_state == M_CHECK && (today_mon > Dram_expire_mon || (today_mon == Dram_expire_mon && today_day > Dram_exipre_day)))
        begin
            temp_err_msg <= No_Exp;
        end
        
        else if(make_state == M_CHECK && (!Black_Tea_enough || !Green_tea_enough || !Milk_enough || !Pineapple_Juice_enough))
        begin
            temp_err_msg <= No_Ing;
        end

        else if(supply_state == S_SUPPLY && (Black_Tea_overflow || Green_Tea_overflow || Milk_overflow || Pineapple_Juice_overflow))
        begin
            temp_err_msg <= Ing_OF;
        end

        else if (check_state == C_CHECK && (today_mon > Dram_expire_mon || (today_mon == Dram_expire_mon && today_day > Dram_exipre_day)))
        begin
            temp_err_msg <= No_Exp;
        end
    end
end

// Black_Tea_Vol && Green_Tea_Vol && Milk_Vol && Pineapple_Juice_Vol && Dram_expire_mon && Dram_exipre_day
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        Black_Tea_Vol <= 0;
        Green_Tea_Vol <= 0;
        Milk_Vol <= 0;
        Pineapple_Juice_Vol <= 0;
        Dram_expire_mon <= 0;
        Dram_exipre_day <= 0;
    end

    else
    begin
        if(inf.C_out_valid && (make_state == M_WAIT_RESPONSE))
        begin
            Black_Tea_Vol <= inf.C_data_r[63:52];
            Green_Tea_Vol <=  inf.C_data_r[51:40]; 
            Dram_expire_mon <= inf.C_data_r[35:32];
            Milk_Vol <=  inf.C_data_r[31:20];
            Pineapple_Juice_Vol <= inf.C_data_r[19:8];
            Dram_exipre_day <= inf.C_data_r[4:0];
        end

        else if (make_state == M_MAKE_DRINK && temp_err_msg == 2'b00)
        begin
            case(bev_type)
                Black_Tea:
                begin
                    Black_Tea_Vol <= Black_Tea_Vol - Black_Tea_need_Vol_reg;
                end

                Milk_Tea:
                begin
                    Black_Tea_Vol <= Black_Tea_Vol - Black_Tea_need_Vol_reg;
                    Milk_Vol <= Milk_Vol - Milk_need_Vol_reg;
                end

                Extra_Milk_Tea:
                begin
                    Black_Tea_Vol <= Black_Tea_Vol - Black_Tea_need_Vol_reg;
                    Milk_Vol <= Milk_Vol - Milk_need_Vol_reg;
                end

                Green_Tea:
                begin
                    Green_Tea_Vol <= Green_Tea_Vol - Green_Tea_need_Vol_reg;
                end

                Green_Milk_Tea:
                begin
                    Green_Tea_Vol <= Green_Tea_Vol - Green_Tea_need_Vol_reg;
                    Milk_Vol <= Milk_Vol - Milk_need_Vol_reg;
                end

                Pineapple_Juice:
                begin
                    Pineapple_Juice_Vol <= Pineapple_Juice_Vol - Pineapple_Juice_need_Vol_reg;
                end

                Super_Pineapple_Tea:
                begin
                    Black_Tea_Vol <= Black_Tea_Vol - Black_Tea_need_Vol_reg;
                    Pineapple_Juice_Vol <= Pineapple_Juice_Vol - Pineapple_Juice_need_Vol_reg;
                end

                Super_Pineapple_Milk_Tea:
                begin
                    Black_Tea_Vol <= Black_Tea_Vol - Black_Tea_need_Vol_reg;
                    Milk_Vol <= Milk_Vol - Milk_need_Vol_reg;
                    Pineapple_Juice_Vol <= Pineapple_Juice_Vol - Pineapple_Juice_need_Vol_reg;
                end
            endcase
        end

        else if(inf.C_out_valid && (supply_state == S_WAIT_RESPONSE))
        begin
            Black_Tea_Vol <= inf.C_data_r[63:52];
            Green_Tea_Vol <=  inf.C_data_r[51:40]; 
            Dram_expire_mon <= inf.C_data_r[35:32];
            Milk_Vol <=  inf.C_data_r[31:20];
            Pineapple_Juice_Vol <= inf.C_data_r[19:8];
            Dram_exipre_day <= inf.C_data_r[4:0];
        end

        else if (supply_state == S_SUPPLY)
        begin
            if(Black_Tea_overflow) Black_Tea_Vol <= 12'd4095;
            else Black_Tea_Vol <= Black_Tea_tot_Vol[11:0];

            if(Green_Tea_overflow) Green_Tea_Vol <= 12'd4095;
            else Green_Tea_Vol <= Green_Tea_tot_Vol[11:0];

            if(Milk_overflow) Milk_Vol <= 12'd4095;
            else Milk_Vol <= Milk_tot_Vol[11:0];

            if(Pineapple_Juice_overflow) Pineapple_Juice_Vol <= 12'd4095;
            else Pineapple_Juice_Vol <= Pineapple_Juice_tot_Vol[11:0];
        end

        else if(inf.C_out_valid && (check_state == C_WAIT_RESPONSE))
        begin
            Dram_expire_mon <= inf.C_data_r[35:32];
            Dram_exipre_day <= inf.C_data_r[4:0];
        end
    end
end


// C_in_valid && C_r_wb && inf.C_addr && inf.C_data_w
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) 
    begin
        inf.C_in_valid <= 0;
        inf.C_r_wb <= 0;
        inf.C_addr <= 0;
        inf.C_data_w <= 0;
    end

    else
    begin
        if(make_state == M_INPUT && make_nstate == M_WAIT_RESPONSE)
        begin
            inf.C_in_valid <= 1; 
            inf.C_r_wb <= 1;  
            inf.C_addr <= inf.D.d_box_no[0];
        end

        else if(make_state == M_BUFFER_DRAM_WRITE)
        begin
            inf.C_in_valid <= 1;
            inf.C_r_wb <= 0;
            inf.C_addr <= barrel_no;
            inf.C_data_w <= {Black_Tea_Vol,Green_Tea_Vol,4'b0,Dram_expire_mon,Milk_Vol,Pineapple_Juice_Vol,3'b0,Dram_exipre_day};
        end

        else if(supply_state == S_INPUT && supply_nstate == S_WAIT_RESPONSE)
        begin
            inf.C_in_valid <= 1; 
            inf.C_r_wb <= 1;  
            inf.C_addr <= barrel_no;
        end

        else if(supply_state == S_BUFFER_DRAM_WRITE)
        begin
            inf.C_in_valid <= 1;
            inf.C_r_wb <= 0;
            inf.C_addr <= barrel_no;
            inf.C_data_w <= {Black_Tea_Vol,Green_Tea_Vol,4'b0,expire_mon,Milk_Vol,Pineapple_Juice_Vol,3'b0,expire_day};
        end

        else if(check_state == C_INPUT && check_nstate == C_WAIT_RESPONSE)
        begin
            inf.C_in_valid <= 1; 
            inf.C_r_wb <= 1;  
            inf.C_addr <= inf.D.d_box_no[0];
        end

        else
        begin
            inf.C_in_valid <= 0;
            inf.C_r_wb <= 0;
            inf.C_addr <= 0;    
            inf.C_data_w <= 0;        
        end
    end
end

// bev_type
always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) bev_type <= Black_Tea;
    else
    begin
        if(inf.type_valid)
        begin
            bev_type <= inf.D.d_type[0];
        end
    end
end

// bev_size
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) bev_size <= S;
    else
    begin
        if(inf.size_valid)
        begin
            bev_size <= inf.D.d_size[0];
        end
    end
end

// today_mon && today_day
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        today_mon <= 0;
        today_day <= 0;
    end

    else
    begin
        if(inf.date_valid)
        begin
            today_mon <= inf.D.d_date[0].M;
            today_day <= inf.D.d_date[0].D;
        end
    end
end

// expire_mon && expire_day
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        expire_mon <= 0;
        expire_day <= 0;
    end

    else
    begin
        if(inf.date_valid)
        begin
            expire_mon <= inf.D.d_date[0].M;
            expire_day <= inf.D.d_date[0].D;
        end
    end
end

// barrel_no
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        barrel_no <= 0;
    end

    else
    begin
        if(inf.box_no_valid)
        begin
            barrel_no <= inf.D.d_box_no[0];
        end
    end
end

// make_state
always_ff @( posedge clk or negedge inf.rst_n) begin : MAKE_DRINK_FSM_SEQ
    if (!inf.rst_n) make_state <= M_IDLE;
    else make_state <= make_nstate;
end

endmodule