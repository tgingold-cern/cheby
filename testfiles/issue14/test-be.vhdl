library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_axi4 is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(2 downto 2);
    awprot               : in    std_logic_vector(2 downto 0);
    wvalid               : in    std_logic;
    wready               : out   std_logic;
    wdata                : in    std_logic_vector(31 downto 0);
    wstrb                : in    std_logic_vector(3 downto 0);
    bvalid               : out   std_logic;
    bready               : in    std_logic;
    bresp                : out   std_logic_vector(1 downto 0);
    arvalid              : in    std_logic;
    arready              : out   std_logic;
    araddr               : in    std_logic_vector(2 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- Test register 1
    register1_o          : out   std_logic_vector(63 downto 0)
  );
end test_axi4;

architecture syn of test_axi4 is
  signal rd_int                         : std_logic;
  signal wr_int                         : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wr_done_int                    : std_logic;
  signal rd_done_int                    : std_logic;
  signal dati                           : std_logic_vector(31 downto 0);
  signal dato                           : std_logic_vector(31 downto 0);
  signal adrw                           : std_logic_vector(2 downto 2);
  signal adrr                           : std_logic_vector(2 downto 2);
  signal awready_r                      : std_logic;
  signal wready_r                       : std_logic;
  signal bvalid_r                       : std_logic;
  signal arready_r                      : std_logic;
  signal rvalid_r                       : std_logic;
  signal register1_reg                  : std_logic_vector(63 downto 0);
  signal adr_int                        : std_logic_vector(2 downto 2);
  signal wr_ack_done_int                : std_logic;
  signal reg_rdat_int                   : std_logic_vector(31 downto 0);
  signal rd_ack1_int                    : std_logic;
begin

  -- AW channel
  awready <= awready_r;
  process (aclk, areset_n) begin
    if areset_n = '0' then 
      awready_r <= '1';
      adrw <= (others => '0');
    elsif rising_edge(aclk) then
      if (awready_r and awvalid) = '1' then
        adrw <= awaddr;
        awready_r <= '0';
      elsif wr_done_int = '1' then
        awready_r <= '1';
      end if;
    end if;
  end process;

  -- W channel
  wready <= wready_r;
  process (aclk, areset_n) begin
    if areset_n = '0' then 
      wready_r <= '1';
      dati <= (others => '0');
    elsif rising_edge(aclk) then
      if (wready_r and wvalid) = '1' then
        dati <= wdata;
        wready_r <= '0';
      elsif wr_done_int = '1' then
        wready_r <= '1';
      end if;
    end if;
  end process;
  wr_int <= not awready_r and not wready_r;

  -- B channel
  process (aclk, areset_n) begin
    if areset_n = '0' then 
      bvalid_r <= '0';
    elsif rising_edge(aclk) then
      if wr_done_int = '1' then
        bvalid_r <= '0';
      elsif wr_ack_int = '1' then
        bvalid_r <= '1';
      end if;
    end if;
  end process;
  wr_done_int <= bready and bvalid_r;
  bvalid <= bvalid_r;
  bresp <= "00";

  -- AR channel
  arready <= arready_r;
  process (aclk, areset_n) begin
    if areset_n = '0' then 
      arready_r <= '1';
      adrr <= (others => '0');
    elsif rising_edge(aclk) then
      if (arready_r and arvalid) = '1' then
        adrr <= araddr;
        arready_r <= '0';
      elsif rd_done_int = '1' then
        arready_r <= '1';
      end if;
    end if;
  end process;
  rd_int <= not arready_r and not rvalid_r;

  -- R channel
  process (aclk, areset_n) begin
    if areset_n = '0' then 
      rvalid_r <= '0';
    elsif rising_edge(aclk) then
      if rd_done_int = '1' then
        rvalid_r <= '0';
      elsif rd_ack_int = '1' then
        rvalid_r <= '1';
      end if;
    end if;
  end process;
  rd_done_int <= rready and rvalid_r;
  rvalid <= rvalid_r;
  rdata <= dato;
  rresp <= "00";

  -- Assign unified address bus
  process (adrr, adrw, rd_int) begin
    if rd_int = '1' then
      adr_int <= adrr;
    else
      adr_int <= adrw;
    end if;
  end process;

  -- Assign outputs
  register1_o <= register1_reg;

  -- Process for write requests.
  process (aclk, areset_n) begin
    if areset_n = '0' then 
      wr_ack_int <= '0';
      wr_ack_done_int <= '0';
      register1_reg <= "0000000000000000000000000000000000000000000000000000000000000000";
    elsif rising_edge(aclk) then
      if wr_int = '1' then
        -- Write in progress
        wr_ack_done_int <= wr_ack_int or wr_ack_done_int;
        case adrw(2 downto 2) is
        when "0" => 
          -- Register register1
          register1_reg(63 downto 32) <= dati;
          wr_ack_int <= not wr_ack_done_int;
        when "1" => 
          -- Register register1
          register1_reg(31 downto 0) <= dati;
          wr_ack_int <= not wr_ack_done_int;
        when others =>
          wr_ack_int <= not wr_ack_done_int;
        end case;
      else
        wr_ack_int <= '0';
        wr_ack_done_int <= '0';
      end if;
    end if;
  end process;

  -- Process for registers read.
  process (aclk, areset_n) begin
    if areset_n = '0' then 
      rd_ack1_int <= '0';
      reg_rdat_int <= (others => 'X');
    elsif rising_edge(aclk) then
      if rd_int = '1' and rd_ack1_int = '0' then
        rd_ack1_int <= '1';
        reg_rdat_int <= (others => '0');
        case adrr(2 downto 2) is
        when "0" => 
          -- register1
        when "1" => 
          -- register1
        when others =>
        end case;
      else
        rd_ack1_int <= '0';
      end if;
    end if;
  end process;

  -- Process for read requests.
  process (adrr, reg_rdat_int, rd_ack1_int, rd_int) begin
    -- By default ack read requests
    dato <= (others => '0');
    rd_ack_int <= '1';
    case adrr(2 downto 2) is
    when "0" => 
      -- register1
      dato <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when "1" => 
      -- register1
      dato <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when others =>
    end case;
  end process;
end syn;
