/* Asim Anis
   Maisha Choudhury
   Marcus Nuyda
   Chris Huynh
   CS4341.002
   
   16 bit ALU
*/

// 2x1 MUX selecting math or logic function output based on op code MSB
module functionSelector(x,y,op,out,err);
	input [15:0] x;									// 2 16 bit inputs x,y 
	input [15:0] y;
	input [2:0] op;									// 3 bit op code input (only 1 select bit for this 2x1 MUX)
	
	
	output reg [16:0] out;							// 17 bit output (17th bit for negative numbers)
	output wire err;								// 1 bit error flag for overflow on add

	
	wire[16:0] math1;								// 17 bit wire connecting to the mathOP module/MUX output
	wire [16:0] logic1;								// 17 bit wire connecting to the logicOP module/MUX output
	wire s2 = op[2];								// 1 bit select input
	wire [1:0] s1s0 = op[1:0];						// 2 bit select input for the mathOP and logicOP modules/MUX
	
	mathOP mathOP1(x,y,s1s0,math1,err);				// Instances of mathOP and logicOP modules (4x2 MUX)
	logicOP logicOP1(x,y,s1s0,logic1);

	always @(*)
	begin 											// 2x1 MUX choosing math or logic functions based on s2 op code selector bit
		if (s2 == 0)								// Select input for math function (add, sub, shift left, shift right)
			out=math1;								// Set output to mathOP module/MUX output wire
		else										// Select input for logic function (AND, OR, XOR, NOT)
			begin
				out=logic1; 						// Set output to logic module/MUX output wire
			end

	end
endmodule

