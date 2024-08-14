library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity blkprefix3 is
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

    -- REG r1
    b1_r1_f1_o           : out   std_logic_vector(2 downto 0);
    b1_r1_f2_o           : out   std_logic;

    -- REG r2
    b1_r2_o              : out   std_logic_vector(63 downto 0);

    -- REG r3
    b1_r3_f1_o           : out   std_logic_vector(2 downto 0);
    b1_r3_f2_o           : out   std_logic;

    -- REG r4
    b1_r4_o              : out   std_logic_vector(63 downto 0);

    -- REG r1
    b2_r1_f1_o           : out   std_logic_vector(2 downto 0);

    -- REG r2
    b2_r2_o              : out   std_logic_vector(63 downto 0)
  );
end blkprefix3;

architecture syn of blkprefix3 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal b1_r1_f1_reg                   : std_logic_vector(2 downto 0);
  signal b1_r1_f2_reg                   : std_logic;
  signal b1_r1_wreq                     : std_logic;
  signal b1_r1_wack                     : std_logic;
  signal b1_r2_reg                      : std_logic_vector(63 downto 0);
  signal b1_r2_wreq                     : std_logic_vector(1 downto 0);
  signal b1_r2_wack                     : std_logic_vector(1 downto 0);
  signal b1_b11_r3_f1_reg               : std_logic_vector(2 downto 0);
  signal b1_b11_r3_f2_reg               : std_logic;
  signal b1_r3_wreq                     : std_logic;
  signal b1_r3_wack                     : std_logic;
  signal b1_b11_r4_reg                  : std_logic_vector(63 downto 0);
  signal b1_r4_wreq                     : std_logic_vector(1 downto 0);
  signal b1_r4_wack                     : std_logic_vector(1 downto 0);
  signal b2_r1_f1_reg                   : std_logic_vector(2 downto 0);
  signal b2_r1_wreq                     : std_logic;
  signal b2_r1_wack                     : std_logic;
  signal b2_r2_reg                      : std_logic_vector(63 downto 0);
  signal b2_r2_wreq                     : std_logic_vector(1 downto 0);
  signal b2_r2_wack                     : std_logic_vector(1 downto 0);
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
        wb_dat_o <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "0000";
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

  -- Register b1_r1
  b1_r1_f1_o <= b1_r1_f1_reg;
  b1_r1_f2_o <= b1_r1_f2_reg;
  b1_r1_wack <= b1_r1_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        b1_r1_f1_reg <= "000";
        b1_r1_f2_reg <= '0';
      else
        if b1_r1_wreq = '1' then
          b1_r1_f1_reg <= wr_dat_d0(2 downto 0);
          b1_r1_f2_reg <= wr_dat_d0(4);
        end if;
      end if;
    end if;
  end process;

  -- Register b1_r2
  b1_r2_o <= b1_r2_reg;
  b1_r2_wack <= b1_r2_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        b1_r2_reg <= "0000000000000000000000000000000000000000000000000000000000000000";
      else
        if b1_r2_wreq(0) = '1' then
          b1_r2_reg(31 downto 0) <= wr_dat_d0;
        end if;
        if b1_r2_wreq(1) = '1' then
          b1_r2_reg(63 downto 32) <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register b1_r3
  b1_r3_f1_o <= b1_b11_r3_f1_reg;
  b1_r3_f2_o <= b1_b11_r3_f2_reg;
  b1_r3_wack <= b1_r3_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        b1_b11_r3_f1_reg <= "000";
        b1_b11_r3_f2_reg <= '0';
      else
        if b1_r3_wreq = '1' then
          b1_b11_r3_f1_reg <= wr_dat_d0(2 downto 0);
          b1_b11_r3_f2_reg <= wr_dat_d0(4);
        end if;
      end if;
    end if;
  end process;

  -- Register b1_r4
  b1_r4_o <= b1_b11_r4_reg;
  b1_r4_wack <= b1_r4_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        b1_b11_r4_reg <= "0000000000000000000000000000000000000000000000000000000000000000";
      else
        if b1_r4_wreq(0) = '1' then
          b1_b11_r4_reg(31 downto 0) <= wr_dat_d0;
        end if;
        if b1_r4_wreq(1) = '1' then
          b1_b11_r4_reg(63 downto 32) <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register b2_r1
  b2_r1_f1_o <= b2_r1_f1_reg;
  b2_r1_wack <= b2_r1_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        b2_r1_f1_reg <= "000";
      else
        if b2_r1_wreq = '1' then
          b2_r1_f1_reg <= wr_dat_d0(2 downto 0);
        end if;
      end if;
    end if;
  end process;

  -- Register b2_r2
  b2_r2_o <= b2_r2_reg;
  b2_r2_wack <= b2_r2_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        b2_r2_reg <= "0000000000000000000000000000000000000000000000000000000000000000";
      else
        if b2_r2_wreq(0) = '1' then
          b2_r2_reg(31 downto 0) <= wr_dat_d0;
        end if;
        if b2_r2_wreq(1) = '1' then
          b2_r2_reg(63 downto 32) <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, b1_r1_wack, b1_r2_wack, b1_r3_wack, b1_r4_wack,
           b2_r1_wack, b2_r2_wack) begin
    b1_r1_wreq <= '0';
    b1_r2_wreq <= (others => '0');
    b1_r3_wreq <= '0';
    b1_r4_wreq <= (others => '0');
    b2_r1_wreq <= '0';
    b2_r2_wreq <= (others => '0');
    case wr_adr_d0(5 downto 3) is
    when "000" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg b1_r1
        b1_r1_wreq <= wr_req_d0;
        wr_ack_int <= b1_r1_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "001" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg b1_r2
        b1_r2_wreq(1) <= wr_req_d0;
        wr_ack_int <= b1_r2_wack(1);
      when "1" =>
        -- Reg b1_r2
        b1_r2_wreq(0) <= wr_req_d0;
        wr_ack_int <= b1_r2_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "010" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg b1_r3
        b1_r3_wreq <= wr_req_d0;
        wr_ack_int <= b1_r3_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "011" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg b1_r4
        b1_r4_wreq(1) <= wr_req_d0;
        wr_ack_int <= b1_r4_wack(1);
      when "1" =>
        -- Reg b1_r4
        b1_r4_wreq(0) <= wr_req_d0;
        wr_ack_int <= b1_r4_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "100" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg b2_r1
        b2_r1_wreq <= wr_req_d0;
        wr_ack_int <= b2_r1_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "101" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg b2_r2
        b2_r2_wreq(1) <= wr_req_d0;
        wr_ack_int <= b2_r2_wack(1);
      when "1" =>
        -- Reg b2_r2
        b2_r2_wreq(0) <= wr_req_d0;
        wr_ack_int <= b2_r2_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, b1_r1_f1_reg, b1_r1_f2_reg, b1_r2_reg,
           b1_b11_r3_f1_reg, b1_b11_r3_f2_reg, b1_b11_r4_reg, b2_r1_f1_reg,
           b2_r2_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(5 downto 3) is
    when "000" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg b1_r1
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(2 downto 0) <= b1_r1_f1_reg;
        rd_dat_d0(3) <= '0';
        rd_dat_d0(4) <= b1_r1_f2_reg;
        rd_dat_d0(31 downto 5) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "001" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg b1_r2
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= b1_r2_reg(63 downto 32);
      when "1" =>
        -- Reg b1_r2
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= b1_r2_reg(31 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "010" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg b1_r3
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(2 downto 0) <= b1_b11_r3_f1_reg;
        rd_dat_d0(3) <= '0';
        rd_dat_d0(4) <= b1_b11_r3_f2_reg;
        rd_dat_d0(31 downto 5) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "011" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg b1_r4
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= b1_b11_r4_reg(63 downto 32);
      when "1" =>
        -- Reg b1_r4
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= b1_b11_r4_reg(31 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "100" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg b2_r1
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(2 downto 0) <= b2_r1_f1_reg;
        rd_dat_d0(31 downto 3) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "101" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg b2_r2
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= b2_r2_reg(63 downto 32);
      when "1" =>
        -- Reg b2_r2
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= b2_r2_reg(31 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
