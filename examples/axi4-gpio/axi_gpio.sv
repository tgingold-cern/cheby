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

/**
# AXI GPIO V2.0 #

Replicates Xilinx's AXI GPIO V2.0 IP, based on publicly available spec sheet. It
uses fewer resources than the Xilinx IP for all configurations.

## Features ##
- AXI4-Lite Interface
- Single or dual GPIO channels
- Each channel has a configurable width of 1 to 32 bits
- Each GPIO bit can be dynamically switch between input and output
- Channels are independently configurable
- Independent reset values for each bit
- Optional interrupt request signal

## AXI4-Lite Interface ##

Implements a 32-bit AXI4-Lite slave.

| Address Offset | Register Name | Access Type | Default | Description                      |
| --             | --            | --          | --      | --                               |
| 0x00           | GPIO_DATA     | R/W         | 0x0     | Channel 1 gpio data              |
| 0x04           | GPIO_TRI      | R/W         | 0x0     | Channel 1 gpio tri-state control |
| 0x08           | GPIO2_DATA    | R/W         | 0x0     | Channel 2 gpio data              |
| 0x0C           | GPIO2_TRI     | R/W         | 0x0     | Channel 2 gpio tri-state control |
| 0x11C          | GIER          | R/W         | 0x0     | Global interrupt enables         |
| 0x128          | IP IER        | R/W         | 0x0     | IP interrupt enables             |
| 0x120          | IP ISR        | R/TOW       | 0x0     | IP interrupt status              |

Note: TOW is Toggle-On-Write, which toggles thte status of a bit when a value of
1 is written to it.

## Resource Usage ##

Approximate FF usage is:
`3*C_GPIO_WIDTH + 3*C_GPIO2_WIDTH + 32 + 6 + 32*C_INTERRUPT_PRESENT*(1+C_IS_DUAL)`.

| Dual Channel | Interrupts | GPIO Width | GPIO2 Width | FF  | LUTs |
| ---          | ---        | ---        | ---         | --- | ---  |
| 0            | 0          | 32         |  N/A        | 133 | 48   |
| 0            | 0          | 16         |  N/A        | 70  | 28   |
| 0            | 1          | 32         |  N/A        | 171 | 73   |
| 0            | 1          |  1         |  N/A        | 19  | 27   |
| 1            | 0          | 32         |  32         | 229 | 87   |
| 1            | 0          |  1         |   1         | 12  | 13   |
| 1            | 0          |  5         |  28         | 132 | 52   |
| 1            | 0          | 28         |   5         | 132 | 51   |
| 1            | 1          | 32         |  32         | 299 | 109  |
| 1            | 1          | 15         |  28         | 212 | 92   |
| 1            | 1          |  1         |   1         | 22  | 28   |

*/

module axi_gpio
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
    axi4_lite_if.slave s_axi,                    ///< AXI4-Lite slave interface
    output logic ip2intc_irpt,                   ///< GPIO Interrupt. Active high.
    input  logic  [C_GPIO_WIDTH-1:0] gpio_io_i,  ///< Channel 1 inputs
    output logic  [C_GPIO_WIDTH-1:0] gpio_io_o,  ///< Channel 1 outputs
    output logic  [C_GPIO_WIDTH-1:0] gpio_io_t,  ///< Channel 1 tri-state control
    input  logic [C_GPIO2_WIDTH-1:0] gpio2_io_i, ///< Channel 2 inputs
    output logic [C_GPIO2_WIDTH-1:0] gpio2_io_o, ///< Channel 2 outputs
    output logic [C_GPIO2_WIDTH-1:0] gpio2_io_t  ///< Channel 2 tri-state control
);

localparam REG_GPIO_IO       = 9'h000; // Channel 1 gpio data
localparam REG_GPIO_IO_T     = 9'h004; // Channel 1 gpio tri-state control
localparam REG_GPIO2_IO      = 9'h008; // Channel 2 gpio data
localparam REG_GPIO2_IO_T    = 9'h00C; // Channel 2 gpio tri-state control
localparam REG_GLOBAL_INT_EN = 9'h11C; // Global interrupt enables
localparam REG_IP_INT_EN     = 9'h120; // IP interrupt enables
localparam REG_IP_INT_STATUS = 9'h128; // IP interrupt status

