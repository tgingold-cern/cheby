library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wires1 is
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

    strobe_o             : out   std_logic_vector(31 downto 0);
    strobe_wr_o          : out   std_logic;
    strobe_rd_o          : out   std_logic;

    wires_i              : in    std_logic_vector(31 downto 0);
    wires_o              : out   std_logic_vector(31 downto 0);
    wires_rd_o           : out   std_logic;

    acks_i               : in    std_logic_vector(31 downto 0);
    acks_o               : out   std_logic_vector(31 downto 0);
    acks_wr_o            : out   std_logic;
    acks_rd_o            : out   std_logic;
    acks_wack_i          : in    std_logic;
    acks_rack_i          : in    std_logic
  );
end wires1;

architecture syn of wires1 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal strobe_reg                     : std_logic_vector(31 downto 0);
  signal strobe_wreq                    : std_logic;
  signal strobe_wack                    : std_logic;
  signal wires_wreq                     : std_logic;
  signal acks_wreq                      : std_logic;
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

  -- Register strobe
  strobe_o <= strobe_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        strobe_reg <= "00000000000000000000000000000000";
        strobe_wack <= '0';
      else
        if strobe_wreq = '1' then
          strobe_reg <= wr_dat_d0;
        end if;
        strobe_wack <= strobe_wreq;
      end if;
    end if;
  end process;
  strobe_wr_o <= strobe_wack;

  -- Register wires
  wires_o <= wr_dat_d0;

  -- Register acks
  acks_o <= wr_dat_d0;
  acks_wr_o <= acks_wreq;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, strobe_wack, acks_wack_i) begin
    strobe_wreq <= '0';
    wires_wreq <= '0';
    acks_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" => 
      -- strobe
      strobe_wreq <= wr_req_d0;
      wr_ack_int <= strobe_wack;
    when "01" => 
      -- wires
      wires_wreq <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "10" => 
      -- acks
      acks_wreq <= wr_req_d0;
      wr_ack_int <= acks_wack_i;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, strobe_reg, wires_i, acks_rack_i, acks_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    strobe_rd_o <= '0';
    wires_rd_o <= '0';
    acks_rd_o <= '0';
    case wb_adr_i(3 downto 2) is
    when "00" => 
      -- strobe
      strobe_rd_o <= rd_req_int;
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= strobe_reg;
    when "01" => 
      -- wires
      wires_rd_o <= rd_req_int;
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= wires_i;
    when "10" => 
      -- acks
      acks_rd_o <= rd_req_int;
      rd_ack_d0 <= acks_rack_i;
      rd_dat_d0 <= acks_i;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
