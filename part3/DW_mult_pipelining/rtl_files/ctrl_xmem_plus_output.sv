//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 2 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description:
// Control Module to 
// 1. write data from Master to Slave using AXI
// 2. generate m_valid signal for output
// 3. allows overlap between xmem input and y output
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//

module ctrl_xmem_plus_output
#( 
	parameter X_MEM_ADDR_WIDTH = 5,
	parameter X_SIZE = 128,
	parameter F_SIZE = 32,
	parameter PLINE_STAGES = 5
)(
        input  logic                        clk,       
        input  logic                        reset,     
        input  logic                        s_valid,   
        input  logic                        conv_start,
        input  logic                        m_ready,   
        output logic                        xmem_wr_en,
	output logic                        xmem_full,
        output logic                        m_valid,  
        output logic                        en_pline_stages,	
        output logic                        conv_done, 
	output logic                        s_ready   
);

typedef enum logic [2:0] {FILL_XMEM, FLUSH_IN, WAIT_ACCEPT, WAIT_FETCH, FLUSH_OUT, DONE} fsm;
fsm state;

logic [$clog2(X_SIZE)-1:0] xmem_tracker;
logic [$clog2(PLINE_STAGES)-1:0] pline_cntr;
logic s_ready_fsm, en_cntr;

always_ff @ (posedge clk) begin
	if (reset) begin
		s_ready_fsm  <= 1'b0;
		state        <= FILL_XMEM;
		m_valid      <= 1'b0;
		conv_done    <= 1'b0;
		xmem_full    <= 1'b0;
		pline_cntr   <= 0;
	end
	else begin
		case (state)  
			FILL_XMEM : begin
				if (xmem_tracker == unsigned'(F_SIZE-1)) begin
					if (xmem_wr_en == 1'b1) begin
						s_ready_fsm <= 1'b0;
						xmem_full   <= 1'b1; 
					end
					if (conv_start == 1'b1) begin
						s_ready_fsm <= 1'b1;
						state       <= FLUSH_IN;
					end
				end
				else begin
					s_ready_fsm <= 1'b1;
					pline_cntr  <= 0;
				end
				
			end

			FLUSH_IN: begin
				if (pline_cntr != unsigned'(PLINE_STAGES-1) && xmem_wr_en == 1'b1) begin  //allow pipeline to fill the very first time
					pline_cntr <= pline_cntr + 'b1;
				end 
				else if (pline_cntr == unsigned'(PLINE_STAGES-1) && xmem_wr_en == 1'b1) begin  //last stage filled
					m_valid      <= 1'b1;
					s_ready_fsm  <= 1'b0;
					state        <= WAIT_ACCEPT;
				end
			end


			WAIT_ACCEPT : begin
				if (m_ready == 1'b1 && m_valid == 1'b1) begin  //element was picked by master from output
					if (xmem_tracker == unsigned'(X_SIZE-1)) begin  //if output was last of y[k], then move to DONE state
						state       <= FLUSH_OUT;
						s_ready_fsm <= 1'b0;
					end
					else if (xmem_wr_en == 1'b0) begin //else if new xmem elem was not available in memory yet, fetch that data
						state       <= WAIT_FETCH;
						m_valid     <= 1'b0;
						s_ready_fsm <= 1'b1;
					end
				end
			end

			WAIT_FETCH : begin
				if (xmem_wr_en == 1'b1) begin   //if new memory write happened, move to WAIT_ACCEPT state
					state       <= WAIT_ACCEPT;
					m_valid     <= 1'b1;
					s_ready_fsm <= 1'b0;
				end
			end

			FLUSH_OUT: begin
				if (en_pline_stages == 1'b1 && pline_cntr != 0) begin  //need to wait before for pipeline to flush out
					pline_cntr <= pline_cntr - 'b1;
				end
				else if (en_pline_stages == 1'b1 && pline_cntr == 0) begin  //all stages flushed out i.e. last elem is picked by master
					conv_done      <= 1'b1;
					pline_cntr     <= 0;
					state          <= DONE;
					m_valid        <= 0;
					xmem_full      <= 1'b0;
				end
			end

			DONE : begin
				conv_done   <= 1'b0;
				if (conv_done == 1'b0)   //only after reset was applied everywhere, in next clock cycle move to FILL_XMEM
					state <= FILL_XMEM;
			end
		endcase
	end
end

assign s_ready    = (xmem_tracker == unsigned'(X_SIZE-1)) ? 1'b0 : (m_valid && m_ready) || s_ready_fsm;  //need to prevent more shift ins
assign xmem_wr_en = (xmem_tracker == unsigned'(X_SIZE-1)) ? 1'b0 : s_valid && s_ready;  //once all shifts done, need to prevent accidental overwrite
assign en_pline_stages = (state == FLUSH_IN) ? xmem_wr_en : (m_valid && m_ready);  //enable for all pipeline stages

//+++++++++++++++++++++++++++++++++++++++++++++
//Tracker to keep count of no of convolutions
//Tracker is paused once max count is reached
always_ff @(posedge clk) begin
	if (reset | conv_done) begin
		xmem_tracker <= 0;
		//en_cntr      <= 0;
	end
	else begin
		//if (xmem_wr_en == 1'b1)
		//	en_cntr <= 1'b1;

		if (xmem_wr_en == 1'b1 && 
		    xmem_tracker != unsigned'(X_SIZE-1) && !(xmem_tracker == unsigned'(F_SIZE-1) && state == FILL_XMEM))
			xmem_tracker <= xmem_tracker + 1;
	end
end

endmodule