localparam GPIO_IO_HIGH_0  = (C_GPIO_WIDTH >  8) ?  7 : C_GPIO_WIDTH-1;
localparam GPIO_IO_HIGH_1  = (C_GPIO_WIDTH > 16) ? 15 : C_GPIO_WIDTH-1;
localparam GPIO_IO_HIGH_2  = (C_GPIO_WIDTH > 24) ? 23 : C_GPIO_WIDTH-1;
localparam GPIO_IO_HIGH_3  = (C_GPIO_WIDTH > 32) ? 31 : C_GPIO_WIDTH-1;
localparam GPIO2_IO_HIGH_0 = (C_GPIO2_WIDTH >  8) ?  7 : C_GPIO2_WIDTH-1;
localparam GPIO2_IO_HIGH_1 = (C_GPIO2_WIDTH > 16) ? 15 : C_GPIO2_WIDTH-1;
localparam GPIO2_IO_HIGH_2 = (C_GPIO2_WIDTH > 24) ? 23 : C_GPIO2_WIDTH-1;
localparam GPIO2_IO_HIGH_3 = (C_GPIO2_WIDTH > 32) ? 31 : C_GPIO2_WIDTH-1;

logic [8:0] awaddr;
logic [8:0] araddr;

logic [C_GPIO_WIDTH-1:0]  gpio_io_i_reg;
logic [C_GPIO2_WIDTH-1:0] gpio2_io_i_reg;
logic [C_GPIO_WIDTH-1:0]  gpio_io_i_reg2;
logic [C_GPIO2_WIDTH-1:0] gpio2_io_i_reg2;

logic global_int_en;
logic [1:0] ip_int_en;
logic [1:0] ip_int_status;

logic clk;
logic rst; // Active high
logic write_strobe;
logic read_strobe;

logic wr_reg_gpio_io;
logic wr_reg_gpio_io_t;
logic wr_reg_gpio2_io;
logic wr_reg_gpio2_io_t;
logic wr_reg_global_int_en;
logic wr_reg_ip_int_en;
logic wr_reg_ip_int_status;

// Sanity Check of Parameters
// {{{
initial begin
    if (!(C_ALL_INPUTS inside {0, 1})) begin
        $display("Attribute Syntax Error : The Attribute C_ALL_INPUTS on axi_gpio instance %m is set to %d.  Legal values for this attribute are 0 or 1", C_ALL_INPUTS);
        $finish();
    end
    if (!(C_ALL_OUTPUTS inside {0, 1})) begin
        $display("Attribute Syntax Error : The Attribute C_ALL_OUTPUTS on axi_gpio instance %m is set to %d.  Legal values for this attribute are 0 or 1", C_ALL_OUTPUTS);
        $finish();
    end
    if (C_GPIO_WIDTH < 1 || C_GPIO_WIDTH > 32) begin
        $display("Attribute Syntax Error : The Attribute C_GPIO_WIDTH on axi_gpio instance %m is set to %d.  Legal values for this attribute are 1 to 32", C_GPIO_WIDTH);
        $finish();
    end
    if (!(C_IS_DUAL inside {0, 1})) begin
        $display("Attribute Syntax Error : The Attribute C_IS_DUAL on axi_gpio instance %m is set to %d.  Legal values for this attribute are 0 or 1", C_IS_DUAL);
        $finish();
    end
    if (!(C_ALL_INPUTS_2 inside {0, 1})) begin
        $display("Attribute Syntax Error : The Attribute C_ALL_INPUTS_2 on axi_gpio instance %m is set to %d.  Legal values for this attribute are 0 or 1", C_ALL_INPUTS_2);
        $finish();
    end
    if (!(C_ALL_OUTPUTS_2 inside {0, 1})) begin
        $display("Attribute Syntax Error : The Attribute C_ALL_OUTPUTS_2 on axi_gpio instance %m is set to %d.  Legal values for this attribute are 0 or 1", C_ALL_OUTPUTS_2);
        $finish();
    end
    if (C_GPIO2_WIDTH < 1 || C_GPIO2_WIDTH > 32) begin
        $display("Attribute Syntax Error : The Attribute C_GPIO2_WIDTH on axi_gpio instance %m is set to %d.  Legal values for this attribute are 1 to 32", C_GPIO2_WIDTH);
        $finish();
    end
    if (!(C_INTERRUPT_PRESENT inside {0, 1})) begin
        $display("Attribute Syntax Error : The Attribute C_INTERRUPT_PRESENT on axi_gpio instance %m is set to %d.  Legal values for this attribute are 0 or 1", C_INTERRUPT_PRESENT);
        $finish();
    end
    if (s_axi.ADDR_WIDTH < 9) begin
        $display("AXI Parameter Error: The AXI4-Lit bus on axi_gpio instance %m only has %d address bits. At least 9 are required.", s_axi.ADDR_WIDTH);
        $finish();
    end
