library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity submap_align1 is
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

    -- REG reg0
    sub0_reg0_o          : out   std_logic_vector(31 downto 0);

    -- REG reg1
    sub0_reg1_o          : out   std_logic_vector(31 downto 0);

    -- REG reg2
    sub0_reg2_o          : out   std_logic_vector(31 downto 0);

    -- REG reg3
    reg3_o               : out   std_logic_vector(31 downto 0)
  );
end submap_align1;

architecture syn of submap_align1 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal sub0_reg0_reg                  : std_logic_vector(31 downto 0);
  signal sub0_reg0_wreq                 : std_logic;
  signal sub0_reg0_wack                 : std_logic;
  signal sub0_reg1_reg                  : std_logic_vector(31 downto 0);
  signal sub0_reg1_wreq                 : std_logic;
  signal sub0_reg1_wack                 : std_logic;
  signal sub0_reg2_reg                  : std_logic_vector(31 downto 0);
  signal sub0_reg2_wreq                 : std_logic;
  signal sub0_reg2_wack                 : std_logic;
  signal reg3_reg                       : std_logic_vector(31 downto 0);
  signal reg3_wreq                      : std_logic;
  signal reg3_wack                      : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(3 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
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
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wb_sel_i;
      end if;
    end if;
  end process;

  -- Register sub0_reg0
  sub0_reg0_o <= sub0_reg0_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sub0_reg0_reg <= "00000000000000000000000000000000";
        sub0_reg0_wack <= '0';
      else
        if sub0_reg0_wreq = '1' then
          sub0_reg0_reg <= wr_dat_d0;
        end if;
        sub0_reg0_wack <= sub0_reg0_wreq;
      end if;
    end if;
  end process;

  -- Register sub0_reg1
  sub0_reg1_o <= sub0_reg1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sub0_reg1_reg <= "00000000000000000000000000000000";
        sub0_reg1_wack <= '0';
      else
        if sub0_reg1_wreq = '1' then
          sub0_reg1_reg <= wr_dat_d0;
        end if;
        sub0_reg1_wack <= sub0_reg1_wreq;
      end if;
    end if;
  end process;

  -- Register sub0_reg2
  sub0_reg2_o <= sub0_reg2_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sub0_reg2_reg <= "00000000000000000000000000000000";
        sub0_reg2_wack <= '0';
      else
        if sub0_reg2_wreq = '1' then
          sub0_reg2_reg <= wr_dat_d0;
        end if;
        sub0_reg2_wack <= sub0_reg2_wreq;
      end if;
    end if;
  end process;

  -- Register reg3
  reg3_o <= reg3_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg3_reg <= "00000000000000000000000000000000";
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
  process (wr_adr_d0, wr_req_d0, sub0_reg0_wack, sub0_reg1_wack, sub0_reg2_wack, reg3_wack) begin
    sub0_reg0_wreq <= '0';
    sub0_reg1_wreq <= '0';
    sub0_reg2_wreq <= '0';
    reg3_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" => 
      -- Reg sub0_reg0
      sub0_reg0_wreq <= wr_req_d0;
      wr_ack_int <= sub0_reg0_wack;
    when "01" => 
      -- Reg sub0_reg1
      sub0_reg1_wreq <= wr_req_d0;
      wr_ack_int <= sub0_reg1_wack;
    when "10" => 
      -- Reg sub0_reg2
      sub0_reg2_wreq <= wr_req_d0;
      wr_ack_int <= sub0_reg2_wack;
    when "11" => 
      -- Reg reg3
      reg3_wreq <= wr_req_d0;
      wr_ack_int <= reg3_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, sub0_reg0_reg, sub0_reg1_reg, sub0_reg2_reg, reg3_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(3 downto 2) is
    when "00" => 
      -- Reg sub0_reg0
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= sub0_reg0_reg;
    when "01" => 
      -- Reg sub0_reg1
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= sub0_reg1_reg;
    when "10" => 
      -- Reg sub0_reg2
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= sub0_reg2_reg;
    when "11" => 
      -- Reg reg3
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= reg3_reg;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
