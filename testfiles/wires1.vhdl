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
  signal rd_int                         : std_logic;
  signal wr_int                         : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal strobe_reg                     : std_logic_vector(31 downto 0);
  signal reg_rdat_int                   : std_logic_vector(31 downto 0);
  signal rd_ack1_int                    : std_logic;
begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;

  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      wb_rip <= '0';
    elsif rising_edge(clk_i) then
      wb_rip <= (wb_rip or (wb_en and not wb_we_i)) and not rd_ack_int;
    end if;
  end process;
  rd_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      wb_wip <= '0';
    elsif rising_edge(clk_i) then
      wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
    end if;
  end process;
  wr_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- Assign outputs
  strobe_o <= strobe_reg;

  -- Process for write requests.
  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      wr_ack_int <= '0';
      strobe_wr_o <= '0';
      strobe_reg <= "00000000000000000000000000000000";
      acks_wr_o <= '0';
    elsif rising_edge(clk_i) then
      wr_ack_int <= '0';
      strobe_wr_o <= '0';
      acks_wr_o <= '0';
      case wb_adr_i(3 downto 2) is
      when "00" => 
        -- Register strobe
        strobe_wr_o <= wr_int;
        if wr_int = '1' then
          strobe_reg <= wb_dat_i;
        end if;
        wr_ack_int <= wr_int;
      when "01" => 
        -- Register wires
        if wr_int = '1' then
          wires_o <= wb_dat_i;
        end if;
        wr_ack_int <= wr_int;
      when "10" => 
        -- Register acks
        acks_wr_o <= wr_int;
        if wr_int = '1' then
          acks_o <= wb_dat_i;
        end if;
        wr_ack_int <= acks_wack_i;
      when others =>
        wr_ack_int <= wr_int;
      end case;
    end if;
  end process;

  -- Process for registers read.
  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      rd_ack1_int <= '0';
      reg_rdat_int <= (others => 'X');
      strobe_rd_o <= '0';
      wires_rd_o <= '0';
      acks_rd_o <= '0';
    elsif rising_edge(clk_i) then
      acks_rd_o <= '0';
      wires_rd_o <= '0';
      strobe_rd_o <= '0';
      reg_rdat_int <= (others => '0');
      case wb_adr_i(3 downto 2) is
      when "00" => 
        -- strobe
        reg_rdat_int <= strobe_reg;
        strobe_rd_o <= '1';
        rd_ack1_int <= rd_int;
      when "01" => 
        -- wires
        reg_rdat_int <= wires_i;
        wires_rd_o <= '1';
        rd_ack1_int <= rd_int;
      when "10" => 
        -- acks
        reg_rdat_int <= acks_i;
        acks_rd_o <= '1';
        rd_ack1_int <= acks_rack_i;
      when others =>
        rd_ack1_int <= rd_int;
      end case;
    end if;
  end process;

  -- Process for read requests.
  process (wb_adr_i, reg_rdat_int, rd_ack1_int, rd_int) begin
    -- By default ack read requests
    wb_dat_o <= (others => '0');
    case wb_adr_i(3 downto 2) is
    when "00" => 
      -- strobe
      wb_dat_o <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when "01" => 
      -- wires
      wb_dat_o <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when "10" => 
      -- acks
      wb_dat_o <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when others =>
      rd_ack_int <= rd_int;
    end case;
  end process;
end syn;
