library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg6ac_wb is
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
    reg2_f1_o            : out   std_logic;
    reg2_f2_o            : out   std_logic_vector(1 downto 0);

    -- REG reg3
    reg3_f1_o            : out   std_logic;
    reg3_f2_o            : out   std_logic_vector(3 downto 0);
    reg3_f3_o            : out   std_logic_vector(3 downto 0)
  );
end reg6ac_wb;

architecture syn of reg6ac_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal reg1_reg                       : std_logic_vector(31 downto 0) := "00000000000000000000000000010000";
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal reg2_f1_reg                    : std_logic;
  signal reg2_f2_reg                    : std_logic_vector(1 downto 0);
  signal reg2_wreq                      : std_logic;
  signal reg2_wack                      : std_logic;
  signal reg3_f1_reg                    : std_logic;
  signal reg3_f2_reg                    : std_logic_vector(3 downto 0);
  signal reg3_f3_reg                    : std_logic_vector(3 downto 0);
  signal reg3_wreq                      : std_logic_vector(1 downto 0);
  signal reg3_wack                      : std_logic_vector(1 downto 0);
  signal rd_ack_d0                      : std_logic;
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
        wr_adr_d0 <= "00";
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

  -- Register reg1
  reg1_o <= reg1_reg;
  reg1_wack <= reg1_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg1_reg <= "00000000000000000000000000010000";
      else
        if reg1_wreq = '1' then
          reg1_reg <= wr_dat_d0;
        else
          reg1_reg <= "00000000000000000000000000000000";
        end if;
      end if;
    end if;
  end process;

  -- Register reg2
  reg2_f1_o <= reg2_f1_reg;
  reg2_f2_o <= reg2_f2_reg;
  reg2_wack <= reg2_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg2_f1_reg <= '0';
        reg2_f2_reg <= "00";
      else
        if reg2_wreq = '1' then
          reg2_f1_reg <= wr_dat_d0(0);
          reg2_f2_reg <= wr_dat_d0(17 downto 16);
        else
          reg2_f1_reg <= '0';
          reg2_f2_reg <= "00";
        end if;
      end if;
    end if;
  end process;

  -- Register reg3
  reg3_f1_o <= reg3_f1_reg;
  reg3_f2_o <= reg3_f2_reg;
  reg3_f3_o <= reg3_f3_reg;
  reg3_wack <= reg3_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg3_f1_reg <= '0';
        reg3_f2_reg <= "0000";
        reg3_f3_reg <= "0000";
      else
        if reg3_wreq(0) = '1' then
          reg3_f1_reg <= wr_dat_d0(0);
          reg3_f2_reg <= wr_dat_d0(23 downto 20);
        else
          reg3_f1_reg <= '0';
          reg3_f2_reg <= "0000";
        end if;
        if reg3_wreq(1) = '1' then
          reg3_f3_reg <= wr_dat_d0(31 downto 28);
        else
          reg3_f3_reg <= "0000";
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg1_wack, reg2_wack, reg3_wack) begin
    reg1_wreq <= '0';
    reg2_wreq <= '0';
    reg3_wreq <= (others => '0');
    case wr_adr_d0(3 downto 3) is
    when "0" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg reg1
        reg1_wreq <= wr_req_d0;
        wr_ack_int <= reg1_wack;
      when "1" =>
        -- Reg reg2
        reg2_wreq <= wr_req_d0;
        wr_ack_int <= reg2_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "1" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg reg3
        reg3_wreq(1) <= wr_req_d0;
        wr_ack_int <= reg3_wack(1);
      when "1" =>
        -- Reg reg3
        reg3_wreq(0) <= wr_req_d0;
        wr_ack_int <= reg3_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(3 downto 3) is
    when "0" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg reg1
        rd_ack_d0 <= rd_req_int;
      when "1" =>
        -- Reg reg2
        rd_ack_d0 <= rd_req_int;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "1" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg reg3
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(27 downto 0) <= (others => '0');
        rd_dat_d0(31 downto 28) <= "0000";
      when "1" =>
        -- Reg reg3
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(19 downto 1) <= (others => '0');
        rd_dat_d0(23 downto 20) <= "0000";
        rd_dat_d0(31 downto 24) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
