-- Do not edit.  Generated on Thu Mar 19 17:36:04 2020 by gingold
-- With Cheby 1.4.dev0 and these options:
--  --gen-hdl=reg2_wb.vhdl -i reg2_wb.cheby


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg2_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(4 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG reg1
    reg1_o               : out   std_logic_vector(31 downto 0);

    -- REG reg2
    reg2_o               : out   std_logic_vector(31 downto 0);
    reg2_wr_o            : out   std_logic;

    -- REG rwo
    rwo_o                : out   std_logic_vector(31 downto 0);

    -- REG rwo_st
    rwo_st_o             : out   std_logic_vector(31 downto 0);
    rwo_st_wr_o          : out   std_logic;

    -- REG rwo_sa
    rwo_sa_o             : out   std_logic_vector(31 downto 0);
    rwo_sa_wr_o          : out   std_logic;
    rwo_sa_wack_i        : in    std_logic;

    -- REG wwo_st
    wwo_st_o             : out   std_logic_vector(31 downto 0);
    wwo_st_wr_o          : out   std_logic;

    -- REG wwo_sa
    wwo_sa_o             : out   std_logic_vector(31 downto 0);
    wwo_sa_wr_o          : out   std_logic;
    wwo_sa_wack_i        : in    std_logic
  );
end reg2_wb;

architecture syn of reg2_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal reg1_reg                       : std_logic_vector(31 downto 0);
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal reg2_reg                       : std_logic_vector(31 downto 0);
  signal reg2_wreq                      : std_logic;
  signal reg2_wack                      : std_logic;
  signal rwo_reg                        : std_logic_vector(31 downto 0);
  signal rwo_wreq                       : std_logic;
  signal rwo_wack                       : std_logic;
  signal rwo_st_reg                     : std_logic_vector(31 downto 0);
  signal rwo_st_wreq                    : std_logic;
  signal rwo_st_wack                    : std_logic;
  signal rwo_sa_reg                     : std_logic_vector(31 downto 0);
  signal rwo_sa_wreq                    : std_logic;
  signal rwo_sa_wack                    : std_logic;
  signal wwo_st_wreq                    : std_logic;
  signal wwo_sa_wreq                    : std_logic;
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

  -- Register reg1
  reg1_o <= reg1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg1_reg <= "10101011110011010001001000110100";
        reg1_wack <= '0';
      else
        if reg1_wreq = '1' then
          reg1_reg <= wb_dat_i;
        end if;
        reg1_wack <= reg1_wreq;
      end if;
    end if;
  end process;

  -- Register reg2
  reg2_o <= reg2_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg2_reg <= "10101011110011010001000000000100";
        reg2_wack <= '0';
      else
        if reg2_wreq = '1' then
          reg2_reg <= wb_dat_i;
        end if;
        reg2_wack <= reg2_wreq;
      end if;
    end if;
  end process;
  reg2_wr_o <= reg2_wack;

  -- Register rwo
  rwo_o <= rwo_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rwo_reg <= "00000000000000000000000000000000";
        rwo_wack <= '0';
      else
        if rwo_wreq = '1' then
          rwo_reg <= wb_dat_i;
        end if;
        rwo_wack <= rwo_wreq;
      end if;
    end if;
  end process;

  -- Register rwo_st
  rwo_st_o <= rwo_st_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rwo_st_reg <= "00000000000000000000000000000000";
        rwo_st_wack <= '0';
      else
        if rwo_st_wreq = '1' then
          rwo_st_reg <= wb_dat_i;
        end if;
        rwo_st_wack <= rwo_st_wreq;
      end if;
    end if;
  end process;
  rwo_st_wr_o <= rwo_st_wack;

  -- Register rwo_sa
  rwo_sa_o <= rwo_sa_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rwo_sa_reg <= "00000000000000000000000000000000";
        rwo_sa_wack <= '0';
      else
        if rwo_sa_wreq = '1' then
          rwo_sa_reg <= wb_dat_i;
        end if;
        rwo_sa_wack <= rwo_sa_wreq;
      end if;
    end if;
  end process;
  rwo_sa_wr_o <= rwo_sa_wack;

  -- Register wwo_st
  wwo_st_o <= wb_dat_i;
  wwo_st_wr_o <= wwo_st_wreq;

  -- Register wwo_sa
  wwo_sa_o <= wb_dat_i;
  wwo_sa_wr_o <= wwo_sa_wreq;

  -- Process for write requests.
  process (wb_adr_i, wr_req_int, reg1_wack, reg2_wack, rwo_wack, rwo_st_wack, rwo_sa_wack_i, wwo_sa_wack_i) begin
    reg1_wreq <= '0';
    reg2_wreq <= '0';
    rwo_wreq <= '0';
    rwo_st_wreq <= '0';
    rwo_sa_wreq <= '0';
    wwo_st_wreq <= '0';
    wwo_sa_wreq <= '0';
    case wb_adr_i(4 downto 2) is
    when "000" => 
      -- Reg reg1
      reg1_wreq <= wr_req_int;
      wr_ack_int <= reg1_wack;
    when "001" => 
      -- Reg reg2
      reg2_wreq <= wr_req_int;
      wr_ack_int <= reg2_wack;
    when "010" => 
      -- Reg rwo
      rwo_wreq <= wr_req_int;
      wr_ack_int <= rwo_wack;
    when "011" => 
      -- Reg rwo_st
      rwo_st_wreq <= wr_req_int;
      wr_ack_int <= rwo_st_wack;
    when "100" => 
      -- Reg rwo_sa
      rwo_sa_wreq <= wr_req_int;
      wr_ack_int <= rwo_sa_wack_i;
    when "101" => 
      -- Reg wwo_st
      wwo_st_wreq <= wr_req_int;
      wr_ack_int <= wr_req_int;
    when "110" => 
      -- Reg wwo_sa
      wwo_sa_wreq <= wr_req_int;
      wr_ack_int <= wwo_sa_wack_i;
    when others =>
      wr_ack_int <= wr_req_int;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, reg1_reg, reg2_reg) begin
    -- By default ack read requests
    wb_dat_o <= (others => 'X');
    case wb_adr_i(4 downto 2) is
    when "000" => 
      -- Reg reg1
      rd_ack_int <= rd_req_int;
      wb_dat_o <= reg1_reg;
    when "001" => 
      -- Reg reg2
      rd_ack_int <= rd_req_int;
      wb_dat_o <= reg2_reg;
    when "010" => 
      -- Reg rwo
      rd_ack_int <= rd_req_int;
    when "011" => 
      -- Reg rwo_st
      rd_ack_int <= rd_req_int;
    when "100" => 
      -- Reg rwo_sa
      rd_ack_int <= rd_req_int;
    when "101" => 
      -- Reg wwo_st
      rd_ack_int <= rd_req_int;
    when "110" => 
      -- Reg wwo_sa
      rd_ack_int <= rd_req_int;
    when others =>
      rd_ack_int <= rd_req_int;
    end case;
  end process;
end syn;
