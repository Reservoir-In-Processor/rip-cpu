`default_nettype none
`timescale 1ns / 1ps

//
// memory module implementation for FPGA Block RAM primitive
//

// Module: rip_2r1w_bram_byte
// Description: 2-read 1-write bram with byte-wise write
// Note: only supports byte aligned data width
module rip_2r1w_bram_byte
    import rip_const::*;
#(
  parameter DATA_WIDTH = 32, // bram data width
  parameter ADDR_WIDTH = 10  // bram data depth
) (
  input wire clk,
  input wire enable_1,
  input wire enable_2,
  input wire [ADDR_WIDTH-1:0] addr_1,
  input wire [ADDR_WIDTH-1:0] addr_2,
  input wire [DATA_WIDTH/B_WIDTH-1:0] we_1,
  input wire [DATA_WIDTH-1:0] din_1,
  output reg [DATA_WIDTH-1:0] dout_1,
  output reg [DATA_WIDTH-1:0] dout_2
);

  (* ram_style = "block" *)
  logic [DATA_WIDTH-1:0] ram [(2 ** ADDR_WIDTH)];

  generate
    for (genvar i = 0; i < DATA_WIDTH/B_WIDTH; i++) begin
      always_ff @(posedge clk) begin
        if (enable_1) begin
          if (we_1[i]) begin
            ram[addr_1][i*B_WIDTH +: B_WIDTH] <= din_1[i*B_WIDTH +: B_WIDTH];
          end
          dout_1[i*B_WIDTH +: B_WIDTH] <= ram[addr_1][i*B_WIDTH +: B_WIDTH];
        end
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (enable_2) begin
      dout_2 <= ram[addr_2];
    end
  end

endmodule

`default_nettype wire
