library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buserr_apb is
  port (
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

    -- REG reg1
    reg1_o               : out   std_logic_vector(31 downto 0);

    -- REG reg2
    reg2_o               : out   std_logic_vector(31 downto 0);

    -- REG reg3
    reg3_o               : out   std_logic_vector(31 downto 0)
  );
end buserr_apb;

architecture syn of buserr_apb is
  signal wr_req                         : std_logic;
  signal wr_addr                        : std_logic_vector(3 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal rd_req                         : std_logic;
  signal rd_addr                        : std_logic_vector(3 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal wr_err                         : std_logic;
  signal wr_ack                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_err                         : std_logic;
  signal reg1_reg                       : std_logic_vector(31 downto 0);
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal reg2_reg                       : std_logic_vector(31 downto 0);
  signal reg2_wreq                      : std_logic;
  signal reg2_wack                      : std_logic;
  signal reg3_reg                       : std_logic_vector(31 downto 0);
  signal reg3_wreq                      : std_logic;
  signal reg3_wack                      : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_err_d0                      : std_logic;
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
  pslverr <= wr_err or rd_err;

  -- pipelining for wr-in+rd-out
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        rd_ack <= '0';
        rd_err <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack <= rd_ack_d0;
        rd_err <= rd_err_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
      end if;
    end if;
  end process;

  -- Register reg1
  reg1_o <= reg1_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg1_reg <= "00010010001101000101011001111000";
        reg1_wack <= '0';
      else
        if reg1_wreq = '1' then
          reg1_reg <= wr_dat_d0;
        end if;
        reg1_wack <= reg1_wreq;
      end if;
    end if;
  end process;

  -- Register reg2
  reg2_o <= reg2_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg2_reg <= "00010010001101000101011001111000";
        reg2_wack <= '0';
      else
        if reg2_wreq = '1' then
          reg2_reg <= wr_dat_d0;
        end if;
        reg2_wack <= reg2_wreq;
      end if;
    end if;
  end process;

  -- Register reg3
  reg3_o <= reg3_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg3_reg <= "00010010001101000101011001111000";
        reg3_wack <= '0';
      else
        if reg3_wreq = '1' then
          reg3_reg <= wr_dat_d0;
        end if;
        reg3_wack <= reg3_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg1_wack, reg2_wack, reg3_wack) begin
    reg1_wreq <= '0';
    reg2_wreq <= '0';
    reg3_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg reg1
      reg1_wreq <= wr_req_d0;
      wr_ack <= reg1_wack;
      wr_err <= '0';
    when "01" =>
      -- Reg reg2
      reg2_wreq <= wr_req_d0;
      wr_ack <= reg2_wack;
      wr_err <= '0';
    when "10" =>
      -- Reg reg3
      reg3_wreq <= wr_req_d0;
      wr_ack <= reg3_wack;
      wr_err <= '0';
    when others =>
      wr_ack <= wr_req_d0;
      wr_err <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, reg1_reg, reg2_reg, reg3_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case rd_addr(3 downto 2) is
    when "00" =>
      -- Reg reg1
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= reg1_reg;
    when "01" =>
      -- Reg reg2
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= reg2_reg;
    when "10" =>
      -- Reg reg3
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= reg3_reg;
    when others =>
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= rd_req;
    end case;
  end process;
end syn;
