library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buserr_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(3 downto 2);
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

    -- REG reg3
    reg3_o               : out   std_logic_vector(31 downto 0)
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
  signal reg1_reg                       : std_logic_vector(31 downto 0);
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal reg2_reg                       : std_logic_vector(31 downto 0);
  signal reg2_wreq                      : std_logic;
  signal reg2_wack                      : std_logic;
  signal reg3_reg                       : std_logic_vector(31 downto 0);
  signal reg3_wreq                      : std_logic;
  signal reg3_wack                      : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_err_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(3 downto 2);
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
        wr_req_d0 <= '0';
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

  -- Register reg1
  reg1_o <= reg1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg1_reg <= "00010010001101000101011001111000";
        reg1_wack <= '0';
      else
        if reg1_wreq = '1' then
          reg1_reg <= wr_dat_d0;
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
        reg2_reg <= "00010010001101000101011001111000";
        reg2_wack <= '0';
      else
        if reg2_wreq = '1' then
          reg2_reg <= wr_dat_d0;
        end if;
        reg2_wack <= reg2_wreq;
      end if;
    end if;
  end process;

  -- Register reg3
  reg3_o <= reg3_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg3_reg <= "00010010001101000101011001111000";
        reg3_wack <= '0';
      else
        if reg3_wreq = '1' then
          reg3_reg <= wr_dat_d0;
        end if;
        reg3_wack <= reg3_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg1_wack, reg2_wack, reg3_wack) begin
    reg1_wreq <= '0';
    reg2_wreq <= '0';
    reg3_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg reg1
      reg1_wreq <= wr_req_d0;
      wr_ack_int <= reg1_wack;
      wr_err_int <= '0';
    when "01" =>
      -- Reg reg2
      reg2_wreq <= wr_req_d0;
      wr_ack_int <= reg2_wack;
      wr_err_int <= '0';
    when "10" =>
      -- Reg reg3
      reg3_wreq <= wr_req_d0;
      wr_ack_int <= reg3_wack;
      wr_err_int <= '0';
    when others =>
      wr_ack_int <= wr_req_d0;
      wr_err_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, reg1_reg, reg2_reg, reg3_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(3 downto 2) is
    when "00" =>
      -- Reg reg1
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= '0';
      rd_dat_d0 <= reg1_reg;
    when "01" =>
      -- Reg reg2
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= '0';
      rd_dat_d0 <= reg2_reg;
    when "10" =>
      -- Reg reg3
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= '0';
      rd_dat_d0 <= reg3_reg;
    when others =>
      rd_ack_d0 <= rd_req_int;
      rd_err_d0 <= rd_req_int;
    end case;
  end process;
end syn;
