library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity wmask_avalon is
  port (
    clk                  : in    std_logic;
    reset                : in    std_logic;
    address              : in    std_logic_vector(5 downto 2);
    readdata             : out   std_logic_vector(31 downto 0);
    writedata            : in    std_logic_vector(31 downto 0);
    byteenable           : in    std_logic_vector(3 downto 0);
    read                 : in    std_logic;
    write                : in    std_logic;
    readdatavalid        : out   std_logic;
    waitrequest          : out   std_logic;

    -- REG reg_rw
    reg_rw_o             : out   std_logic_vector(31 downto 0);

    -- REG reg_ro
    reg_ro_i             : in    std_logic_vector(31 downto 0);

    -- REG reg_wo
    reg_wo_o             : out   std_logic_vector(31 downto 0);

    -- REG wire_rw
    wire_rw_i            : in    std_logic_vector(31 downto 0);
    wire_rw_o            : out   std_logic_vector(31 downto 0);

    -- REG wire_ro
    wire_ro_i            : in    std_logic_vector(31 downto 0);

    -- REG wire_wo
    wire_wo_o            : out   std_logic_vector(31 downto 0);

    -- RAM port for ram1
    ram1_adr_i           : in    std_logic_vector(2 downto 0);
    ram1_row1_rd_i       : in    std_logic;
    ram1_row1_dat_o      : out   std_logic_vector(31 downto 0)
  );
end wmask_avalon;

architecture syn of wmask_avalon is
  signal rst_n                          : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_dat                         : std_logic_vector(31 downto 0);
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal wait_int                       : std_logic;
  signal sel_int                        : std_logic_vector(31 downto 0);
  signal adr                            : std_logic_vector(5 downto 2);
  signal reg_rw_reg                     : std_logic_vector(31 downto 0);
  signal reg_rw_wreq                    : std_logic;
  signal reg_rw_wack                    : std_logic;
  signal reg_wo_reg                     : std_logic_vector(31 downto 0);
  signal reg_wo_wreq                    : std_logic;
  signal reg_wo_wack                    : std_logic;
  signal ram1_row1_int_dato             : std_logic_vector(31 downto 0);
  signal ram1_row1_ext_dat              : std_logic_vector(31 downto 0);
  signal ram1_row1_rreq                 : std_logic;
  signal ram1_row1_rack                 : std_logic;
  signal ram1_row1_int_wr               : std_logic;
  signal ram1_sel_int                   : std_logic_vector(3 downto 0);
