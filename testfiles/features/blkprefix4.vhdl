library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity blkprefix4 is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(5 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG r5
    r5_o                 : out   std_logic_vector(31 downto 0);

    -- REG r1
    sub1_r1_o            : out   std_logic_vector(31 downto 0);

    -- REG r2
    sub1_b1_r2_o         : out   std_logic_vector(31 downto 0);

    -- REG r3
    sub1_b2_r3_o         : out   std_logic_vector(31 downto 0);

    -- REG r1
    sub2_r1_o            : out   std_logic_vector(31 downto 0);

    -- REG r2
    sub2_b1_r2_o         : out   std_logic_vector(31 downto 0);

    -- REG r3
    sub2_b2_r3_o         : out   std_logic_vector(31 downto 0)
  );
end blkprefix4;

architecture syn of blkprefix4 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal r5_reg                         : std_logic_vector(31 downto 0);
  signal r5_wreq                        : std_logic;
  signal r5_wack                        : std_logic;
  signal blk_sub1_r1_reg                : std_logic_vector(31 downto 0);
  signal sub1_r1_wreq                   : std_logic;
  signal sub1_r1_wack                   : std_logic;
  signal blk_sub1_b1_r2_reg             : std_logic_vector(31 downto 0);
  signal sub1_b1_r2_wreq                : std_logic;
  signal sub1_b1_r2_wack                : std_logic;
  signal blk_sub1_b2_r3_reg             : std_logic_vector(31 downto 0);
  signal sub1_b2_r3_wreq                : std_logic;
  signal sub1_b2_r3_wack                : std_logic;
  signal blk_sub2_r1_reg                : std_logic_vector(31 downto 0);
  signal sub2_r1_wreq                   : std_logic;
  signal sub2_r1_wack                   : std_logic;
  signal blk_sub2_b1_r2_reg             : std_logic_vector(31 downto 0);
  signal sub2_b1_r2_wreq                : std_logic;
  signal sub2_b1_r2_wack                : std_logic;
  signal blk_sub2_b2_r3_reg             : std_logic_vector(31 downto 0);
  signal sub2_b2_r3_wreq                : std_logic;
  signal sub2_b2_r3_wack                : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(5 downto 2);
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
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register r5
  r5_o <= r5_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        r5_reg <= "00000000000000000000000000000000";
        r5_wack <= '0';
      else
        if r5_wreq = '1' then
          r5_reg <= wr_dat_d0;
        end if;
        r5_wack <= r5_wreq;
      end if;
    end if;
  end process;

  -- Register sub1_r1
  sub1_r1_o <= blk_sub1_r1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_sub1_r1_reg <= "00000000000000000000000000000000";
        sub1_r1_wack <= '0';
      else
        if sub1_r1_wreq = '1' then
          blk_sub1_r1_reg <= wr_dat_d0;
        end if;
        sub1_r1_wack <= sub1_r1_wreq;
      end if;
    end if;
  end process;

  -- Register sub1_b1_r2
  sub1_b1_r2_o <= blk_sub1_b1_r2_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_sub1_b1_r2_reg <= "00000000000000000000000000000000";
        sub1_b1_r2_wack <= '0';
      else
        if sub1_b1_r2_wreq = '1' then
          blk_sub1_b1_r2_reg <= wr_dat_d0;
        end if;
        sub1_b1_r2_wack <= sub1_b1_r2_wreq;
      end if;
    end if;
  end process;

  -- Register sub1_b2_r3
  sub1_b2_r3_o <= blk_sub1_b2_r3_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_sub1_b2_r3_reg <= "00000000000000000000000000000000";
        sub1_b2_r3_wack <= '0';
      else
        if sub1_b2_r3_wreq = '1' then
          blk_sub1_b2_r3_reg <= wr_dat_d0;
        end if;
        sub1_b2_r3_wack <= sub1_b2_r3_wreq;
      end if;
    end if;
  end process;

  -- Register sub2_r1
  sub2_r1_o <= blk_sub2_r1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_sub2_r1_reg <= "00000000000000000000000000000000";
        sub2_r1_wack <= '0';
      else
        if sub2_r1_wreq = '1' then
          blk_sub2_r1_reg <= wr_dat_d0;
        end if;
        sub2_r1_wack <= sub2_r1_wreq;
      end if;
    end if;
  end process;

  -- Register sub2_b1_r2
  sub2_b1_r2_o <= blk_sub2_b1_r2_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_sub2_b1_r2_reg <= "00000000000000000000000000000000";
        sub2_b1_r2_wack <= '0';
      else
        if sub2_b1_r2_wreq = '1' then
          blk_sub2_b1_r2_reg <= wr_dat_d0;
        end if;
        sub2_b1_r2_wack <= sub2_b1_r2_wreq;
      end if;
    end if;
  end process;

  -- Register sub2_b2_r3
  sub2_b2_r3_o <= blk_sub2_b2_r3_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_sub2_b2_r3_reg <= "00000000000000000000000000000000";
        sub2_b2_r3_wack <= '0';
      else
        if sub2_b2_r3_wreq = '1' then
          blk_sub2_b2_r3_reg <= wr_dat_d0;
        end if;
        sub2_b2_r3_wack <= sub2_b2_r3_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, r5_wack, sub1_r1_wack, sub1_b1_r2_wack,
           sub1_b2_r3_wack, sub2_r1_wack, sub2_b1_r2_wack, sub2_b2_r3_wack) begin
    r5_wreq <= '0';
    sub1_r1_wreq <= '0';
    sub1_b1_r2_wreq <= '0';
    sub1_b2_r3_wreq <= '0';
    sub2_r1_wreq <= '0';
    sub2_b1_r2_wreq <= '0';
    sub2_b2_r3_wreq <= '0';
    case wr_adr_d0(5 downto 2) is
    when "0000" =>
      -- Reg r5
      r5_wreq <= wr_req_d0;
      wr_ack_int <= r5_wack;
    when "1000" =>
      -- Reg sub1_r1
      sub1_r1_wreq <= wr_req_d0;
      wr_ack_int <= sub1_r1_wack;
    when "1001" =>
      -- Reg sub1_b1_r2
      sub1_b1_r2_wreq <= wr_req_d0;
      wr_ack_int <= sub1_b1_r2_wack;
    when "1010" =>
      -- Reg sub1_b2_r3
      sub1_b2_r3_wreq <= wr_req_d0;
      wr_ack_int <= sub1_b2_r3_wack;
    when "1100" =>
      -- Reg sub2_r1
      sub2_r1_wreq <= wr_req_d0;
      wr_ack_int <= sub2_r1_wack;
    when "1101" =>
      -- Reg sub2_b1_r2
      sub2_b1_r2_wreq <= wr_req_d0;
      wr_ack_int <= sub2_b1_r2_wack;
    when "1110" =>
      -- Reg sub2_b2_r3
      sub2_b2_r3_wreq <= wr_req_d0;
      wr_ack_int <= sub2_b2_r3_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, r5_reg, blk_sub1_r1_reg, blk_sub1_b1_r2_reg,
           blk_sub1_b2_r3_reg, blk_sub2_r1_reg, blk_sub2_b1_r2_reg,
           blk_sub2_b2_r3_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(5 downto 2) is
    when "0000" =>
      -- Reg r5
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= r5_reg;
    when "1000" =>
      -- Reg sub1_r1
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_sub1_r1_reg;
    when "1001" =>
      -- Reg sub1_b1_r2
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_sub1_b1_r2_reg;
    when "1010" =>
      -- Reg sub1_b2_r3
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_sub1_b2_r3_reg;
    when "1100" =>
      -- Reg sub2_r1
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_sub2_r1_reg;
    when "1101" =>
      -- Reg sub2_b1_r2
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_sub2_b1_r2_reg;
    when "1110" =>
      -- Reg sub2_b2_r3
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_sub2_b2_r3_reg;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
