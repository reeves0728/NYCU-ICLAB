module bridge(input clk, INF.bridge_inf inf);

logic [11:0] Black_Tea_R, Green_Tea_R, Milk_R, Pineapple_Juice_R;
logic [7:0] Expired_month_R, Expired_Day_R;

//================================================================
// READ 
//================================================================

assign Black_Tea_R = {inf.R_DATA[51:48] , inf.R_DATA[63:56]};
assign Green_Tea_R = {inf.R_DATA[47:40], inf.R_DATA[55:52]};
assign Expired_month_R = {4'b0000, inf.R_DATA[35:32]};
assign Milk_R = {inf.R_DATA[19:16],inf.R_DATA[31:24]};
assign Pineapple_Juice_R = {inf.R_DATA[15:8],inf.R_DATA[23:20]};
assign Expired_Day_R = {3'b000, inf.R_DATA[4:0]};

//  AR_ADDR
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
    begin
		inf.AR_ADDR	<=	0;
	end 

    else
    begin
        if(inf.C_in_valid)
        begin
		    inf.AR_ADDR	<=	{1'd1,5'd0,inf.C_addr,3'd0};
        end
	end
end

// AR_VALID
always_ff@(posedge clk , negedge inf.rst_n)begin
	if (!inf.rst_n)
    begin
		inf.AR_VALID <= 0 ; 
	end 

    else 
    begin
        if (inf.AR_READY && inf.AR_VALID)
        begin
		    inf.AR_VALID <= 0 ; 
	    end 
        else if (inf.C_in_valid && inf.C_r_wb == 1)
        begin
		    inf.AR_VALID <= 1 ; 
	    end
    end
end

// R_READY
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
    begin
		inf.R_READY	<=	0;
	end 

    else
    begin
        if(inf.AR_READY)
        begin
            inf.R_READY	<=	1;
        end 
        else if(inf.R_VALID)
        begin
            inf.R_READY	<=	0;
        end
    end
end

// inf.C_data_r
always_ff@(posedge clk , negedge inf.rst_n)begin
	if (!inf.rst_n)
    begin
		inf.C_data_r <= 0 ;
	end 
    
    else
    begin
        if (inf.R_VALID)
        begin
            // inf.C_data_r <= {Black_Tea_R, Green_Tea_R, Expired_month_R, Milk_R, Pineapple_Juice_R, Expired_Day_R} ;
            inf.C_data_r <= inf.R_DATA;
        end
    end
end

//================================================================
// WRITE
//================================================================

logic [11:0] Black_Tea_W, Green_Tea_W, Milk_W, Pineapple_Juice_W;
logic [7:0] Expired_month_W, Expired_Day_W;

assign Black_Tea_W = inf.C_data_w[63:52];
assign Green_Tea_W = inf.C_data_w[51:40];
assign Expired_month_W = inf.C_data_w[39:32];
assign Milk_W = inf.C_data_w[31:20];
assign Pineapple_Juice_W = inf.C_data_w[19:8];
assign Expired_Day_W = inf.C_data_w[7:0];

// AW_VALID
always_ff@(posedge clk , negedge inf.rst_n)begin
	if (!inf.rst_n)
    begin
		inf.AW_VALID <= 0 ; 
	end 

    else
    begin
        if(inf.AW_READY && inf.AW_VALID)
        begin
		    inf.AW_VALID <= 0 ; 
        end
        else if (inf.C_in_valid && inf.C_r_wb == 0)
        begin
		    inf.AW_VALID <= 1 ; 
	    end
	end
end

// AW_ADDR
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
    begin
		inf.AW_ADDR	<=	0;
	end 
    
    else
    begin
		if(inf.C_in_valid)
        begin
            inf.AW_ADDR	<=	{1'd1,5'd0,inf.C_addr,3'd0};
        end
	end
end	

// W_VALID
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
    begin
		inf.W_VALID	<=	0;
	end 
    
    else
    begin
        if(inf.AW_READY)
        begin
            inf.W_VALID	<=	1;
        end 
        else if(inf.W_READY)
        begin
            inf.W_VALID	<=	0;
        end
    end
end

// B_READY
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
    begin
		inf.B_READY	<=	0;
	end 
    
    else
    begin
        if(inf.AW_READY)
        begin
            inf.B_READY	<=	1;
        end 
        else if(inf.B_VALID)
        begin
            inf.B_READY	<=	0;
        end
    end
end

// W_DATA
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
    begin
		inf.W_DATA	<=	0;
	end 

    else
    begin
        if(inf.C_in_valid && inf.C_r_wb == 0)
        begin
            // inf.W_DATA	<=	{Black_Tea_W[7:0], Green_Tea_W[3:0], Black_Tea_W[11:8], Green_Tea_W[11:4], Expired_month_W, 
            //                Milk_W[7:0], Pineapple_Juice_W[3:0], Milk_W[11:8], Pineapple_Juice_W[11:4], Expired_Day_W};
            inf.W_DATA <= inf.C_data_w;
        end 
    end
end


//================================================================
// OUTPUT
//================================================================

// C_out_valid
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
    begin
		inf.C_out_valid <=  0;
	end 
    
    else
    begin
        if(inf.R_VALID) 
        begin
            inf.C_out_valid	<=	1;
	    end 
        else if(inf.B_VALID) 
        begin
            inf.C_out_valid	<=	1;
        end 
        else 
        begin
            inf.C_out_valid	<=	0;
        end
    end
end
endmodule