/*
   Copyright 2016 Scott Teal

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

module axi_gpio_tb;

// Device Parameters
parameter C_ALL_INPUTS        = 0;            ///< GPIO  - All inputs. '0' or '1'
parameter C_ALL_OUTPUTS       = 0;            ///< GPIO  - All outputs. '0' or '1'
parameter C_GPIO_WIDTH        = 32;           ///< GPIO  - Width. Range is 1 to 32
parameter C_DOUT_DEFAULT      = 32'h00000000; ///< GPIO  - Default output value. Any 32-bit word
parameter C_TRI_DEFAULT       = 32'hFFFFFFFF; ///< GPIO  - Default tri-state value. Any 32-bit word
parameter C_IS_DUAL           = 1;            ///< Enable dual channel. '0' or '1'
parameter C_ALL_INPUTS_2      = 0;            ///< GPIO2  - All inputs. '0' or '1'
parameter C_ALL_OUTPUTS_2     = 0;            ///< GPIO2  - All outputs. '0' or '1'
parameter C_GPIO2_WIDTH       = 32;           ///< GPIO2  - Width. Range is 1 to 32
parameter C_DOUT_DEFAULT_2    = 32'h00000000; ///< GPIO2  - Default output value. Any 32-bit word
parameter C_TRI_DEFAULT_2     = 32'hFFFFFFFF; ///< GPIO2  - Default tri-state value. Any 32-bit word
parameter C_INTERRUPT_PRESENT = 1;            ///< Enable interrupt. '0' or '1'

// Registers
localparam REG_GPIO_IO       = 9'h000; // Channel 1 gpio data
localparam REG_GPIO_IO_T     = 9'h004; // Channel 1 gpio tri-state control
localparam REG_GPIO2_IO      = 9'h008; // Channel 2 gpio data
localparam REG_GPIO2_IO_T    = 9'h00C; // Channel 2 gpio tri-state control
localparam REG_GLOBAL_INT_EN = 9'h11C; // Global interrupt enables
localparam REG_IP_INT_EN     = 9'h120; // IP interrupt enables
localparam REG_IP_INT_STATUS = 9'h128; // IP interrupt status

// Testbench Signals
logic clk  = 1'b0;
logic rstn = 1'b0;
logic pass = 1'b1;
logic success = 1'b0;

// Device Signals
axi4_lite_if axiBus(.ACLK(clk),.ARESETn(rstn));
logic ip2intc_irpt;                           ///< GPIO Interrupt. Active high.
logic  [C_GPIO_WIDTH-1:0] gpio_io_i = 32'h0;  ///< Channel 1 inputs
logic  [C_GPIO_WIDTH-1:0] gpio_io_o;          ///< Channel 1 outputs
logic  [C_GPIO_WIDTH-1:0] gpio_io_t;          ///< Channel 1 tri-state control
logic [C_GPIO2_WIDTH-1:0] gpio2_io_i = 32'h0; ///< Channel 2 inputs
logic [C_GPIO2_WIDTH-1:0] gpio2_io_o;         ///< Channel 2 outputs
logic [C_GPIO2_WIDTH-1:0] gpio2_io_t;         ///< Channel 2 tri-state control

always #1 clk = ~clk;

always @(gpio_io_o)  gpio_io_i  = gpio_io_o;
always @(gpio2_io_o) gpio2_io_i = gpio2_io_o;

initial begin
    axiBus.InitializeMaster();
    @(posedge clk) rstn = 1'b0;
    @(posedge clk) rstn = 1'b0;
    @(posedge clk) rstn = 1'b0;
    @(posedge clk) rstn = 1'b1;

    // Test AXI Bus
    axiBus.TestNormal(REG_GPIO_IO,  success); pass &= success;
    if (!success) $display("REG_GPIO_IO failed");
    axiBus.TestNormal(REG_GPIO2_IO, success); pass &= success;
    if (!success) $display("REG_GPIO2_IO failed");

    // Test GPIO 1
    axiBus.Write(REG_GPIO_IO, 32'hDEADBEEF, 4'hF, success);
    if (gpio_io_o != 32'hDEADBEEF) success = 1'b0;
    pass &= success;
    if (!success) $display("Output to GPIO 1 failed");
    // Test GPIO 2
    axiBus.Write(REG_GPIO2_IO, 32'hDEADBEEF, 4'hF, success);
    if (gpio2_io_o != 32'hDEADBEEF) success = 1'b0;
    pass &= success;
    if (!success) $display("Output to GPIO 2 failed");

    if (pass) $display("PASSED");
    else      $display("FAILED");
    $stop();
end


axi_gpio #(
    .C_ALL_INPUTS(C_ALL_INPUTS),              ///< GPIO  - All inputs. '0' or '1'
    .C_ALL_OUTPUTS(C_ALL_OUTPUTS),            ///< GPIO  - All outputs. '0' or '1'
    .C_GPIO_WIDTH(C_GPIO_WIDTH),              ///< GPIO  - Width. Range is 1 to 32
    .C_DOUT_DEFAULT(C_DOUT_DEFAULT),          ///< GPIO  - Default output value. Any 32-bit word
    .C_TRI_DEFAULT(C_TRI_DEFAULT),            ///< GPIO  - Default tri-state value. Any 32-bit word
    .C_IS_DUAL(C_IS_DUAL),                    ///< Enable dual channel. '0' or '1'
    .C_ALL_INPUTS_2(C_ALL_INPUTS_2),          ///< GPIO2  - All inputs. '0' or '1'
    .C_ALL_OUTPUTS_2(C_ALL_OUTPUTS_2),        ///< GPIO2  - All outputs. '0' or '1'
    .C_GPIO2_WIDTH(C_GPIO2_WIDTH),            ///< GPIO2  - Width. Range is 1 to 32
    .C_DOUT_DEFAULT_2(C_DOUT_DEFAULT_2),      ///< GPIO2  - Default output value. Any 32-bit word
    .C_TRI_DEFAULT_2(C_TRI_DEFAULT_2),        ///< GPIO2  - Default tri-state value. Any 32-bit word
    .C_INTERRUPT_PRESENT(C_INTERRUPT_PRESENT) ///< Enable interrupt. '0' or '1'
)
uut (
    .s_axi(axiBus),              ///< AXI4-Lite slave interface
    .ip2intc_irpt(ip2intc_irpt), ///< GPIO Interrupt. Active high.
    .gpio_io_i(gpio_io_i),       ///< [C_GPIO_WIDTH-1:0] Channel 1 inputs
    .gpio_io_o(gpio_io_o),       ///< [C_GPIO_WIDTH-1:0] Channel 1 outputs
    .gpio_io_t(gpio_io_t),       ///< [C_GPIO_WIDTH-1:0] Channel 1 tri-state control
    .gpio2_io_i(gpio2_io_i),     ///< [C_GPIO2_WIDTH-1:0] Channel 2 inputs
    .gpio2_io_o(gpio2_io_o),     ///< [C_GPIO2_WIDTH-1:0] Channel 2 outputs
    .gpio2_io_t(gpio2_io_t)      ///< [C_GPIO2_WIDTH-1:0] Channel 2 tri-state control
);

endmodule
