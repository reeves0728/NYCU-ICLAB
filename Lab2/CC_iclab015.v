module CC(
    //Input Port
    clk,
    rst_n,
	in_valid,
	mode,
    xi,
    yi,

    //Output Port
    out_valid,
	xo,
	yo
    );

input               clk, rst_n, in_valid;
input       [1:0]   mode;
input       signed [7:0]   xi, yi;  

output reg          out_valid;
output reg  signed [7:0]   xo, yo;

reg signed [7:0] x[0:3];
reg signed [7:0] y[0:3];
reg  signed [7:0]  temp_y;

reg signed [23:0] x_coeff[0:1]; // 0: left boundary line's x coefficient, 1: right boundary line's x coefficient
reg signed [23:0] y_coeff[0:1]; // 0: left boundary line's y coefficient, 1: right boundary line's y coefficient
reg signed [23:0] cons[0:1]; // 0: left boundary line's constant, 1: right boundary line's constant

reg signed [23:0] x_setup_0[0:2];
reg signed [23:0] x_setup_1[0:2];
reg signed [23:0] x_check_1[0:2];
reg signed [23:0] x_check_0[0:2];


reg signed [23:0] x_coeff_1; 
reg signed [23:0] y_coeff_1; 
reg signed [23:0] cons_1;
reg signed [29:0] line; 
reg signed [29:0] radius;
reg signed [16:0] area;
reg signed [16:0] area_abs;
reg signed [15:0] area_d2;
reg [1:0] relation;
reg [1:0] mode_reg;


reg [2:0] current_state;
reg [2:0] next_state;

reg [1:0] in_counter;
integer i;

reg signed [7:0] x_new[0:1];
reg signed [7:0] right_bound;

reg test;

parameter RESET = 3'd0;
parameter INPUT = 3'd1;
parameter MODE0 = 3'd2;
parameter MODE1 = 3'd3;
parameter MODE2 = 3'd4;
parameter OUTPUT = 3'd5;
parameter OUTPUT_1 = 3'd6;
parameter OUTPUT_2 = 3'd7;


always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i = 0; i < 4; i = i + 1)
        begin
            x[i] <= 0;
            y[i] <= 0;
        end        
    end

    else
    begin
        if(in_valid)
        begin
            mode_reg <= mode;
            x[in_counter] <= xi;
            y[in_counter] <= yi;                    
        end
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        in_counter <= 0;
    end

    else
    begin
        if(in_valid)
        begin
            if(in_counter == 3)
            begin
                in_counter <= 0;
            end

            else
            begin
                in_counter <= in_counter + 1;
            end
        end


    end
end