begin
  rst_n <= not reset;
  process (clk) begin
    if rising_edge(clk) then
      if rst_n = '0' then
        wait_int <= '0';
      else
        wait_int <= (wait_int or (read or write)) and not (rd_ack or wr_ack);
      end if;
    end if;
  end process;
  process (byteenable) begin
    sel_int(7 downto 0) <= (others => byteenable(0));
    sel_int(15 downto 8) <= (others => byteenable(1));
    sel_int(23 downto 16) <= (others => byteenable(2));
    sel_int(31 downto 24) <= (others => byteenable(3));
  end process;
  process (clk) begin
    if rising_edge(clk) then
      if rst_n = '0' then
        rd_req <= '0';
        wr_req <= '0';
      else
        if ((read or write) and not wait_int) = '1' then
          adr <= address;
        else
        end if;
        if (write and not wait_int) = '1' then
          wr_sel <= sel_int;
          wr_dat <= writedata;
        else
        end if;
        rd_req <= read and not wait_int;
        wr_req <= write and not wait_int;
      end if;
    end if;
  end process;
  readdatavalid <= rd_ack;
  waitrequest <= wait_int;

  -- Register reg_rw
  reg_rw_o <= reg_rw_reg;
  process (clk) begin
    if rising_edge(clk) then
      if rst_n = '0' then
        reg_rw_reg <= "00000000000000000000000000000000";
        reg_rw_wack <= '0';
      else
        if reg_rw_wreq = '1' then
          reg_rw_reg <= (reg_rw_reg and not wr_sel) or (wr_dat and wr_sel);
        end if;
        reg_rw_wack <= reg_rw_wreq;
      end if;
    end if;
  end process;

  -- Register reg_ro

  -- Register reg_wo
  reg_wo_o <= reg_wo_reg;
  process (clk) begin
    if rising_edge(clk) then
      if rst_n = '0' then
        reg_wo_reg <= "00000000000000000000000000000000";
        reg_wo_wack <= '0';
      else
        if reg_wo_wreq = '1' then
          reg_wo_reg <= (reg_wo_reg and not wr_sel) or (wr_dat and wr_sel);
        end if;
        reg_wo_wack <= reg_wo_wreq;
      end if;
    end if;
  end process;

  -- Register wire_rw
  wire_rw_o <= (wire_rw_i and not wr_sel) or (wr_dat and wr_sel);

  -- Register wire_ro

  -- Register wire_wo
  wire_wo_o <= wr_dat;

  -- Memory ram1
  ram1_row1_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 8,
      g_addr_width         => 3,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk,
      clk_b_i              => clk,
      addr_a_i             => adr(4 downto 2),
      bwsel_a_i            => ram1_sel_int,
      data_a_i             => wr_dat,
      data_a_o             => ram1_row1_int_dato,
      rd_a_i               => ram1_row1_rreq,
      wr_a_i               => ram1_row1_int_wr,
      addr_b_i             => ram1_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ram1_row1_ext_dat,
      data_b_o             => ram1_row1_dat_o,
      rd_b_i               => ram1_row1_rd_i,
      wr_b_i               => '0'
    );
  
  process (wr_sel) begin
    ram1_sel_int <= (others => '0');
    if not (wr_sel(7 downto 0) = (7 downto 0 => '0')) then
      ram1_sel_int(0) <= '1';
    end if;
    if not (wr_sel(15 downto 8) = (7 downto 0 => '0')) then
      ram1_sel_int(1) <= '1';
    end if;
    if not (wr_sel(23 downto 16) = (7 downto 0 => '0')) then
      ram1_sel_int(2) <= '1';
    end if;
    if not (wr_sel(31 downto 24) = (7 downto 0 => '0')) then
      ram1_sel_int(3) <= '1';
    end if;
  end process;
  process (clk) begin
    if rising_edge(clk) then
      if rst_n = '0' then
        ram1_row1_rack <= '0';
      else
        ram1_row1_rack <= ram1_row1_rreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (adr, wr_req, reg_rw_wack, reg_wo_wack) begin
    reg_rw_wreq <= '0';
    reg_wo_wreq <= '0';
    ram1_row1_int_wr <= '0';
    case adr(5 downto 5) is
    when "0" =>
      case adr(4 downto 2) is
      when "000" =>
        -- Reg reg_rw
        reg_rw_wreq <= wr_req;
        wr_ack <= reg_rw_wack;
      when "001" =>
        -- Reg reg_ro
        wr_ack <= wr_req;
      when "010" =>
        -- Reg reg_wo
        reg_wo_wreq <= wr_req;
        wr_ack <= reg_wo_wack;
      when "011" =>
        -- Reg wire_rw
        wr_ack <= wr_req;
      when "100" =>
        -- Reg wire_ro
        wr_ack <= wr_req;
      when "101" =>
        -- Reg wire_wo
        wr_ack <= wr_req;
      when others =>
        wr_ack <= wr_req;
      end case;
    when "1" =>
      -- Memory ram1
      ram1_row1_int_wr <= wr_req;
      wr_ack <= wr_req;
    when others =>
      wr_ack <= wr_req;
    end case;
  end process;

  -- Process for read requests.
  process (adr, rd_req, reg_rw_reg, reg_ro_i, wire_rw_i, wire_ro_i, ram1_row1_int_dato,
           ram1_row1_rack) begin
    -- By default ack read requests
    readdata <= (others => 'X');
    ram1_row1_rreq <= '0';
    case adr(5 downto 5) is
    when "0" =>
      case adr(4 downto 2) is
      when "000" =>
        -- Reg reg_rw
        rd_ack <= rd_req;
        readdata <= reg_rw_reg;
      when "001" =>
        -- Reg reg_ro
        rd_ack <= rd_req;
        readdata <= reg_ro_i;
      when "010" =>
        -- Reg reg_wo
        rd_ack <= rd_req;
      when "011" =>
        -- Reg wire_rw
        rd_ack <= rd_req;
        readdata <= wire_rw_i;
      when "100" =>
        -- Reg wire_ro
        rd_ack <= rd_req;
        readdata <= wire_ro_i;
      when "101" =>
        -- Reg wire_wo
        rd_ack <= rd_req;
      when others =>
        rd_ack <= rd_req;
      end case;
    when "1" =>
      -- Memory ram1
      readdata <= ram1_row1_int_dato;
      ram1_row1_rreq <= rd_req;
      rd_ack <= ram1_row1_rack;
    when others =>
      rd_ack <= rd_req;
    end case;
  end process;
end syn;