end
// }}}

assign clk = s_axi.ACLK;

// Register reset for local use
always_ff @(posedge clk) begin
    rst <= ~s_axi.ARESETn;
end

/**************************************************************************/
// Write Channel
/**************************************************************************/
assign write_strobe = s_axi.AWVALID && s_axi.WVALID && !s_axi.BVALID;

// Address decode logic
assign awaddr = {s_axi.AWADDR[8:2], 2'b00};
assign wr_reg_gpio_io       = (awaddr == REG_GPIO_IO      );
assign wr_reg_gpio_io_t     = (awaddr == REG_GPIO_IO_T    );
assign wr_reg_gpio2_io      = (awaddr == REG_GPIO2_IO     );
assign wr_reg_gpio2_io_t    = (awaddr == REG_GPIO2_IO_T   );
assign wr_reg_global_int_en = (awaddr == REG_GLOBAL_INT_EN);
assign wr_reg_ip_int_en     = (awaddr == REG_IP_INT_EN    );
assign wr_reg_ip_int_status = (awaddr == REG_IP_INT_STATUS);

assign s_axi.BRESP = 2'b00; // Always respond with RESP_OKAY

generate
// 0x00 - Channel 1 gpio data
if (!C_ALL_INPUTS) begin
    if (C_GPIO_WIDTH > 0) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio_io_o[GPIO_IO_HIGH_0:0] <= C_DOUT_DEFAULT[GPIO_IO_HIGH_0:0];
            else if (write_strobe && wr_reg_gpio_io && s_axi.WSTRB[0])
                gpio_io_o[GPIO_IO_HIGH_0:0] <= s_axi.WDATA[GPIO_IO_HIGH_0:0];
        end
    end
    if (C_GPIO_WIDTH > 8) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio_io_o[GPIO_IO_HIGH_1:8] <= C_DOUT_DEFAULT[GPIO_IO_HIGH_1:8];
            else if (write_strobe && wr_reg_gpio_io && s_axi.WSTRB[1])
                gpio_io_o[GPIO_IO_HIGH_1:8] <= s_axi.WDATA[GPIO_IO_HIGH_1:8];
        end
    end
    if (C_GPIO_WIDTH > 16) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio_io_o[GPIO_IO_HIGH_2:16] <= C_DOUT_DEFAULT[GPIO_IO_HIGH_2:16];
            else if (write_strobe && wr_reg_gpio_io && s_axi.WSTRB[2])
                gpio_io_o[GPIO_IO_HIGH_2:16] <= s_axi.WDATA[GPIO_IO_HIGH_2:16];
        end
    end
    if (C_GPIO_WIDTH > 24) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio_io_o[GPIO_IO_HIGH_3:24] <= C_DOUT_DEFAULT[GPIO_IO_HIGH_3:24];
            else if (write_strobe && wr_reg_gpio_io && s_axi.WSTRB[3])
                gpio_io_o[GPIO_IO_HIGH_3:24] <= s_axi.WDATA[GPIO_IO_HIGH_3:24];
        end
    end
end
else begin
    assign gpio_io_o = C_DOUT_DEFAULT;
end

// 0x04 - Channel 1 gpio tri-state control
if (!C_ALL_INPUTS && !C_ALL_OUTPUTS) begin
    if (C_GPIO_WIDTH > 0) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio_io_t[GPIO_IO_HIGH_0:0] <= C_DOUT_DEFAULT[GPIO_IO_HIGH_0:0];
            else if (write_strobe && wr_reg_gpio_io_t && s_axi.WSTRB[0])
                gpio_io_t[GPIO_IO_HIGH_0:0] <= s_axi.WDATA[GPIO_IO_HIGH_0:0];
        end
    end
    if (C_GPIO_WIDTH > 8) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio_io_t[GPIO_IO_HIGH_1:8] <= C_DOUT_DEFAULT[GPIO_IO_HIGH_1:8];
            else if (write_strobe && wr_reg_gpio_io_t && s_axi.WSTRB[1])
                gpio_io_t[GPIO_IO_HIGH_1:8] <= s_axi.WDATA[GPIO_IO_HIGH_1:8];
        end
    end
    if (C_GPIO_WIDTH > 16) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio_io_t[GPIO_IO_HIGH_2:16] <= C_DOUT_DEFAULT[GPIO_IO_HIGH_2:16];
            else if (write_strobe && wr_reg_gpio_io_t && s_axi.WSTRB[2])
                gpio_io_t[GPIO_IO_HIGH_2:16] <= s_axi.WDATA[GPIO_IO_HIGH_2:16];
        end
    end
    if (C_GPIO_WIDTH > 24) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio_io_t[GPIO_IO_HIGH_3:24] <= C_DOUT_DEFAULT[GPIO_IO_HIGH_3:24];
            else if (write_strobe && wr_reg_gpio_io_t && s_axi.WSTRB[3])
                gpio_io_t[GPIO_IO_HIGH_3:24] <= s_axi.WDATA[GPIO_IO_HIGH_3:24];
        end
    end
end
else begin
    assign gpio_io_t = C_TRI_DEFAULT;
end

// 0x08 - Channel 2 gpio data
if (C_IS_DUAL && !C_ALL_INPUTS_2) begin
    if (C_GPIO2_WIDTH > 0) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio2_io_o[GPIO2_IO_HIGH_0:0] <= C_DOUT_DEFAULT[GPIO2_IO_HIGH_0:0];
            else if (write_strobe && wr_reg_gpio2_io && s_axi.WSTRB[0])
                gpio2_io_o[GPIO2_IO_HIGH_0:0] <= s_axi.WDATA[GPIO2_IO_HIGH_0:0];
        end
    end
    if (C_GPIO2_WIDTH > 8) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio2_io_o[GPIO2_IO_HIGH_1:8] <= C_DOUT_DEFAULT[GPIO2_IO_HIGH_1:8];
            else if (write_strobe && wr_reg_gpio2_io && s_axi.WSTRB[1])
                gpio2_io_o[GPIO2_IO_HIGH_1:8] <= s_axi.WDATA[GPIO2_IO_HIGH_1:8];
        end
    end
    if (C_GPIO2_WIDTH > 16) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio2_io_o[GPIO2_IO_HIGH_2:16] <= C_DOUT_DEFAULT[GPIO2_IO_HIGH_2:16];
            else if (write_strobe && wr_reg_gpio2_io && s_axi.WSTRB[2])
                gpio2_io_o[GPIO2_IO_HIGH_2:16] <= s_axi.WDATA[GPIO2_IO_HIGH_2:16];
        end
    end
    if (C_GPIO2_WIDTH > 24) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio2_io_o[GPIO2_IO_HIGH_3:24] <= C_DOUT_DEFAULT[GPIO2_IO_HIGH_3:24];
            else if (write_strobe && wr_reg_gpio2_io && s_axi.WSTRB[3])
                gpio2_io_o[GPIO2_IO_HIGH_3:24] <= s_axi.WDATA[GPIO2_IO_HIGH_3:24];
        end
    end
end
else begin
    assign gpio2_io_o = C_DOUT_DEFAULT_2;
end

// 0x0C - Channel 2 gpio tri-state control
if (C_IS_DUAL && !C_ALL_INPUTS_2 && !C_ALL_OUTPUTS_2) begin
    if (C_GPIO2_WIDTH > 0) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio2_io_t[GPIO2_IO_HIGH_0:0] <= C_DOUT_DEFAULT[GPIO2_IO_HIGH_0:0];
            else if (write_strobe && wr_reg_gpio2_io_t && s_axi.WSTRB[0])
                gpio2_io_t[GPIO2_IO_HIGH_0:0] <= s_axi.WDATA[GPIO2_IO_HIGH_0:0];
        end
    end
    if (C_GPIO2_WIDTH > 8) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio2_io_t[GPIO2_IO_HIGH_1:8] <= C_DOUT_DEFAULT[GPIO2_IO_HIGH_1:8];
            else if (write_strobe && wr_reg_gpio2_io_t && s_axi.WSTRB[1])
                gpio2_io_t[GPIO2_IO_HIGH_1:8] <= s_axi.WDATA[GPIO2_IO_HIGH_1:8];
        end
    end
    if (C_GPIO2_WIDTH > 16) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio2_io_t[GPIO2_IO_HIGH_2:16] <= C_DOUT_DEFAULT[GPIO2_IO_HIGH_2:16];
            else if (write_strobe && wr_reg_gpio2_io_t && s_axi.WSTRB[2])
                gpio2_io_t[GPIO2_IO_HIGH_2:16] <= s_axi.WDATA[GPIO2_IO_HIGH_2:16];
        end
    end
    if (C_GPIO2_WIDTH > 24) begin
        always_ff @(posedge clk) begin
            if (rst)
                gpio2_io_t[GPIO2_IO_HIGH_3:24] <= C_DOUT_DEFAULT[GPIO2_IO_HIGH_3:24];
            else if (write_strobe && wr_reg_gpio2_io_t && s_axi.WSTRB[3])
                gpio2_io_t[GPIO2_IO_HIGH_3:24] <= s_axi.WDATA[GPIO2_IO_HIGH_3:24];
        end
    end
end
else begin
    assign gpio2_io_t = C_TRI_DEFAULT;
end

if (C_INTERRUPT_PRESENT) begin
    always_ff @(posedge clk) begin
        if (rst) begin
            global_int_en <= 1'b0;
            ip_int_en <= 2'b00;
        end
        else if (write_strobe) begin
            if (wr_reg_global_int_en && s_axi.WSTRB[3]) global_int_en <= s_axi.WDATA[31];
            if (wr_reg_ip_int_en && s_axi.WSTRB[0]) ip_int_en <= s_axi.WDATA[1:0];
            // ip_int_status is handled in the Interrupt Logic
        end
    end
end
else begin
    assign global_int_en = 1'b0;
    assign ip_int_en = 2'b00;
end

endgenerate

// AXI Write Channel Controls
always_ff @(posedge clk) begin
    if (rst) begin
        s_axi.AWREADY <= 1'b0;
        s_axi.WREADY  <= 1'b0;
        s_axi.BVALID  <= 1'b0;
    end
    else begin
        s_axi.AWREADY <= write_strobe;
        s_axi.WREADY  <= write_strobe;
        // Write Response Channel
        if (write_strobe) begin
            s_axi.BVALID  <= 1'b1;
        end
        else if (s_axi.BVALID) begin
            s_axi.BVALID  <= ~s_axi.BREADY;
        end
    end
end

/**************************************************************************/
// Register Inputs
/**************************************************************************/

generate

if (!C_ALL_OUTPUTS) begin
    always_ff @(posedge clk) begin
        gpio_io_i_reg  <= gpio_io_i;
    end
end
else begin
    assign gpio_io_i_reg = '0;
end
if (C_IS_DUAL && !C_ALL_OUTPUTS_2) begin
    always_ff @(posedge clk) begin
        gpio2_io_i_reg <= gpio2_io_i;
    end
end
else begin
    assign gpio2_io_i_reg = '0;
end

endgenerate

/**************************************************************************/
// Interrupt Logic
/**************************************************************************/

generate
if (C_INTERRUPT_PRESENT) begin
    always_ff @(posedge clk) begin
        if (rst) begin
            gpio_io_i_reg2  <= '0;
            gpio2_io_i_reg2 <= '0;
            ip_int_status   <= '0;
            ip2intc_irpt    <= 1'b0;
        end
        else begin
            // GPIO 1
            gpio_io_i_reg2  <= gpio_io_i_reg;
            if (gpio_io_i_reg != gpio_io_i_reg2) begin
                ip_int_status[0] <= 1'b1;
            end
            else if (write_strobe && wr_reg_ip_int_status && s_axi.WSTRB[0]) begin
                ip_int_status[0] <= s_axi.WDATA[0] ^ ip_int_status[0];
            end
            // GPIO 2
            gpio2_io_i_reg2 <= gpio2_io_i_reg;
            if (gpio2_io_i_reg != gpio2_io_i_reg2) begin
                ip_int_status[1] <= 1'b1;
            end
            else if (write_strobe && wr_reg_ip_int_status && s_axi.WSTRB[0]) begin
                ip_int_status[1] <= s_axi.WDATA[1] ^ ip_int_status[1];
            end
            // Interrupt Output
            ip2intc_irpt <= |ip_int_status[1:0];
        end
    end
end
else begin
    assign ip2intc_irpt = 1'b0;
    assign ip_int_status = 2'b00;
    assign gpio_io_i_reg2 = '0;
    assign gpio2_io_i_reg2 = '0;
end
endgenerate

/**************************************************************************/
// Read Channel
/**************************************************************************/

assign read_strobe = s_axi.ARVALID && !s_axi.RVALID;

assign s_axi.RRESP = 2'b00; // Always respond with RESP_OKAY

assign araddr = {s_axi.ARADDR[8:2],2'b00};

always_ff @(posedge clk) begin
    if (rst) begin
        s_axi.ARREADY <= '0;
        s_axi.RDATA   <= '0;
        s_axi.RVALID  <= '0;
    end
    else begin
        s_axi.ARREADY <= read_strobe;
        if (read_strobe) begin
            s_axi.RDATA <= 32'd0; // Unused bits should default to 0
            unique case (araddr)
                REG_GPIO_IO       : s_axi.RDATA <= gpio_io_i_reg;          // Channel 1 gpio data
                REG_GPIO_IO_T     : s_axi.RDATA <= gpio_io_t;              // Channel 1 gpio tri-state control
                REG_GPIO2_IO      : s_axi.RDATA <= gpio2_io_i_reg;         // Channel 2 gpio data
                REG_GPIO2_IO_T    : s_axi.RDATA <= gpio2_io_t;             // Channel 2 gpio tri-state control
                REG_GLOBAL_INT_EN : s_axi.RDATA <= {global_int_en, 30'd0}; // Global interrupt enable
                REG_IP_INT_EN     : s_axi.RDATA <= {30'd0, ip_int_en};     // IP interrupt enables
                REG_IP_INT_STATUS : s_axi.RDATA <= {30'd0, ip_int_status}; // IP interrupt status
                default : s_axi.RDATA <= 32'd0;         // Default of 0
            endcase
        end

        if (read_strobe) begin
            s_axi.RVALID <= 1'b1;
        end
        else if (s_axi.RVALID) begin
            s_axi.RVALID <= ~s_axi.RREADY;
        end
    end
end

endmodule
/* vim: set fdm=marker: */
