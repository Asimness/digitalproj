
module ALU16bit(x,y,op,out);
	input [16:0] x;
	input [16:0] y;
	input [2:0] op;
	output reg [16:0] out;
	wire [16:0] math1;
	wire [16:0] logic1;	
	wire s2 = op[2];
	wire [1:0] s1s0 = op[1:0];

	mathOP mathOP1(x,y,s1s0,math1);
	logicOP logicOP1(x,y,s1s0,logic1);

	always @(*)
	begin 
		if (s2 == 0)
			out=math1;
		else
			out=logic1; 
			
	end
endmodule
	
module mathOP(x,y,s1s0,out);
	input[16:0] x;
	input[16:0] y;
	input[1:0] s1s0;
	output reg [16:0] out;
	    
    always @(*)
	begin
		case(s1s0)
		2'b00:            
           	out=(x+y);
        2'b01:            
          	out=(x-y);
       	2'b10:            
           	out=(x<<1);  
       	2'b11:            
           	out=(x>>1); 
		endcase
		
	end
endmodule

module logicOP(x,y,s1s0,out);
	input[16:0] x;
	input[16:0] y;
	input[1:0] s1s0;
	output reg[16:0] out;
	   
    always @(*)
	begin
		case(s1s0)
		2'b00:            
           	out=(x&y);
       	2'b01:            
			out=(x|y);
        2'b10:            
          	out=(x^y);
       	2'b11:            
       		out=(~x);
		endcase
	end
endmodule



//Clock Module to track time in our system
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

//module to save the output value
module accumulatorA(in, acc, clk, reset);
	input [16:0] in;
	input clk, reset;
	output [16:0] acc;
	reg [16:0] acc;
	always@(clk) begin
		if(reset)
			acc <= 8'b00000000;
		else
			acc <= in;
	end
endmodule

//module to save the output value
module accumulatorB(in, acc, clk, reset);
	input in;
	input clk, reset;
	output  acc;
	reg acc;
	always@(clk) begin
		if(reset)
			acc <= 1'b0;
		else
			acc <= in;
	end
endmodule


module testbench1;

    reg[16:0] x, y;          // Input registers (A is Num 1, B is Num 2) 
    reg[3:0] op;        // op bits
    wire[16:0] out;          // Output
	wire[16:0] result;
    wire c;
	wire curr;
	wire prev;
	
    Clock clock(c);
    ALU16bit test1(x,y,op[2:0],out);
	accumulatorA nextState(out,result,c,1'b0);
	accumulatorB currentState(curr,prev,c,1'b0);
    
    initial begin
        #5 x = 16'h0001; y = 16'hFFFF; op = 3'b0;
    
		$display("16-Bit ALU");
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
    
        // Display labels 
        #5 $display("Num 1                      Num 2                      Operation    Current Output                      Next State ");
        
        // Loop for displaying Num 1, Num 2, Operation, and Current State
		while (op < 4'b1000)
        begin

            // Display Num 1, Num 2, and Opcode
            #5 $write("%b", x, " (", "%d", x, ") ", "%b", y, " (", "%d", y, ") ", "%b", (op));
        
            // Display Operation depending on op bits and Current State
          case(op)
            3'b000:
				begin
					$write(" (Add)   Running "); 
					if (out >= 17'b01111111111111111)
						$display("XXXXXXXXXXXXXXXXX (Nan)     ERROR");
					else
						$display("%b", out, " (", "%d", out, ")  Running");
				end
            3'b001:
				begin
					$write(" (Sub)   Running ");
					if (out >= 17'b01111111111111111)
						$display("%b", out, " (-", "%d", ~(out-1'b1), ") Running");
					else
						$display("%b", out, " (", "%d", out, ")  Running");
				end
            3'b010:
				begin
					$write(" (Left)  Running ");
					if (out > 17'b01111111111111111)
						$display("XXXXXXXXXXXXXXXXX (Nan)  ERROR");
					else
						$display("%b", out, " (", "%d", out, ")  Running");
				end
            3'b011:
				begin
					$write(" (Right) Running ");
					if (out > 17'b01111111111111111)
						$display("%b", (out-17'b10000000000000000), " (", "%d", (out-17'b10000000000000000), ")  Running"); 
					else
						$display("%b", out, " (", "%d", out, ")  Running");
				end
            3'b100:
				begin
					$write(" (AND)   Running ");
					if (out > 17'b01111111111111111)
						$display("%b", (out-17'b10000000000000000), " (", "%d", (out-17'b10000000000000000), ")  Running"); 
					else
						$display("%b", out, " (", "%d", out, ")  Running");
				end
            3'b101:
				begin
					$write(" (OR)    Running ");
					if (out > 17'b01111111111111111)
						$display("%b", (out-17'b10000000000000000), " (", "%d", (out-17'b10000000000000000), ")  Running"); 
					else
						$display("%b", out, " (", "%d", out, ")  Running");
				end
            3'b110:
				begin
					$write(" (XOR)   Running ");
					if (out > 17'b01111111111111111)
						$display("%b", (out-17'b10000000000000000), " (", "%d", (out-17'b10000000000000000), ")  Running"); 
					else
						$display("%b", out, " (", "%d", out, ")  Running");
				end
            3'b111:
				begin
					$write(" (NOT)   Running ");
					if (out > 17'b01111111111111111)
						$display("%b", (out-17'b10000000000000000), " (", "%d", (out-17'b10000000000000000), ")  Running"); 
					else
						$display("%b", out, " (", "%d", out, ")  Running");
				end
			endcase
       
       
        #10;
        op=op+3'b001; // Add 1 to op bits
        end
        
        $display("");
		
      
    end
endmodule

