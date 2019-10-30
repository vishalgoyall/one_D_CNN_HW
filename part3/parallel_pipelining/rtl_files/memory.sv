//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 2 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description: File to Store data inputs from master
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module memory(clk, data_in, data_out, addr, wr_en);
   
    parameter                   	WIDTH=16, SIZE=64, LOGSIZE=6;
    input signed [WIDTH-1:0]           	data_in;
    output logic signed [WIDTH-1:0]	data_out[SIZE-1:0];
    input [LOGSIZE-1:0]         	addr;
    input                       	clk, wr_en;
    
    // Signal to output all the memory registers
    logic signed [WIDTH-1:0] mem[SIZE-1:0];
    
    always_ff @(posedge clk) begin
        if (wr_en)
            mem[addr] <= data_in;
    end

    assign data_out = mem;

endmodule
