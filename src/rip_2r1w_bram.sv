`default_nettype none
`timescale 1ns / 1ps

//
// memory module implementation for FPGA Block RAM primitive
//

// Module: rip_2r1w_bram
// Description: simple 2-read 1-write bram
// Note: only supports line-wise data write (with any data width)
module rip_2r1w_bram
#(
  parameter int DATA_WIDTH = 32, // bram data width
  parameter int ADDR_WIDTH = 10  // bram data depth
) (
  input wire clk,
  input wire enable_1,
  input wire enable_2,
  input wire [ADDR_WIDTH-1:0] addr_1,
  input wire [ADDR_WIDTH-1:0] addr_2,
  input wire we_1,
  input wire [DATA_WIDTH-1:0] din_1,
  output reg [DATA_WIDTH-1:0] dout_1,
  output reg [DATA_WIDTH-1:0] dout_2
);

  (* ram_style = "block" *)
  logic [DATA_WIDTH-1:0] ram [(2 ** ADDR_WIDTH)];

  always_ff @(posedge clk) begin
    if (enable_1) begin
      if (we_1) begin
        ram[addr_1] <= din_1;
      end
      dout_1 <= ram[addr_1];
    end
  end

  always_ff @(posedge clk) begin
    if (enable_2) begin
      dout_2 <= ram[addr_2];
    end
  end

endmodule

`default_nettype wire
