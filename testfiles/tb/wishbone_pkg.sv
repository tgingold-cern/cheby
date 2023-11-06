interface t_wishbone;
  parameter C_WISHBONE_ADDRESS_WIDTH = 32;
  parameter C_WISHBONE_DATA_WIDTH = 32;

  // Types
  typedef logic [C_WISHBONE_ADDRESS_WIDTH-1:0] t_wishbone_address;
  typedef logic [C_WISHBONE_DATA_WIDTH-1:0] t_wishbone_data;
  typedef logic [(C_WISHBONE_ADDRESS_WIDTH/8)-1:0] t_wishbone_byte_select;
  typedef logic [2:0] t_wishbone_cycle_type;
  typedef logic [1:0] t_wishbone_burst_type;

  typedef enum logic [1:0] {
    CLASSIC = 2'b00,
    PIPELINED = 2'b01
  } t_wishbone_interface_mode;

  typedef enum logic [1:0] {
    BYTE = 2'b00,
    WORD = 2'b01
  } t_wishbone_address_granularity;

  // Master out, slave in
  logic clk;
  logic rst_n;
  logic cyc;
  logic stb;
  t_wishbone_address adr;
  t_wishbone_byte_select sel;
  logic we;
  t_wishbone_data dato;


  // Master in, slave out
  logic ack;
  logic err;
  logic rty;
  logic stall;
  logic irq;
  t_wishbone_data dati;


  modport master (
    output clk,
    output rst_n,
    output cyc,
    output stb,
    output adr,
    output sel,
    output we,
    output dato,

    input ack,
    input err,
    input rty,
    input stall,
    input irq,
    input dati
  );

  modport slave (
    input clk,
    input rst_n,
    input cyc,
    input stb,
    input adr,
    input sel,
    input we,
    input dato,

    output ack,
    output err,
    output rty,
    output stall,
    output irq,
    output dati
  );

endinterface
