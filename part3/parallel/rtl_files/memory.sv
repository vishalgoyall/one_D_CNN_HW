//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 1 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description: This is the top level module for convolution of X (8) and F (4)
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
        data_out <= mem;
        if (wr_en)
            mem[addr] <= data_in;
    end
endmodule
