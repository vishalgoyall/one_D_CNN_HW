//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 1 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description: This is the memory module being used to store F vectors
// This module acts as a de-serializer to output the data parallely
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module memory(clk, data_in, data_out, addr, wr_en);
   
    parameter                   	WIDTH=16, SIZE=64, LOGSIZE=6;
    input [WIDTH-1:0]           	data_in;
    output logic signed [WIDTH-1:0]	data_out[SIZE-1:0];
    input [LOGSIZE-1:0]         	addr;
    input                       	clk, wr_en;
    
    // Signal to output all the memory registers
    logic signed [WIDTH-1:0] mem[SIZE-1:0];
    
    always_ff @(posedge clk) begin
        if (wr_en)
            mem[addr] <= data_in;
    end

// outputting all registers' outputs in a single cycle
assign data_out = mem;

endmodule
