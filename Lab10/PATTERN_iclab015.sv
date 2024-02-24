/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
real CYCLE = 10.0;
integer latency, tot_latency;
integer seed = 231;
integer box_id;
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
integer gap;
integer patCount;
integer PATNUM = 10000;

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)]; 
Error_Msg err_msg; 
Data D;
Bev_Bal init_Bev;
Order_Info make_order;
Date input_date;
Action curAction;
logic [11:0] black_tea_supply_vol;
logic [11:0] green_tea_supply_vol;
logic [11:0] milk_supply_vol;
logic [11:0] pineapple_juice_supply_vol;
Error_Msg golden_err_msg;
logic golden_complete;
logic [9:0] beverage_vol;
logic Black_Tea_enough, Green_tea_enough, Milk_enough, Pineapple_Juice_enough;
logic [12:0] Black_Tea_tot_Vol, Green_Tea_tot_Vol, Milk_tot_Vol, Pineapple_Juice_tot_Vol;

//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;

	function new(int seed); 
		this.srandom(seed); 
	endfunction

    constraint range{
        act_id inside{Make_drink, Supply, Check_Valid_Date};
    }
endclass

/**
 * Class representing a random box from 0 to 31.
 */
class random_box;
    randc logic [7:0] box_id;

	function new(int seed); 
		this.srandom(seed); 
	endfunction

    constraint range{
        box_id inside{[0:255]};
    }
endclass

/**
 * Class representing a random beverage type from 0 to 7.
 */
class random_order;
    randc Order_Info order_id;

    function new(int seed); 
		this.srandom(seed); 
	endfunction

    constraint range{
        order_id.Bev_Type_O inside{Black_Tea, Milk_Tea, Extra_Milk_Tea, Green_Tea, Green_Milk_Tea, 
                            Pineapple_Juice, Super_Pineapple_Tea, Super_Pineapple_Milk_Tea};
                        
        order_id.Bev_Size_O inside{L, M ,S};
    }
endclass


class random_date;
    randc Date date_id;

    function new(int seed); 
		this.srandom(seed); 
	endfunction

    constraint range{
        date_id.M inside{[1:12]};
        (date_id.M == 1) -> date_id.D inside {[1:31]};
        (date_id.M == 2) -> date_id.D inside {[1:28]};
        (date_id.M == 3) -> date_id.D inside {[1:31]};
        (date_id.M == 4) -> date_id.D inside {[1:30]};
        (date_id.M == 5) -> date_id.D inside {[1:31]};
        (date_id.M == 6) -> date_id.D inside {[1:30]};
        (date_id.M == 7) -> date_id.D inside {[1:31]};
        (date_id.M == 8) -> date_id.D inside {[1:31]};
        (date_id.M == 9) -> date_id.D inside {[1:30]};
        (date_id.M == 10) -> date_id.D inside {[1:31]};
        (date_id.M == 11) -> date_id.D inside {[1:30]};
        (date_id.M == 12) -> date_id.D inside {[1:31]};
    }
endclass

class random_supply;
    randc logic [11:0] black_tea_supply_vol;
    randc logic [11:0] green_tea_supply_vol;
    randc logic [11:0] milk_supply_vol;
    randc logic [11:0] pineapple_juice_supply_vol;
	function new(int seed); 
		this.srandom(seed); 
	endfunction

    constraint range{
        black_tea_supply_vol inside{[0:4095]};
        green_tea_supply_vol inside{[0:4095]};
        milk_supply_vol inside{[0:4095]};
        pineapple_juice_supply_vol inside{[0:4095]};
    }
endclass

random_act random_action = new(seed);
random_box random_barrel = new(seed);
random_order random_bevOrder = new(seed);
random_date random_Date = new(seed);
random_supply random_Supply = new(seed);

//================================================================
// initial
//================================================================
initial $readmemh(DRAM_p_r, golden_DRAM);

initial 
begin
    reset_task;
    for(patCount = 0; patCount < PATNUM; patCount = patCount + 1)
    begin
        random_act_task;
        random_box_id_task;
        // $display("CurAction = %d", curAction);
        get_dram_task;
        action_sel_task;
        wait_outvalid_task;
        check_and_task;
        store_dram_task;
        tot_latency = tot_latency + latency;
        $display("\033[0;34mPass Pattern No.%4d \033[m \033[0;32mLatency : %3d\033[m",patCount ,latency);
    end
    YOU_PASS_task;
