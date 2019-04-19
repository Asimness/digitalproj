/* Asim Anis
   Maisha Choudhury
   Marcus Nuyda
   Chris Huynh
   CS4341.002
   
   16 bit ALU
*/

module Clock(clock);					
output reg clock;
	initial							
		begin
			clock = 0;					
		end
		
	always							
		begin
			#5 clock = ~clock;			
		end
		
endmodule


module ALU16bit(x,y,op,out,rst);
	input [15:0] x;									// 2 16 bit inputs x,y 
	input [15:0] y;
	input [2:0] op;									// 3 bit op code input (only 1 select bit for this 2x1 MUX)
	
	output reg [16:0] out;							// 17 bit output (17th bit for negative numbers)
	output reg rst;									// 1 bit error flag for overflow/underflow for add/sub

	
	wire[16:0] math1;								// 17 bit wire connecting to the mathOP module/MUX output
	wire [16:0] logic1;								// 17 bit wire connecting to the logicOP module/MUX output
	wire s2 = op[2];								// 1 bit select input
	wire [1:0] s1s0 = op[1:0];						// 2 bit select input for the mathOP and logicOP modules/MUX
	
	mathOP mathOP1(x,y,s1s0,math1);					// Instances of mathOP and logicOP modules (4x2 MUX)
	logicOP logicOP1(x,y,s1s0,logic1);

	always @(*)
	begin 
		rst=1'b0;									// Default no error, set rst flag to 0
		
		if (s2 == 0)								// Select input for math function (add, sub, shift left, shift right)
			begin
				out=math1;							// Set output to mathOP module/MUX output wire
				
				// ERROR check for overflow from addition
				if (s1s0 == 2'b00)
					begin
						if (out >= 17'b01111111111111111)
							begin
								out=17'b00000000000000000;
								rst=1'b1; // Set error flag
							end
					end
				// ERROR check for underflow from subtraction
				if (s1s0 == 2'b01)
					begin
						if (out >= 17'b01111111111111111)		// Check inverse for overflow (underflow when negated)
							begin
								out=17'b00000000000000000;
								rst=1'b1; // Set error flag
							end
						// If negative, invert output to get negative number	
						else if (y>x)
							out=~(out);
					end
			end
		else										// Select input for logic function (AND, OR, XOR, NOT)
			begin
				out=logic1; 						// Set output to logic module/MUX output wire
			end
	end
endmodule

// Math functions module 4x2 MUX for addition, subtraction, shift left, shift right	
module mathOP(x,y,s1s0,out);
	input[15:0] x;									// 2 16 bit inputs x,y
	input[15:0] y;
	input[1:0] s1s0;								// 2 bit op code input / select
	output reg [16:0] out;							// 17 bit output (17th bit for negative numbers)
	    
    always @(*)
	begin
		case(s1s0)									// Get operation from 2 bit select op code
		2'b00:   									// Addition
			out=(x+y);
        2'b01: 										// Subtraction
			begin
				if (y>x)							// Negative output subtraction
					out=((~x)+y);
				else								// Regular subtraction
					out=(x-y);	
			end
       	2'b10:            							// Shift left
           	out=(x<<1);  
       	2'b11:            							// Shift right
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
		case(s1s0)									// Get operation from 2 bit select op code
		2'b00:            							// AND 
           	out=(x&y);	
       	2'b01:            							// OR
			out=(x|y);
        2'b10:            							// XOR
          	out=(x^y);
       	2'b11:
			begin									// NOT
				out=(~x);
				out[16]=1'b0;						// Do not invert the 17th bit, only for negative numbers
			end
		endcase
	end
endmodule




//module to save the output value
module accumulatorA(in, acc, reset);
	input [16:0] in;
	input  reset;
	output [16:0] acc;
	reg [16:0] acc;
	always@(*) begin
		if(reset)
			acc <= 8'b00000000;
		else
			acc <= in;
	end
endmodule

//module to save the output value
module accumulatorB(clk, rst, state);
	input clk, rst;
	output state;
	reg state;
	always@(clk) begin
		if(rst)
			state = 1'b1;
		else
			state = 1'b0;
	end
endmodule


module testbench1;

    reg[15:0] x, y;									// 2 16 bit inputs x,y
	reg[15:0] x1,y1;
    reg[2:0] op;       								// 3 bit op code (4th bit for while loop comparison)

	reg[7*8:0] str;
	reg[7*8:0] str2;
	reg[5*8:0] opr;
	reg start;
	
    wire signed [16:0] out;   						// Signed 17 bit output (for possible negative numbers after subtraction)
	wire rst;
	wire prev;
	wire next; //prevReset
	
	wire clock;
	
	Clock c0(clock);
	
    ALU16bit test1(x,y,op[2:0],out,rst);			// Instance of 16 bit ALU 2x1 MUX
	accumulatorB currentState(clock, rst, next);
	
	
	initial begin
	//cases for each trial
    forever
      begin
		//open ALU to op
		//set A and B
		
		//set op to add
		#10 x = 16'h0001; y = 16'hFFFF; op = 3'b0;opr="Add";str2="Running";start=1;
		#10 op=op+3'b001;opr="Sub";
		#10 op=op+3'b001;opr="Left";
		#10 op=op+3'b001;opr="Right";
		#10 op=op+3'b001;opr="AND";
		#10 op=op+3'b001;opr="OR";
		#10 op=op+3'b001;opr="XOR";
		#10 op=op+3'b001;opr="NOT";
		#10 x = 16'h00E1; y = 16'h0B01; op = 3'b0;str="Running";opr="Add";start=1; $display("");
		#10 op=op+3'b001;opr="Sub";
		#10 op=op+3'b001;opr="Left";
		#10 op=op+3'b001;opr="Right";
		#10 op=op+3'b001;opr="AND";
		#10 op=op+3'b001;opr="OR";
		#10 op=op+3'b001;opr="XOR";
		#10 op=op+3'b001;opr="NOT";
		
		/*
		#10 x = 16'h0001; y = 16'h0001; op = 3'b0;
		#10 op=op+3'b001;
		#10 op=op+3'b001;
		#10 op=op+3'b001;
		#10 op=op+3'b001;
		#10 op=op+3'b001;
		#10 op=op+3'b001;
		#10 op=op+3'b001;
		*/
		
		/*
		//set op to subtract
		#5 s=1;
		//set values of A and B
		#5 a= 8; b=5; 
		//set op to shift A left
		#5 s=2;
		//set op to shift A Right
		#5 s=3;
		//set op to AND A and B
		#5 s=4;
		//set op to OR A and B
		#5 s=5;
		//set op to XOR A and B
		#5 s=6;
		//set op to NOT A
		#5 s=7;
		#5 r=1;
		*/
	
      end
    end
	
	
	 //Display Forever
	initial begin
		//display variable names
		#1 $display("16-Bit ALU");                        // Header to display functions
        $display("Math Functions");
        $display("0000 x + y Add");
        $display("0001 x - y Sub");
        $display("0010 x << 1 Shift Left");
        $display("0011 x >> 1 Shift Right");
        $display("Logic Functions");
        $display("0100 x & y AND");
        $display("0101 x | y OR");
        $display("0110 x ^ y XOR");
        $display("0111 ~x NOT\n");

                                                    // Labels
        #5 $display("Num 1                    Num 2                    Operation    Current Output                     Next State ");

		//$display("%b    |%b    |%b(%d)|%b(%d)|%b(%d)   |%b(%d),%b        ",clock,rst,x,x,y,y,op,op,out,out,next);
		forever
		begin
		//display output
		//#5		$display("%b    |%b    |%b(%d)|%b(%d)|%b(%d)   |%b(%d),%b        ",clock,rst,x,x,y,y,op,op,out,out,next);
			#5  if (next && start == 0)
					str = "ERROR";
				else
					begin
						str = "Running";
						start = 0;
					end
				if (rst)
					str2 = "ERROR";
				else
					str2 = "Running";
			$display("%b", x, " (", "%d", x, ") ", "%b", y, " (", "%d", y, ") ", "%b",(op)," (%s)", opr,"%s", str," %b",out," (%d)",out, "%s", str2);
			//$display("     |     |                       |                       |         |                        | ");
		

		end	
		
	end


	///Shutoff
	initial begin
		#170
		$finish;
	end  
	
endmodule

