library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity no_port is
  port (
    pclk                 : in    std_logic;
    presetn              : in    std_logic;
    paddr                : in    std_logic_vector(2 downto 2);
    psel                 : in    std_logic;
    pwrite               : in    std_logic;
    penable              : in    std_logic;
    pready               : out   std_logic;
    pwdata               : in    std_logic_vector(31 downto 0);
    pstrb                : in    std_logic_vector(3 downto 0);
    prdata               : out   std_logic_vector(31 downto 0);
    pslverr              : out   std_logic;

    -- REG reg1
    reg1_o               : out   std_logic_vector(31 downto 0)
  );
end no_port;

architecture syn of no_port is
  signal wr_req                         : std_logic;
  signal wr_addr                        : std_logic_vector(2 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal rd_req                         : std_logic;
  signal rd_addr                        : std_logic_vector(2 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal wr_ack                         : std_logic;
  signal rd_ack                         : std_logic;
  signal reg0_reg                       : std_logic_vector(31 downto 0);
  signal reg0_wreq                      : std_logic;
  signal reg0_wack                      : std_logic;
  signal reg1_reg                       : std_logic_vector(31 downto 0);
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- Write Channel
  wr_req <= (psel and pwrite) and not penable;
  wr_addr <= paddr;
  wr_data <= pwdata;

  -- Read Channel
  rd_req <= (psel and not pwrite) and not penable;
  rd_addr <= paddr;
  prdata <= rd_data;
  pready <= wr_ack or rd_ack;
  pslverr <= '0';

  -- pipelining for wr-in+rd-out
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        rd_ack <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
      end if;
    end if;
  end process;

  -- Register reg0
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg0_reg <= "00000000000000000000000000000000";
        reg0_wack <= '0';
      else
        if reg0_wreq = '1' then
          reg0_reg <= wr_dat_d0;
        end if;
        reg0_wack <= reg0_wreq;
      end if;
    end if;
  end process;

  -- Register reg1
  reg1_o <= reg1_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg1_reg <= "00000000000000000000000000000000";
        reg1_wack <= '0';
      else
        if reg1_wreq = '1' then
          reg1_reg <= wr_dat_d0;
        end if;
        reg1_wack <= reg1_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg0_wack, reg1_wack) begin
    reg0_wreq <= '0';
    reg1_wreq <= '0';
    case wr_adr_d0(2 downto 2) is
    when "0" =>
      -- Reg reg0
      reg0_wreq <= wr_req_d0;
      wr_ack <= reg0_wack;
    when "1" =>
      -- Reg reg1
      reg1_wreq <= wr_req_d0;
      wr_ack <= reg1_wack;
    when others =>
      wr_ack <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, reg0_reg, reg1_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case rd_addr(2 downto 2) is
    when "0" =>
      -- Reg reg0
      rd_ack_d0 <= rd_req;
      rd_dat_d0 <= reg0_reg;
    when "1" =>
      -- Reg reg1
      rd_ack_d0 <= rd_req;
      rd_dat_d0 <= reg1_reg;
    when others =>
      rd_ack_d0 <= rd_req;
    end case;
  end process;
end syn;