end


//================================================================
// reset_task
//================================================================

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                            Congratulations!                           *");
    $display("*                   Your execution cycles = %5d cycles               *", tot_latency);
    $display("*                   Your clock period = %.1f ns                         *", CYCLE);
    $display("*                   Total Latency = %.1f ns                        *", tot_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

task check_and_task;
    begin
        case(curAction)
            Make_drink: make_drink_check_ans_task;
            Supply: supply_check_ans_task;
            Check_Valid_Date: check_valid_date_check_ans_task;
        endcase 
        if(golden_err_msg === No_Err)
        begin
            golden_complete = 1'b1;
        end

        else
        begin
            golden_complete = 1'b0;
        end

        if(inf.err_msg !== golden_err_msg || inf.complete !== golden_complete) 
        begin
            $display("*************************************************************************");     
            $display("*                          Wrong Answer                                 *");
            $display("*                      golden_err_msg: %b  yours: %b                    *", golden_err_msg, inf.err_msg);
            $display("*                      golden_complete: %b  yours: %b                     *", golden_complete, inf.complete);
            $display("*************************************************************************");
            $finish;
        end
    end
endtask

task reset_task; 
    begin
        tot_latency = 0;

        inf.rst_n               = 1'b1; 
        inf.sel_action_valid    = 1'bx;
        inf.type_valid          = 1'bx;
        inf.size_valid  	    = 1'bx;
        inf.date_valid  	    = 1'bx;
        inf.box_no_valid        = 1'bx;
        inf.box_sup_valid       = 1'bx;
        inf.D                   =  'dx;

        #(CYCLE) inf.rst_n = 1'b0;
        #(CYCLE) inf.rst_n = 1'b1;

    // if(inf.out_valid !== 1'b0 || inf.err_msg !== No_Err || inf.complete !== 1'b0) 
    // begin
    //     $display("************************************************************");  
    //     $display("                          FAIL!                              ");    
    //     $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
    //     $display("************************************************************");
    //     $finish;
    // end

        inf.sel_action_valid    = 1'b0;
        inf.type_valid          = 1'b0;
        inf.size_valid  	    = 1'b0;
        inf.date_valid  	    = 1'b0;
        inf.box_no_valid        = 1'b0;
        inf.box_sup_valid       = 1'b0;
        inf.D           =  'dx;
        @(negedge clk);
    end 
endtask

task store_dram_task;
    begin
    case(curAction)
        Make_drink:  make_drink_store_dram_task;
        Supply:     supply_store_dram_task;
    endcase

    {golden_DRAM[(65536 + box_id*8 + 7)], golden_DRAM[(65536 + box_id*8 + 6)][7:4]} = init_Bev.black_tea;
    {golden_DRAM[(65536 + box_id*8 + 6)][3:0], golden_DRAM[(65536 + box_id*8 + 5)]} = init_Bev.green_tea;
    {golden_DRAM[(65536 + box_id*8 + 4)][3:0]}                                      = init_Bev.M;
    {golden_DRAM[(65536 + box_id*8 + 3)], golden_DRAM[(65536 + box_id*8 + 2)][7:4]} = init_Bev.milk;
    {golden_DRAM[(65536 + box_id*8 + 2)][3:0], golden_DRAM[(65536 + box_id*8 + 1)]} = init_Bev.pineapple_juice;
    {golden_DRAM[(65536 + box_id*8 + 0)][4:0]}                                      = init_Bev.D;
    end
endtask


task make_drink_store_dram_task; begin
    if(golden_err_msg === No_Err) begin
        case(make_order.Bev_Type_O)
            Black_Tea: begin
                init_Bev.black_tea = init_Bev.black_tea - beverage_vol;
            end
            Milk_Tea: begin
                init_Bev.black_tea = init_Bev.black_tea - 3*beverage_vol/4;
                init_Bev.milk = init_Bev.milk - beverage_vol/4;
            end
            Extra_Milk_Tea: begin
                init_Bev.black_tea = init_Bev.black_tea - beverage_vol/2;
                init_Bev.milk = init_Bev.milk - beverage_vol/2;
            end
            Green_Tea: begin
                init_Bev.green_tea = init_Bev.green_tea - beverage_vol;
            end
            Green_Milk_Tea: begin
                init_Bev.green_tea = init_Bev.green_tea - beverage_vol/2;
                init_Bev.milk = init_Bev.milk - beverage_vol/2;
            end
            Pineapple_Juice: begin
                init_Bev.pineapple_juice = init_Bev.pineapple_juice - beverage_vol;
            end
            Super_Pineapple_Tea: begin
                init_Bev.black_tea = init_Bev.black_tea - beverage_vol/2;
                init_Bev.pineapple_juice = init_Bev.pineapple_juice - beverage_vol/2;
            end
            Super_Pineapple_Milk_Tea: begin
                init_Bev.black_tea = init_Bev.black_tea - beverage_vol/2;
                init_Bev.milk = init_Bev.milk - beverage_vol/4;
                init_Bev.pineapple_juice = init_Bev.pineapple_juice - beverage_vol/4;
            end
        endcase
    end
end
endtask

task supply_store_dram_task;
    begin
        init_Bev.black_tea = (Black_Tea_tot_Vol[12]) ? 4095 : Black_Tea_tot_Vol[11:0];
        init_Bev.green_tea = (Green_Tea_tot_Vol[12]) ? 4095 : Green_Tea_tot_Vol[11:0];
        init_Bev.milk = (Milk_tot_Vol[12]) ? 4095 : Milk_tot_Vol[11:0];
        init_Bev.pineapple_juice = (Pineapple_Juice_tot_Vol[12]) ? 4095 : Pineapple_Juice_tot_Vol[11:0];
        init_Bev.M = input_date.M;
        init_Bev.D = input_date.D;
    end
endtask

task action_sel_task;
    begin
        case(curAction)
            Make_drink: make_drink_task;
            Supply: supply_task;
            Check_Valid_Date: check_valid_date_task;
        endcase
    end
endtask

task get_dram_task;
    begin
        init_Bev.black_tea = {golden_DRAM[(65536+box_id*8+7)],golden_DRAM[(65536+box_id*8+6)][7:4]};
        init_Bev.green_tea = {golden_DRAM[(65536+box_id*8+6)][3:0],golden_DRAM[(65536+box_id*8+5)]};
        init_Bev.M = golden_DRAM[(65536+box_id*8+4)];
        init_Bev.milk = {golden_DRAM[(65536+box_id*8+3)],golden_DRAM[(65536+box_id*8+2)][7:4]};
        init_Bev.pineapple_juice = {golden_DRAM[(65536+box_id*8+2)][3:0],golden_DRAM[(65536+box_id*8+1)]};
        init_Bev.D = golden_DRAM[(65536+box_id*8)];
    end
endtask

task make_drink_task;
    begin
        random_order_task;
        random_date_task;
        make_drink_input_task;
    end
endtask


task supply_task;
    begin
        random_date_task;
        random_supply_task;
        supply_input_task;
    end
endtask

task check_valid_date_task;
    begin
        random_date_task;
        check_valid_date_input_task;
    end
endtask

task check_valid_date_check_ans_task;
    begin
        if((input_date.M > init_Bev.M) || (input_date.M === init_Bev.M && input_date.D > init_Bev.D))
        begin
            golden_err_msg = No_Exp;
        end

        else
        begin
            golden_err_msg = No_Err;
        end
    end
endtask

task supply_check_ans_task;
    begin
        Black_Tea_tot_Vol = init_Bev.black_tea + black_tea_supply_vol;
        Green_Tea_tot_Vol = init_Bev.green_tea + green_tea_supply_vol;
        Milk_tot_Vol = init_Bev.milk + milk_supply_vol;
        Pineapple_Juice_tot_Vol = init_Bev.pineapple_juice + pineapple_juice_supply_vol;
    end

    if(Black_Tea_tot_Vol > 4095  || Green_Tea_tot_Vol > 4095 || Milk_tot_Vol > 4095 || Pineapple_Juice_tot_Vol > 4095)
    begin
        golden_err_msg = Ing_OF;
    end
    else
    begin
        golden_err_msg = No_Err;
    end

endtask

task make_drink_check_ans_task;
    begin
        case(make_order.Bev_Size_O)
            L: beverage_vol = 960;
            M: beverage_vol = 720;
            S: beverage_vol = 480;
        endcase

    Black_Tea_enough = (make_order.Bev_Type_O === Green_Milk_Tea) || (make_order.Bev_Type_O === Green_Tea) || (make_order.Bev_Type_O === Pineapple_Juice) || 
                        (make_order.Bev_Type_O === Black_Tea && init_Bev.black_tea >= beverage_vol) || (make_order.Bev_Type_O === Milk_Tea && init_Bev.black_tea >= 3*beverage_vol/4) ||
                        (make_order.Bev_Type_O === Extra_Milk_Tea && init_Bev.black_tea >= beverage_vol/2) || (make_order.Bev_Type_O === Super_Pineapple_Tea && init_Bev.black_tea >= beverage_vol/2) ||
                        (make_order.Bev_Type_O === Super_Pineapple_Milk_Tea && init_Bev.black_tea >= beverage_vol/2);

    Green_tea_enough = (make_order.Bev_Type_O === Black_Tea) || (make_order.Bev_Type_O === Milk_Tea) || (make_order.Bev_Type_O === Extra_Milk_Tea) || (make_order.Bev_Type_O === Green_Tea && init_Bev.green_tea >= beverage_vol) ||
                        (make_order.Bev_Type_O === Green_Milk_Tea && init_Bev.green_tea >= beverage_vol/2) || (make_order.Bev_Type_O === Pineapple_Juice)||
                        (make_order.Bev_Type_O === Super_Pineapple_Tea) || (make_order.Bev_Type_O === Super_Pineapple_Milk_Tea);

    Milk_enough = (make_order.Bev_Type_O === Black_Tea) || (make_order.Bev_Type_O === Milk_Tea && init_Bev.milk >= beverage_vol/4) || (make_order.Bev_Type_O === Extra_Milk_Tea && init_Bev.milk >= beverage_vol/2) ||
                    (make_order.Bev_Type_O === Green_Tea) || (make_order.Bev_Type_O === Green_Milk_Tea && init_Bev.milk >= beverage_vol/2) || (make_order.Bev_Type_O === Pineapple_Juice) ||
                    (make_order.Bev_Type_O === Super_Pineapple_Tea) || (make_order.Bev_Type_O === Super_Pineapple_Milk_Tea && init_Bev.milk >= beverage_vol/4);

    Pineapple_Juice_enough = (make_order.Bev_Type_O === Black_Tea) || (make_order.Bev_Type_O === Milk_Tea) || (make_order.Bev_Type_O === Extra_Milk_Tea) || (make_order.Bev_Type_O === Green_Tea) ||
                                (make_order.Bev_Type_O === Green_Milk_Tea) || (make_order.Bev_Type_O === Pineapple_Juice && init_Bev.pineapple_juice >= beverage_vol) ||
                                (make_order.Bev_Type_O === Super_Pineapple_Tea && init_Bev.pineapple_juice >= beverage_vol/2) || (make_order.Bev_Type_O === Super_Pineapple_Milk_Tea && init_Bev.pineapple_juice >= beverage_vol/4);

    if((input_date.M > init_Bev.M) || (input_date.M === init_Bev.M && input_date.D > init_Bev.D))
    begin
        golden_err_msg = No_Exp;
    end  
    else if((!Black_Tea_enough || !Green_tea_enough || !Milk_enough || !Pineapple_Juice_enough))
    begin
        golden_err_msg = No_Ing;
    end
    else
    begin
        golden_err_msg = No_Err;
    end
    end
endtask

task wait_outvalid_task; 
    begin
        latency = 0;
        while ( inf.out_valid !== 1 ) 
        begin
            latency = latency + 1;
            // if(latency === 1000)
            // begin
            //     $display("********************************************************");     
            //     $display("                          FAIL!                              ");
            //     $display("*  The execution latency are over 1000 cycles  at %8t   *",$time);
            //     $display("********************************************************");
            //     $finish;
            // end
            @(negedge clk);
        end
    end 
endtask

task check_valid_date_input_task;
    begin
        gap = $urandom_range(1,4);
	    repeat(gap) @(negedge clk);
        inf.sel_action_valid = 1;
        inf.D.d_act[0] = curAction;
        @(negedge clk);
        inf.sel_action_valid = 0;
        inf.D.d_act[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.date_valid = 1;
        inf.D.d_date[0] = input_date;
        @(negedge clk);
        inf.date_valid = 0;  
        inf.D.d_date[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.box_no_valid = 1;
        inf.D.d_box_no[0] = box_id;
        @(negedge clk);
        inf.box_no_valid = 0;  
        inf.D.d_box_no[0] = 'dx;
    end
endtask

task make_drink_input_task;
    begin
        gap = $urandom_range(1,4);
	    repeat(gap) @(negedge clk);
        inf.sel_action_valid = 1;
        inf.D.d_act[0] = curAction;
        @(negedge clk);
        inf.sel_action_valid = 0;
        inf.D.d_act[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.type_valid = 1;
        inf.D.d_type[0] = make_order.Bev_Type_O;
        @(negedge clk);
        inf.type_valid = 0;
        inf.D.d_type[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.size_valid = 1;
        inf.D.d_size[0] = make_order.Bev_Size_O;
        @(negedge clk);
        inf.size_valid = 0; 
        inf.D.d_size[0] = 'dx;   

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.date_valid = 1;
        inf.D.d_date[0] = input_date;
        @(negedge clk);
        inf.date_valid = 0;  
        inf.D.d_date[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.box_no_valid = 1;
        inf.D.d_box_no[0] = box_id;
        @(negedge clk);
        inf.box_no_valid = 0;  
        inf.D.d_box_no[0] = 'dx;
    end
endtask

task supply_input_task;
    begin
        gap = $urandom_range(1,4);
	    repeat(gap) @(negedge clk);
        inf.sel_action_valid = 1;
        inf.D.d_act[0] = curAction;
        @(negedge clk);
        inf.sel_action_valid = 0;
        inf.D.d_act[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.date_valid = 1;
        inf.D.d_date[0] = input_date;
        @(negedge clk);
        inf.date_valid = 0;  
        inf.D.d_date[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.box_no_valid = 1;
        inf.D.d_box_no[0] = box_id;
        @(negedge clk);
        inf.box_no_valid = 0;  
        inf.D.d_box_no[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.box_sup_valid = 1;
        inf.D.d_ing[0] = black_tea_supply_vol;
        @(negedge clk);
        inf.box_sup_valid = 0;  
        inf.D.d_ing[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.box_sup_valid = 1;
        inf.D.d_ing[0] = green_tea_supply_vol;
        @(negedge clk);
        inf.box_sup_valid = 0;  
        inf.D.d_ing[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.box_sup_valid = 1;
        inf.D.d_ing[0] = milk_supply_vol;
        @(negedge clk);
        inf.box_sup_valid = 0;  
        inf.D.d_ing[0] = 'dx;

        gap = $urandom_range(0,3);
	    repeat(gap) @(negedge clk);
        inf.box_sup_valid = 1;
        inf.D.d_ing[0] = pineapple_juice_supply_vol;
        @(negedge clk);
        inf.box_sup_valid = 0;  
        inf.D.d_ing[0] = 'dx;
    end
endtask
task random_box_id_task;
    begin
        random_barrel.randomize();
        box_id = random_barrel.box_id;
    end
endtask

task random_act_task;
    begin
        random_action.randomize();
        curAction = random_action.act_id;
    end
endtask

task random_date_task;
    begin
        random_Date.randomize();
        // input_date.M = random_Date.date_id.M;
        // input_date.D = random_Date.date_id.D;
        input_date = random_Date.date_id;
    end
endtask

task random_order_task;
    begin
        random_bevOrder.randomize();
        // make_order.Bev_Type_O = random_bevOrder.order_id.Bev_Type_O;
        // make_order.Bev_Size_O = random_bevOrder.order_id,Bev_Size_O;
        make_order = random_bevOrder.order_id;
    end
endtask

task random_supply_task;
    begin
        random_Supply.randomize();
        black_tea_supply_vol = random_Supply.black_tea_supply_vol;
        green_tea_supply_vol = random_Supply.green_tea_supply_vol;
        milk_supply_vol = random_Supply.milk_supply_vol;
        pineapple_juice_supply_vol = random_Supply.pineapple_juice_supply_vol;
    end
endtask

endprogram
