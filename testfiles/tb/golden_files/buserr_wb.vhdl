library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buserr_wb is
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

    -- REG rw0
    rw0_o                : out   std_logic_vector(31 downto 0);

    -- REG rw1
    rw1_o                : out   std_logic_vector(31 downto 0);

    -- REG rw2
    rw2_o                : out   std_logic_vector(31 downto 0);

    -- REG ro0
    ro0_i                : in    std_logic_vector(31 downto 0);

    -- REG wo0
    wo0_o                : out   std_logic_vector(31 downto 0)
  );
end buserr_wb;

architecture syn of buserr_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal rd_err_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wr_err_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal err_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal rw0_reg                        : std_logic_vector(31 downto 0);
  signal rw0_wreq                       : std_logic;
  signal rw0_wack                       : std_logic;
  signal rw1_reg                        : std_logic_vector(31 downto 0);
  signal rw1_wreq                       : std_logic;
  signal rw1_wack                       : std_logic;
  signal rw2_reg                        : std_logic_vector(31 downto 0);
  signal rw2_wreq                       : std_logic;
  signal rw2_wack                       : std_logic;
  signal wo0_reg                        : std_logic_vector(31 downto 0);
  signal wo0_wreq                       : std_logic;
  signal wo0_wack                       : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_err_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(4 downto 2);
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

  process (rd_ack_int, wr_ack_int, ack_int, rd_err_int, wr_err_int, err_int) begin
    ack_int <= rd_ack_int or wr_ack_int;
    err_int <= rd_err_int or wr_err_int;
    if err_int = '0' then
      wb_ack_o <= ack_int;
      wb_err_o <= '0';
    else
      wb_ack_o <= '0';
      wb_err_o <= ack_int;
    end if;
  end process;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        rd_err_int <= '0';
        wb_dat_o <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "000";
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        rd_err_int <= rd_err_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register rw0
  rw0_o <= rw0_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rw0_reg <= "00010010001101000101011001111000";
        rw0_wack <= '0';
      else
        if rw0_wreq = '1' then
          rw0_reg <= wr_dat_d0;
        end if;
        rw0_wack <= rw0_wreq;
      end if;
    end if;
  end process;

  -- Register rw1
  rw1_o <= rw1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rw1_reg <= "00100011010001010110011110001001";
        rw1_wack <= '0';
      else
        if rw1_wreq = '1' then
          rw1_reg <= wr_dat_d0;
        end if;
        rw1_wack <= rw1_wreq;
      end if;
    end if;
  end process;

  -- Register rw2
  rw2_o <= rw2_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rw2_reg <= "00110100010101100111100010011010";
        rw2_wack <= '0';
      else
        if rw2_wreq = '1' then
          rw2_reg <= wr_dat_d0;
        end if;
        rw2_wack <= rw2_wreq;
      end if;
    end if;
  end process;

  -- Register ro0

  -- Register wo0
  wo0_o <= wo0_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wo0_reg <= "01010110011110001001101010111100";
        wo0_wack <= '0';
      else
        if wo0_wreq = '1' then
          wo0_reg <= wr_dat_d0;
        end if;
        wo0_wack <= wo0_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, rw0_wack, rw1_wack, rw2_wack, wo0_wack) begin
    rw0_wreq <= '0';
    rw1_wreq <= '0';
    rw2_wreq <= '0';
    wo0_wreq <= '0';
    case wr_adr_d0(4 downto 2) is
    when "000" =>
      -- Reg rw0
      rw0_wreq <= wr_req_d0;
      wr_ack_int <= rw0_wack;
      wr_err_int <= '0';
    when "001" =>
      -- Reg rw1
      rw1_wreq <= wr_req_d0;
      wr_ack_int <= rw1_wack;
      wr_err_int <= '0';
    when "010" =>
      -- Reg rw2
      rw2_wreq <= wr_req_d0;
      wr_ack_int <= rw2_wack;
      wr_err_int <= '0';
    when "011" =>
      -- Reg ro0
      wr_ack_int <= wr_req_d0;
      wr_err_int <= wr_req_d0;
    when "100" =>
      -- Reg wo0
      wo0_wreq <= wr_req_d0;
      wr_ack_int <= wo0_wack;
      wr_err_int <= '0';
    when others =>
      wr_ack_int <= wr_req_d0;
      wr_err_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, rw0_reg, rw1_reg, rw2_reg, ro0_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(4 downto 2) is
    when "000" =>
      -- Reg rw0
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= '0';
      rd_dat_d0 <= rw0_reg;
    when "001" =>
      -- Reg rw1
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= '0';
      rd_dat_d0 <= rw1_reg;
    when "010" =>
      -- Reg rw2
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= '0';
      rd_dat_d0 <= rw2_reg;
    when "011" =>
      -- Reg ro0
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= '0';
      rd_dat_d0 <= ro0_i;
    when "100" =>
      -- Reg wo0
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= rd_req_int;
    when others =>
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= rd_req_int;
    end case;
  end process;
end syn;