// Math functions module with 4x2 MUX for addition, subtraction, shift left, shift right	
module mathOP(x,y,s1s0,out,err);
	input[15:0] x;									// 2 16 bit inputs x,y
	input[15:0] y;
	input[1:0] s1s0;								// 2 bit op code input / select
	output reg [16:0] out;							// 17 bit output (17th bit for negative numbers)
	output reg err;									// Error bit
	    
    always @(*)
	begin
		err=1'b0;									// Default no error, set err flag to 0
													
													// 4x2 MUX selecting function based on s1s0 op code 
		case(s1s0)									// Get operation from 2 bit select op code
		2'b00:   									// Addition
			begin
				out=(x+y);
				// ERROR check for overflow from addition
				if (out[16] == 1'b1)
					begin
						//out=17'b00000000000000000;
						err=1'b1; // Set error flag
					end
			end
        2'b01: 										// Subtraction
			out=(x-y);	
       	2'b10:            							// Shift left x
           	out=(x<<1);  
       	2'b11:            							// Shift right x
           	out=(x>>1); 				
		endcase
		
	end
endmodule


// Logic functions module 4x2 MUX for AND, OR, XOR, NOT
module logicOP(x,y,s1s0,out);
	input[15:0] x;									// 2 16 bit inputs x,y
	input[15:0] y;
	input[1:0] s1s0;								// 2 bit op code input / select
	output reg[16:0] out;							// 17 bit output 
	   
    always @(*)
	begin
													// 4x2 MUX selecting function based on s1s0 op code 
		case(s1s0)									// Get operation from 2 bit select op code
		2'b00:            							// AND 
           	out=(x&y);	
       	2'b01:            							// OR
			out=(x|y);
        2'b10:            							// XOR
          	out=(x^y);
       	2'b11:
			begin									// NOT x
				out=(~x);
				out[16]=1'b0;						// Do not invert the 17th bit, only for negative numbers
			end
		endcase
	end
endmodule

// Clock module used for accumulator module
module Clock(clock);					
	output reg clock;
	initial							
		begin
			clock = 0;					
		end		
	always							
		begin
			#5 clock = ~clock;			// Invert every 5 units	
		end
endmodule

// Accumulator for output current state
module accumulator(clk, err, state);
	input clk, err;
	output state;
	reg state;
	always@(clk) begin
		if(err)
			state = 1'b1;
		else
			state = 1'b0;
	end
endmodule

// Reset module for CLEAR result operation 
module reset(clear,out,result);
	input clear;
	input[16:0] out;
	output reg [16:0] result;
	always@(*)
	begin
		if(clear)							// Clear result
			result=17'b00000000000000000;
		else
			result=out;						// Keep result
	end

endmodule


module testbench1;

    reg[15:0] x, y;									// 2 16 bit inputs x,y
	reg[15:0] x1,y1;
    reg[2:0] op;       								// 3 bit op code (4th bit for while loop comparison)

	reg[7*8:0] str;									// String registers for state strings
	reg[7*8:0] str2;
	reg[5*8:0] opr;									// String register for op code string
	reg start;										// Start flag
	reg clear;										// Clear flag for CLEAR operation
	
    wire signed [16:0] out;   						// Signed 17 bit output (for possible negative numbers after subtraction)
	wire err;										// ERROR bit
	wire next;										// Next state bit
	wire clock;					
	wire signed [16:0] result;						// 17 bit result output (17th bit for sign for negatives)
	
	Clock c0(clock);										// Initialize clock
    functionSelector funcSe1(x,y,op[2:0],out,err);			// Instance of 16 bit ALU 2x1 MUX and accumulator
	accumulator currentState(clock, err, next);
	reset reset1(clear,out,result);							// Reset 2x1 MUX
	
	initial begin
															// Iterate through 10 operations
    forever
      begin
															// Test case 1 values
		#10 x = 16'h0001; y = 16'hFFFF; op = 3'b0;opr="Add";str2="Running";start=1;
		#10 op=op+3'b001;opr="Sub";
		#10 op=op+3'b001;opr="Left";
		#10 op=op+3'b001;opr="Right";
		#10 op=op+3'b001;opr="AND";
		#10 op=op+3'b001;opr="OR";
		#10 op=op+3'b001;opr="XOR";
		#10 op=op+3'b001;opr="NOT";
		#10 clear=1;opr="CLEAR";
															// Test case 2 values
		#10 x = 16'h00E1; y = 16'h0B01; op = 3'b0;str="Running";opr="Add";start=1; $display("");clear=0;
		#10 op=op+3'b001;opr="Sub";
		#10 op=op+3'b001;opr="Left";
		#10 op=op+3'b001;opr="Right";
		#10 op=op+3'b001;opr="AND";
		#10 op=op+3'b001;opr="OR";
		#10 op=op+3'b001;opr="XOR";
		#10 op=op+3'b001;opr="NOT";
		#10 clear=1;opr="CLEAR";
		
	
      end
    end
	
	
	initial begin
		#1 $display("16-Bit ALU");                        	// Header to display functions
        $display("Math Functions");
        $display("000 x + y Add");
        $display("001 x - y Sub");
        $display("010 x << 1 Shift Left");
        $display("011 x >> 1 Shift Right\n");
        $display("Logic Functions");
        $display("100 x & y AND");
        $display("101 x | y OR");
        $display("110 x ^ y XOR");
        $display("111 ~x NOT\n");
		
		$display("(CLEAR)");
		$display("ERROR (Addition overflow)\n");
		

															// Labels
        #5 $display("Num 1                    Num 2                    Operation    Current Output                     Next State Clock");
		forever
		begin
		
			#5  if (next && start == 0 && (op ==3'b000 || op == 3'b001)) // Current state
					str = "ERROR";
				else
					begin
						str = "Running";
						start = 0;
					end
				if (err && op==3'b000)									// Next State
					str2 = "ERROR";
				else
					str2 = "Running";
			if (str2=="ERROR")
				$display("%b", x, " (", "%d", x, ") ", "%b", y, " (", "%d", y, ") ", "%b",(op)," (%s)", opr,"%s", str," XXXXXXXXXXXXXXXXX (   Nan)",  "%s", str2, "    %b",clock);
			else
				$display("%b", x, " (", "%d", x, ") ", "%b", y, " (", "%d", y, ") ", "%b",(op)," (%s)", opr,"%s", str," %b",result," (%d)",result, "%s", str2, "    %b",clock);

		end	
		
	end


	// Finish
	initial begin
		#190
		$finish;
	end  
	
endmodule

