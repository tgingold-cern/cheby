library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lock_apb is
  port (
    scantest             : in    std_logic;
    pclk                 : in    std_logic;
    presetn              : in    std_logic;
    paddr                : in    std_logic_vector(3 downto 2);
    psel                 : in    std_logic;
    pwrite               : in    std_logic;
    penable              : in    std_logic;
    pready               : out   std_logic;
    pwdata               : in    std_logic_vector(31 downto 0);
    pstrb                : in    std_logic_vector(3 downto 0);
    prdata               : out   std_logic_vector(31 downto 0);
    pslverr              : out   std_logic;

    -- REG reg0
    reg0_o               : out   std_logic_vector(31 downto 0);

    -- REG reg1
    reg1_o               : out   std_logic_vector(31 downto 0);

    -- REG reg2
    reg2_field0_o        : out   std_logic_vector(3 downto 0);
    reg2_field1_o        : out   std_logic_vector(3 downto 0)
  );
end lock_apb;

architecture syn of lock_apb is
  signal wr_req                         : std_logic;
  signal wr_addr                        : std_logic_vector(3 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal rd_req                         : std_logic;
  signal rd_addr                        : std_logic_vector(3 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal wr_ack                         : std_logic;
  signal rd_ack                         : std_logic;
  signal reg0_reg                       : std_logic_vector(31 downto 0) := "00010010001101000101011001111000";
  signal reg0_wreq                      : std_logic;
  signal reg0_wack                      : std_logic;
  signal reg1_reg                       : std_logic_vector(31 downto 0) := "00100011010001010110011110001001";
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal reg2_field0_reg                : std_logic_vector(3 downto 0) := "0011";
  signal reg2_field1_reg                : std_logic_vector(3 downto 0) := "0100";
  signal reg2_wreq                      : std_logic;
  signal reg2_wack                      : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(3 downto 2);
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
        rd_data <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "00";
        wr_dat_d0 <= "00000000000000000000000000000000";
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
  reg0_o <= reg0_reg;
  reg0_wack <= reg0_wreq;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg0_reg <= "00010010001101000101011001111000";
      else
        if reg0_wreq = '1' then
          if scantest = '0' then
            reg0_reg <= wr_dat_d0;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Register reg1
  process (scantest, reg1_reg) begin
    -- Overwrite output with lock value
    if scantest = '1' then
      reg1_o <= "10011000011101100101010000110010";
    else
      reg1_o <= reg1_reg;
    end if;
  end process;
  reg1_wack <= reg1_wreq;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg1_reg <= "00100011010001010110011110001001";
      else
        if reg1_wreq = '1' then
          reg1_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register reg2
  reg2_field0_o <= reg2_field0_reg;
  process (scantest, reg2_field1_reg) begin
    -- Overwrite output with lock value
    if scantest = '1' then
      reg2_field1_o <= "0101";
    else
      reg2_field1_o <= reg2_field1_reg;
    end if;
  end process;
  reg2_wack <= reg2_wreq;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg2_field0_reg <= "0011";
        reg2_field1_reg <= "0100";
      else
        if reg2_wreq = '1' then
          if scantest = '0' then
            reg2_field0_reg <= wr_dat_d0(3 downto 0);
          end if;
          reg2_field1_reg <= wr_dat_d0(7 downto 4);
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg0_wack, reg1_wack, reg2_wack) begin
    reg0_wreq <= '0';
    reg1_wreq <= '0';
    reg2_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg reg0
      reg0_wreq <= wr_req_d0;
      wr_ack <= reg0_wack;
    when "01" =>
      -- Reg reg1
      reg1_wreq <= wr_req_d0;
      wr_ack <= reg1_wack;
    when "10" =>
      -- Reg reg2
      reg2_wreq <= wr_req_d0;
      wr_ack <= reg2_wack;
    when others =>
      wr_ack <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, reg0_reg, reg1_reg, reg2_field0_reg, reg2_field1_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case rd_addr(3 downto 2) is
    when "00" =>
      -- Reg reg0
      rd_ack_d0 <= rd_req;
      rd_dat_d0 <= reg0_reg;
    when "01" =>
      -- Reg reg1
      rd_ack_d0 <= rd_req;
      rd_dat_d0 <= reg1_reg;
    when "10" =>
      -- Reg reg2
      rd_ack_d0 <= rd_req;
      rd_dat_d0(3 downto 0) <= reg2_field0_reg;
      rd_dat_d0(7 downto 4) <= reg2_field1_reg;
      rd_dat_d0(31 downto 8) <= (others => '0');
    when others =>
      rd_ack_d0 <= rd_req;
    end case;
  end process;
end syn;
