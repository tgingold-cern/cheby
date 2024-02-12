library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem64ro is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(7 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- The first register (with some fields)
    -- 1-bit field
    regA_field0_o        : out   std_logic;

    -- SRAM bus ts
    ts_addr_o            : out   std_logic_vector(6 downto 2);
    ts_data_i            : in    std_logic_vector(127 downto 0)
  );
end mem64ro;

architecture syn of mem64ro is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal regA_field0_reg                : std_logic;
  signal regA_wreq                      : std_logic;
  signal regA_wack                      : std_logic;
  signal ts_rack                        : std_logic;
  signal ts_re                          : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(7 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_we_i)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wb_dat_o <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "000000";
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register regA
  regA_field0_o <= regA_field0_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        regA_field0_reg <= '0';
        regA_wack <= '0';
      else
        if regA_wreq = '1' then
          regA_field0_reg <= wr_dat_d0(1);
        end if;
        regA_wack <= regA_wreq;
      end if;
    end if;
  end process;

  -- Interface ts
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ts_rack <= '0';
      else
        ts_rack <= ts_re and not ts_rack;
      end if;
    end if;
  end process;
  ts_addr_o <= wb_adr_i(6 downto 2);

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, regA_wack) begin
    regA_wreq <= '0';
    case wr_adr_d0(7 downto 7) is
    when "0" =>
      case wr_adr_d0(6 downto 2) is
      when "00000" =>
        -- Reg regA
        regA_wreq <= wr_req_d0;
        wr_ack_int <= regA_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "1" =>
      -- Memory ts
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, regA_field0_reg, ts_data_i, ts_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    ts_re <= '0';
    case wb_adr_i(7 downto 7) is
    when "0" =>
      case wb_adr_i(6 downto 2) is
      when "00000" =>
        -- Reg regA
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= regA_field0_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "1" =>
      -- Memory ts
      rd_dat_d0 <= ts_data_i;
      rd_ack_d0 <= ts_rack;
      ts_re <= rd_req_int;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
