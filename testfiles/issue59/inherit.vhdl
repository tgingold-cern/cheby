library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inherit is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG reg0
    reg0_field00_i       : in    std_logic;
    reg0_field00_o       : out   std_logic;
    reg0_field01_o       : out   std_logic_vector(3 downto 0);
    reg0_field02_o       : out   std_logic_vector(2 downto 0);
    reg0_wr_o            : out   std_logic
  );
end inherit;

architecture syn of inherit is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal reg0_field01_reg               : std_logic_vector(3 downto 0);
  signal reg0_field02_reg               : std_logic_vector(2 downto 0);
  signal reg0_wreq                      : std_logic;
  signal reg0_wack                      : std_logic;
  signal reg0_wstrb                     : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
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
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register reg0
  reg0_field00_o <= wr_dat_d0(1);
  reg0_field01_o <= reg0_field01_reg;
  reg0_field02_o <= reg0_field02_reg;
  reg0_wack <= reg0_wreq;
  reg0_wstrb <= reg0_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg0_field01_reg <= "0000";
        reg0_field02_reg <= "010";
      else
        if reg0_wreq = '1' then
          reg0_field01_reg <= wr_dat_d0(7 downto 4);
          reg0_field02_reg <= wr_dat_d0(10 downto 8);
        end if;
      end if;
    end if;
  end process;
  reg0_wr_o <= reg0_wstrb;

  -- Process for write requests.
  process (wr_req_d0, reg0_wack) begin
    reg0_wreq <= '0';
    -- Reg reg0
    reg0_wreq <= wr_req_d0;
    wr_ack_int <= reg0_wack;
  end process;

  -- Process for read requests.
  process (rd_req_int, reg0_field00_i, reg0_field01_reg, reg0_field02_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    -- Reg reg0
    rd_ack_d0 <= rd_req_int;
    rd_dat_d0(0) <= '0';
    rd_dat_d0(1) <= reg0_field00_i;
    rd_dat_d0(3 downto 2) <= (others => '0');
    rd_dat_d0(7 downto 4) <= reg0_field01_reg;
    rd_dat_d0(10 downto 8) <= reg0_field02_reg;
    rd_dat_d0(31 downto 11) <= (others => '0');
  end process;
end syn;
