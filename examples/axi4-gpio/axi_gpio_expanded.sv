module axi_gpio_expanded
#(
    parameter C_ALL_INPUTS        = 0,            ///< GPIO  - All inputs. '0' or '1'
    parameter C_ALL_OUTPUTS       = 0,            ///< GPIO  - All outputs. '0' or '1'
    parameter C_GPIO_WIDTH        = 32,           ///< GPIO  - Width. Range is 1 to 32
    parameter C_DOUT_DEFAULT      = 32'h00000000, ///< GPIO  - Default output value. Any 32-bit word
    parameter C_TRI_DEFAULT       = 32'hFFFFFFFF, ///< GPIO  - Default tri-state value. Any 32-bit word
    parameter C_IS_DUAL           = 0,            ///< Enable dual channel. '0' or '1'
    parameter C_ALL_INPUTS_2      = 0,            ///< GPIO2  - All inputs. '0' or '1'
    parameter C_ALL_OUTPUTS_2     = 0,            ///< GPIO2  - All outputs. '0' or '1'
    parameter C_GPIO2_WIDTH       = 32,           ///< GPIO2  - Width. Range is 1 to 32
    parameter C_DOUT_DEFAULT_2    = 32'h00000000, ///< GPIO2  - Default output value. Any 32-bit word
    parameter C_TRI_DEFAULT_2     = 32'hFFFFFFFF, ///< GPIO2  - Default tri-state value. Any 32-bit word
    parameter C_INTERRUPT_PRESENT = 0             ///< Enable interrupt. '0' or '1'
)
(
    input logic ACLK,    ///< Global clock signal
    input logic ARESETn, ///< Global reset signal, active LOW

    input  logic              [8:2] AWADDR,   ///< Write address
    input  logic              [2:0] AWPROT,   ///< Protection type
    input  logic                    AWVALID,  ///< Write address valid
    output logic                    AWREADY,  ///< Write address ready

    input  logic             [31:0] WDATA,  ///< Write data
    input  logic              [3:0] WSTRB,  ///< Write strobes
    input  logic                    WVALID, ///< Write valid
    output logic                    WREADY, ///< Write ready

    output logic              [1:0] BRESP,  ///< Write response
    output logic                    BVALID, ///< Write response valid
    input  logic                    BREADY, ///< Response ready

    input  logic              [8:2] ARADDR,   ///< Read address
    input  logic              [2:0] ARPROT,   ///< Protection type
    input  logic                    ARVALID,  ///< Read address valid
    output logic                    ARREADY,  ///< Read address ready

    output logic             [31:0] RDATA,  ///< Read data
    output logic              [1:0] RRESP,  ///< Read response
    output logic                    RVALID, ///< Read valid
    input  logic                    RREADY, ///< Read ready

    output logic ip2intc_irpt,                   ///< GPIO Interrupt. Active high.
    input  logic  [C_GPIO_WIDTH-1:0] gpio_io_i,  ///< Channel 1 inputs
    output logic  [C_GPIO_WIDTH-1:0] gpio_io_o,  ///< Channel 1 outputs
    output logic  [C_GPIO_WIDTH-1:0] gpio_io_t,  ///< Channel 1 tri-state control
    input  logic [C_GPIO2_WIDTH-1:0] gpio2_io_i, ///< Channel 2 inputs
    output logic [C_GPIO2_WIDTH-1:0] gpio2_io_o, ///< Channel 2 outputs
    output logic [C_GPIO2_WIDTH-1:0] gpio2_io_t  ///< Channel 2 tri-state control
);
   axi4_lite_if axibus(ACLK, ARESETn);

   axi_gpio #(.C_ALL_INPUTS(C_ALL_INPUTS),
              .C_ALL_OUTPUTS(C_ALL_OUTPUTS),
              .C_GPIO_WIDTH(C_GPIO_WIDTH),
              .C_DOUT_DEFAULT(C_DOUT_DEFAULT),
              .C_TRI_DEFAULT(C_TRI_DEFAULT),
              .C_IS_DUAL(C_IS_DUAL),
              .C_ALL_INPUTS_2(C_ALL_INPUTS_2),
              .C_ALL_OUTPUTS_2(C_ALL_OUTPUTS_2),
              .C_GPIO2_WIDTH(C_GPIO2_WIDTH),
              .C_DOUT_DEFAULT_2(C_DOUT_DEFAULT_2),
              .C_TRI_DEFAULT_2(C_TRI_DEFAULT_2),
              .C_INTERRUPT_PRESENT(C_INTERRUPT_PRESENT))
     gpio(.s_axi(axibus), .*);

   always_comb begin
      axibus.AWADDR[8:0] = {AWADDR, 2'b00};
      axibus.AWPROT = AWPROT;
      axibus.AWVALID = AWVALID;
      AWREADY = axibus.AWREADY;

      axibus.WDATA = WDATA;
      axibus.WSTRB = WSTRB;
      axibus.WVALID = WVALID;
      WREADY = axibus.WREADY;

      BRESP = axibus.BRESP;
      BVALID = axibus.BVALID;
      axibus.BREADY = BREADY;

      axibus.ARADDR[8:0] = {ARADDR, 2'b00};
      axibus.ARPROT = ARPROT;
      axibus.ARVALID = ARVALID;
      ARREADY = axibus.ARREADY;

      RDATA = axibus.RDATA;
      RRESP = axibus.RRESP;
      RVALID = axibus.RVALID;
      axibus.RREADY = RREADY;
   end
endmodule
