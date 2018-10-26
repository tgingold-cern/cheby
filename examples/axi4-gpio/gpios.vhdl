library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

entity gpios is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- A register
    inputs_i             : in    std_logic_vector(31 downto 0);
    outputs_o            : out   std_logic_vector(31 downto 0);

    -- An AXI4-Lite bus
    gpios_axi4_awvalid_o : out   std_logic;
    gpios_axi4_awready_i : in    std_logic;
    gpios_axi4_awaddr_o  : out   std_logic_vector(5 downto 2);
    gpios_axi4_awprot_o  : out   std_logic_vector(2 downto 0);
    gpios_axi4_wvalid_o  : out   std_logic;
    gpios_axi4_wready_i  : in    std_logic;
    gpios_axi4_wdata_o   : out   std_logic_vector(31 downto 0);
    gpios_axi4_wstrb_o   : out   std_logic_vector(3 downto 0);
    gpios_axi4_bvalid_i  : in    std_logic;
    gpios_axi4_bready_o  : out   std_logic;
    gpios_axi4_bresp_i   : in    std_logic_vector(1 downto 0);
    gpios_axi4_arvalid_o : out   std_logic;
    gpios_axi4_arready_i : in    std_logic;
    gpios_axi4_araddr_o  : out   std_logic_vector(5 downto 2);
    gpios_axi4_arprot_o  : out   std_logic_vector(2 downto 0);
    gpios_axi4_rvalid_i  : in    std_logic;
    gpios_axi4_rready_o  : out   std_logic;
    gpios_axi4_rdata_i   : in    std_logic_vector(31 downto 0);
    gpios_axi4_rresp_i   : in    std_logic_vector(1 downto 0)
  );
end gpios;

architecture syn of gpios is
  signal wb_en                          : std_logic;
  signal rd_int                         : std_logic;
  signal wr_int                         : std_logic;
  signal ack_int                        : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal outputs_reg                    : std_logic_vector(31 downto 0);
  signal gpios_axi4_aw_val              : std_logic;
  signal gpios_axi4_wval                : std_logic;
  signal gpios_axi4_aw_done             : std_logic;
  signal gpios_axi4_w_done              : std_logic;
  signal gpios_axi4_rd                  : std_logic;
  signal wr_ack_done_int                : std_logic;
  signal reg_rdat_int                   : std_logic_vector(31 downto 0);
  signal rd_ack1_int                    : std_logic;
begin

  -- WB decode signals
  wb_en <= wb_i.cyc and wb_i.stb;
  rd_int <= wb_en and not wb_i.we;
  wr_int <= wb_en and wb_i.we;
  ack_int <= rd_ack_int or wr_ack_int;
  wb_o.ack <= ack_int;
  wb_o.stall <= not ack_int and wb_en;

  -- Assign outputs
  outputs_o <= outputs_reg;

  -- Assignments for submap gpios_axi4
  gpios_axi4_awvalid_o <= gpios_axi4_aw_val;
  gpios_axi4_awaddr_o <= wb_i.adr(5 downto 2);
  gpios_axi4_awprot_o <= "000";
  gpios_axi4_wvalid_o <= gpios_axi4_wval;
  gpios_axi4_wdata_o <= wb_i.dat;
  gpios_axi4_wstrb_o <= "1111";
  gpios_axi4_bready_o <= '1';
  gpios_axi4_arvalid_o <= gpios_axi4_rd;
  gpios_axi4_araddr_o <= wb_i.adr(5 downto 2);
  gpios_axi4_arprot_o <= "000";
  gpios_axi4_rready_o <= '1';

  -- Process for write requests.
  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      wr_ack_int <= '0';
      wr_ack_done_int <= '0';
      outputs_reg <= "00000000000000000000000000000000";
      gpios_axi4_aw_val <= '0';
      gpios_axi4_wval <= '0';
    elsif rising_edge(clk_i) then
      gpios_axi4_aw_done <= '0';
      gpios_axi4_aw_val <= '0';
      gpios_axi4_w_done <= '0';
      gpios_axi4_wval <= '0';
      if wr_int = '1' then
        -- Write in progress
        wr_ack_done_int <= wr_ack_int or wr_ack_done_int;
        case wb_i.adr(6 downto 6) is
        when "0" => 
          case wb_i.adr(5 downto 2) is
          when "0000" => 
            -- Register inputs
            wr_ack_int <= not wr_ack_done_int;
          when "0001" => 
            -- Register outputs
            outputs_reg <= wb_i.dat;
            wr_ack_int <= not wr_ack_done_int;
          when others =>
          end case;
        when "1" => 
          -- Submap gpios_axi4
          gpios_axi4_aw_val <= not gpios_axi4_aw_done;
          gpios_axi4_aw_done <= gpios_axi4_aw_done or gpios_axi4_awready_i;
          gpios_axi4_wval <= not gpios_axi4_w_done;
          gpios_axi4_w_done <= gpios_axi4_w_done or gpios_axi4_wready_i;
          wr_ack_int <= gpios_axi4_bvalid_i and '1';
        when others =>
        end case;
      else
        wr_ack_int <= '0';
        wr_ack_done_int <= '0';
      end if;
    end if;
  end process;

  -- Process for registers read.
  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      rd_ack1_int <= '0';
      reg_rdat_int <= (others => 'X');
    elsif rising_edge(clk_i) then
      if rd_int = '1' and rd_ack1_int = '0' then
        rd_ack1_int <= '1';
        case wb_i.adr(6 downto 6) is
        when "0" => 
          case wb_i.adr(5 downto 2) is
          when "0000" => 
            -- inputs
            reg_rdat_int <= inputs_i;
          when "0001" => 
            -- outputs
            reg_rdat_int <= outputs_reg;
          when others =>
          end case;
        when "1" => 
        when others =>
        end case;
      else
        rd_ack1_int <= '0';
      end if;
    end if;
  end process;

  -- Process for read requests.
  process (wb_i.adr, reg_rdat_int, rd_ack1_int, rd_int, rd_int, gpios_axi4_rdata_i, gpios_axi4_rvalid_i) begin
    -- By default ack read requests
    wb_o.dat <= (others => '0');
    rd_ack_int <= '1';
    gpios_axi4_rd <= '0';
    case wb_i.adr(6 downto 6) is
    when "0" => 
      case wb_i.adr(5 downto 2) is
      when "0000" => 
        -- inputs
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when "0001" => 
        -- outputs
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
      end case;
    when "1" => 
      -- Submap gpios_axi4
      gpios_axi4_rd <= rd_int;
      wb_o.dat <= gpios_axi4_rdata_i;
      rd_ack_int <= gpios_axi4_rvalid_i;
    when others =>
    end case;
  end process;
end syn;
