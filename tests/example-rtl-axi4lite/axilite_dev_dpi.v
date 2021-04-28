`timescale 1ns / 1ps

`include "include/axi.svh"

`ifdef NOT_DEFINED
module Bus(input In1, output Out1);
  import "DPI" function void slave_write(input int address,
                                         input int data);
  export "DPI" function write;  // Note – not a function prototype

  // This SystemVerilog function could be called from C
  function void write(int address, int data);
    // Call C function
    slave_write(address, data); // Arguments passed by copy
  endfunction
  ...
endmodule
`endif

module axilite_dev_dpi(
	input clk,
	input resetn);

	`AXILITE_NETS(m00, 32, 32);

	axilite_dev axidev(.s00_axi_aclk(clk), .s00_axi_aresetn(resetn),
		`AXILITE_CONNECT_PORT(s00_axi_, m00_));

	export "DPI-C" function xtor_write;  // Note – not a function prototype
	// This SystemVerilog function could be called from C
	function void xtor_write(int address, int data);
		$display("Got data %x = %x", address, data);
	endfunction

   initial begin
      if ($test$plusargs("trace") != 0) begin
         $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
         $dumpfile("logs/vlt_dump.vcd");
         $dumpvars();
      end
      $display("[%0t] Model running...\n", $time);
   end


endmodule
