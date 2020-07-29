library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity m1 is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(13 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- CERN-BE bus m0
    m0_VMEAddr_o         : out   std_logic_vector(12 downto 2);
    m0_VMERdData_i       : in    std_logic_vector(31 downto 0);
    m0_VMEWrData_o       : out   std_logic_vector(31 downto 0);
    m0_VMERdMem_o        : out   std_logic;
    m0_VMEWrMem_o        : out   std_logic;
    m0_VMERdDone_i       : in    std_logic;
    m0_VMEWrDone_i       : in    std_logic;

    -- CERN-BE bus m1
    m1_VMEAddr_o         : out   std_logic_vector(11 downto 2);
    m1_VMERdData_i       : in    std_logic_vector(31 downto 0);
    m1_VMEWrData_o       : out   std_logic_vector(31 downto 0);
    m1_VMERdMem_o        : out   std_logic;
    m1_VMEWrMem_o        : out   std_logic;
    m1_VMERdDone_i       : in    std_logic;
    m1_VMEWrDone_i       : in    std_logic;

    -- CERN-BE bus m2
    m2_VMEAddr_o         : out   std_logic_vector(10 downto 2);
    m2_VMERdData_i       : in    std_logic_vector(31 downto 0);
    m2_VMEWrData_o       : out   std_logic_vector(31 downto 0);
    m2_VMERdMem_o        : out   std_logic;
    m2_VMEWrMem_o        : out   std_logic;
    m2_VMERdDone_i       : in    std_logic;
    m2_VMEWrDone_i       : in    std_logic
  );
end m1;

architecture syn of m1 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(13 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
  signal m0_ws                          : std_logic;
  signal m0_wt                          : std_logic;
  signal m1_ws                          : std_logic;
  signal m1_wt                          : std_logic;
  signal m2_ws                          : std_logic;
  signal m2_wt                          : std_logic;
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

  -- Interface m0
  m0_VMEWrData_o <= wr_dat_d0;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        m0_wt <= '0';
      else
        m0_wt <= (m0_wt or m0_ws) and not m0_VMEWrDone_i;
      end if;
    end if;
  end process;
  m0_ws <= wr_req_d0 or (m0_wt and not rd_req_int);
  process (wb_adr_i, wr_adr_d0, m0_wt, m0_ws) begin
    if (m0_ws or m0_wt) = '1' then
      m0_VMEAddr_o <= wr_adr_d0(12 downto 2);
    else
      m0_VMEAddr_o <= wb_adr_i(12 downto 2);
    end if;
  end process;

  -- Interface m1
  m1_VMEWrData_o <= wr_dat_d0;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        m1_wt <= '0';
      else
        m1_wt <= (m1_wt or m1_ws) and not m1_VMEWrDone_i;
      end if;
    end if;
  end process;
  m1_ws <= wr_req_d0 or (m1_wt and not rd_req_int);
  process (wb_adr_i, wr_adr_d0, m1_wt, m1_ws) begin
    if (m1_ws or m1_wt) = '1' then
      m1_VMEAddr_o <= wr_adr_d0(11 downto 2);
    else
      m1_VMEAddr_o <= wb_adr_i(11 downto 2);
    end if;
  end process;

  -- Interface m2
  m2_VMEWrData_o <= wr_dat_d0;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        m2_wt <= '0';
      else
        m2_wt <= (m2_wt or m2_ws) and not m2_VMEWrDone_i;
      end if;
    end if;
  end process;
  m2_ws <= wr_req_d0 or (m2_wt and not rd_req_int);
  process (wb_adr_i, wr_adr_d0, m2_wt, m2_ws) begin
    if (m2_ws or m2_wt) = '1' then
      m2_VMEAddr_o <= wr_adr_d0(10 downto 2);
    else
      m2_VMEAddr_o <= wb_adr_i(10 downto 2);
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, m0_VMEWrDone_i, m1_VMEWrDone_i, m2_VMEWrDone_i) begin
    m0_VMEWrMem_o <= '0';
    m1_VMEWrMem_o <= '0';
    m2_VMEWrMem_o <= '0';
    case wr_adr_d0(13 downto 13) is
    when "0" =>
      -- Memory m0
      m0_VMEWrMem_o <= wr_req_d0;
      wr_ack_int <= m0_VMEWrDone_i;
    when "1" =>
      case wr_adr_d0(12 downto 12) is
      when "0" =>
        -- Memory m1
        m1_VMEWrMem_o <= wr_req_d0;
        wr_ack_int <= m1_VMEWrDone_i;
      when "1" =>
        -- Memory m2
        m2_VMEWrMem_o <= wr_req_d0;
        wr_ack_int <= m2_VMEWrDone_i;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, m0_VMERdData_i, m0_VMERdDone_i, m1_VMERdData_i, m1_VMERdDone_i, m2_VMERdData_i, m2_VMERdDone_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    m0_VMERdMem_o <= '0';
    m1_VMERdMem_o <= '0';
    m2_VMERdMem_o <= '0';
    case wb_adr_i(13 downto 13) is
    when "0" =>
      -- Memory m0
      m0_VMERdMem_o <= rd_req_int;
      rd_dat_d0 <= m0_VMERdData_i;
      rd_ack_d0 <= m0_VMERdDone_i;
    when "1" =>
      case wb_adr_i(12 downto 12) is
      when "0" =>
        -- Memory m1
        m1_VMERdMem_o <= rd_req_int;
        rd_dat_d0 <= m1_VMERdData_i;
        rd_ack_d0 <= m1_VMERdDone_i;
      when "1" =>
        -- Memory m2
        m2_VMERdMem_o <= rd_req_int;
        rd_dat_d0 <= m2_VMERdData_i;
        rd_ack_d0 <= m2_VMERdDone_i;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