always @ (*)
begin
    case(current_state)
        RESET:
        begin
            if(in_valid == 1'b1)
            begin
                next_state = INPUT;
            end

            else
            begin
                next_state = RESET;
            end
        end

        INPUT:
        begin
            if(in_counter == 3) 
            begin
                if(mode_reg == 2'd0)
                begin
                    next_state = MODE0;
                end

                else if(mode_reg == 2'd1)
                begin
                    next_state = MODE1;
                end

                else 
                begin
                    next_state = MODE2;
                end
            end

            else 
            begin
                next_state = INPUT;
            end
        end

        MODE0:
        begin
            next_state = OUTPUT;
        end

        MODE1:
        begin
            next_state = OUTPUT_1;            
        end

        MODE2:
        begin
            next_state = OUTPUT_2;
        end

        OUTPUT:
        begin
            if(out_valid == 0)
            begin
                next_state = RESET;                
            end

            else
            begin
                next_state = OUTPUT;
            end
        end

        OUTPUT_1:
        begin
            next_state = RESET;
        end

        OUTPUT_2:
        begin
            next_state = RESET;
        end
    endcase
end

always @ (*) begin
    x_coeff[0] = y[0] - y[2];
    y_coeff[0] = -(x[0] - x[2]);
    cons[0] = (x_coeff[0]*x[0]) + (y_coeff[0]*y[0]);

    x_setup_0[0] = (yo-y[2]+1);
    x_setup_0[1] = x_setup_0[0]*y_coeff[0];
    x_check_0[0] = (x_coeff[0]*x[2] - x_setup_0[1])/x_coeff[0]; // if 1.5 => 1, -1.5 => -1;

    //ex: 5x-2y=10 => 5 * x = 10 - (-2 * y) ===> x_check_0[2] = x_check_0[1]; this step is checking whether the line is on grid
    x_check_0[1] = cons[0] - y_coeff[0] * (yo+1);
    x_check_0[2] = x_coeff[0]*x_check_0[0];

    if(x_check_0[2] == x_check_0[1]) // the line is autually on grid
    begin
        x_new[0] = x_check_0[0];
    end

    else
    begin
        if(x_check_0[0] == 0) // this means x_setup_0[2] is a positive number, so x_check_0[0] = (0 - 0.5) ==> (0 - 0) ==> 0 will be inclued in this case
        begin
            if(x_check_0[1] >= 0)
            begin
                x_new[0] = x_check_0[0];
            end

            else
            begin
                x_new[0] = x_check_0[0] - 1;
            end
        end

        else if(x_check_0[1] > 0) // this means x_setup_0[2] is a negative number, so x_check_0[0] = (0 - (-0.5) ) ==> (0 - 0) ==> 0 will be inclued in this case
        begin 
            x_new[0] = x_check_0[0];
        end

        else
        begin
            x_new[0] = x_check_0[0] - 1;
        end
    end
end

always @ (*)
begin
    x_coeff[1] = y[1] - y[3];
    y_coeff[1] = -(x[1] - x[3]);
    cons[1] = (x_coeff[1]*x[1]) + (y_coeff[1]*y[1]);
    x_setup_1[0] = (yo-y[3]+1);
    x_setup_1[1] = x_setup_1[0]*y_coeff[1];  

    x_check_1[0] = (x_coeff[1] * x[3] - x_setup_1[1])/x_coeff[1];
    x_check_1[1] = cons[1] - y_coeff[1]* (yo+1); 
    x_check_1[2] = x_coeff[1]*x_check_1[0];

    if(x_check_1[2] == x_check_1[1]) // on grid
    begin
        x_new[1] = x_check_1[0];
    end      

    else
    begin
        if(x_check_1[0] == 0) // this means x_setup_0[2] is a positive number, so x_check_0[0] = (0 - 0.5) ==> (0 - 0) ==> 0 will be inclued in this case
        begin
            if(x_check_1[1] >= 0)
            begin
                x_new[1] = x_check_1[0];
            end

            else
            begin
                x_new[1] = x_check_1[0] - 1;
            end
        end

        else if(x_check_1[0] > 0) // this means x_setup_0[2] is a negative number, so x_check_0[0] = (0 - (-0.5) ) ==> (0 - 0) ==> 0 will be inclued in this case
        begin 
            x_new[1] = x_check_1[0];
        end

        else
        begin
            x_new[1] = x_check_1[0] - 1;
        end                   
    end
end


always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        current_state <= RESET;
    end

    else 
    begin
        current_state <= next_state;
    end
end


always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        xo <= 0;       
    end

    else
    begin

        if(current_state == MODE2)
        begin
            xo <= area_d2[15:8];
        end
        
        if(current_state == MODE1)
        begin
            xo <= 0;
        end     

        
        if(current_state == MODE0)
        begin
            xo <= x[2]; 
            right_bound <= x[3];
        end
        
        else if(xo == right_bound)
        begin
            xo <= x_new[0];
            right_bound <= x_new[1];
        end

        else if(mode_reg == 0)
        begin
            xo <= xo + 1;
        end
    end
end


always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        yo <= 0;       
    end

    else
    begin

        if(current_state == MODE2)
        begin
            yo <= area_d2[7:0];
        end
        
        
        
        if(current_state == MODE1)
        begin
            case(relation)
                2'd0: yo <= 0;
                2'd1: yo <= 1;
                2'd2: yo <= 2;
                default: yo <= 3;
            endcase
        end

                
        if(current_state == MODE0)
        begin
            yo <= y[2]; 
        end


        else if(mode_reg == 0 && xo == right_bound)
        begin
            yo <= yo+1;
        end


    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid <= 0;  
    end

    else
    begin
        if(current_state == MODE2)
        begin
            out_valid <= 1;
        end

        else if(current_state == OUTPUT_2)
        begin
            out_valid <= 0;
        end

        else if(current_state == MODE1)
        begin
            out_valid <= 1;
        end

        else if(current_state == OUTPUT_1)
        begin
            out_valid <= 0;
        end

        else if(current_state == MODE0)
        begin
            out_valid <= 1;
        end

        else if(mode_reg == 0 && yo == y[1] && xo == x[1])
        begin
            out_valid <= 0;
        end
    end
end


//==============================================//
//              Calculation Block2              //
//==============================================//
always @ (*)begin
    x_coeff_1 = y[0] - y[1];
    y_coeff_1 = -(x[0] - x[1]);
    cons_1 = (x_coeff_1*x[0]) + (y_coeff_1*y[0]);    
end


always @ (*)begin
    line =  (x_coeff_1 * x[2] + y_coeff_1* y[2] - cons_1) * (x_coeff_1 * x[2] + y_coeff_1* y[2] - cons_1) ;
    radius = ((x[2] - x[3])* (x[2]-x[3]) + (y[2]-y[3]) *(y[2] - y[3])) * ((x_coeff_1*x_coeff_1) + (y_coeff_1*y_coeff_1));

    if(line > radius)
    begin
        relation = 0;
    end

    else if(line < radius)
    begin
        relation = 1;
    end

    else
    begin
        relation = 2;
    end
end

//==============================================//
//              Calculation Block3              //
//==============================================//
always @ (*)
begin
    area = ((x[0]*y[1]) + (x[1]*y[2]) + (x[2]*y[3]) + (x[3]*y[0])) - ((y[0]*x[1])+(y[1]*x[2])+(y[2]*x[3])+(y[3]*x[0]));
    area_abs = area[16]? -area : area;
    area_d2 = area_abs / 2;
end


endmodule 