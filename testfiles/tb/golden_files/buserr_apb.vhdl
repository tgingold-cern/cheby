library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buserr_apb is
  port (
    pclk                 : in    std_logic;
    presetn              : in    std_logic;
    paddr                : in    std_logic_vector(4 downto 2);
    psel                 : in    std_logic;
    pwrite               : in    std_logic;
    penable              : in    std_logic;
    pready               : out   std_logic;
    pwdata               : in    std_logic_vector(31 downto 0);
    pstrb                : in    std_logic_vector(3 downto 0);
    prdata               : out   std_logic_vector(31 downto 0);
    pslverr              : out   std_logic;

    -- REG rw0
    rw0_o                : out   std_logic_vector(31 downto 0);

    -- REG rw1
    rw1_o                : out   std_logic_vector(31 downto 0);

    -- REG rw2
    rw2_o                : out   std_logic_vector(31 downto 0);

    -- REG ro0
    ro0_i                : in    std_logic_vector(31 downto 0);

    -- REG wo0
    wo0_o                : out   std_logic_vector(31 downto 0)
  );
end buserr_apb;

architecture syn of buserr_apb is
  signal wr_req                         : std_logic;
  signal wr_addr                        : std_logic_vector(4 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_req_del                     : std_logic;
  signal rd_req                         : std_logic;
  signal rd_addr                        : std_logic_vector(4 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal wr_err                         : std_logic;
  signal wr_ack                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_err                         : std_logic;
  signal rw0_reg                        : std_logic_vector(31 downto 0);
  signal rw0_wreq                       : std_logic;
  signal rw0_wack                       : std_logic;
  signal rw1_reg                        : std_logic_vector(31 downto 0);
  signal rw1_wreq                       : std_logic;
  signal rw1_wack                       : std_logic;
  signal rw2_reg                        : std_logic_vector(31 downto 0);
  signal rw2_wreq                       : std_logic;
  signal rw2_wack                       : std_logic;
  signal wo0_reg                        : std_logic_vector(31 downto 0);
  signal wo0_wreq                       : std_logic;
  signal wo0_wack                       : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_err_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_req_del_d0                  : std_logic;
  signal wr_adr_d0                      : std_logic_vector(4 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- Write Channel
  wr_req <= (psel and pwrite) and not penable;
  wr_addr <= paddr;
  wr_data <= pwdata;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        wr_req_del <= '0';
      else
        wr_req_del <= wr_req;
      end if;
    end if;
  end process;

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
        rd_data <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_req_del_d0 <= '0';
        wr_adr_d0 <= "000";
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack <= rd_ack_d0;
        rd_err <= rd_err_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_req_del_d0 <= wr_req_del;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
      end if;
    end if;
  end process;

  -- Register rw0
  rw0_o <= rw0_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        rw0_reg <= "00010010001101000101011001111000";
        rw0_wack <= '0';
      else
        if rw0_wreq = '1' then
          rw0_reg <= wr_dat_d0;
        end if;
        rw0_wack <= rw0_wreq;
      end if;
    end if;
  end process;

  -- Register rw1
  rw1_o <= rw1_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        rw1_reg <= "00100011010001010110011110001001";
        rw1_wack <= '0';
      else
        if rw1_wreq = '1' then
          rw1_reg <= wr_dat_d0;
        end if;
        rw1_wack <= rw1_wreq;
      end if;
    end if;
  end process;

  -- Register rw2
  rw2_o <= rw2_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        rw2_reg <= "00110100010101100111100010011010";
        rw2_wack <= '0';
      else
        if rw2_wreq = '1' then
          rw2_reg <= wr_dat_d0;
        end if;
        rw2_wack <= rw2_wreq;
      end if;
    end if;
  end process;

  -- Register ro0

  -- Register wo0
  wo0_o <= wo0_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        wo0_reg <= "01010110011110001001101010111100";
        wo0_wack <= '0';
      else
        if wo0_wreq = '1' then
          wo0_reg <= wr_dat_d0;
        end if;
        wo0_wack <= wo0_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, rw0_wack, rw1_wack, rw2_wack, wr_req_del_d0, wo0_wack) begin
    rw0_wreq <= '0';
    rw1_wreq <= '0';
    rw2_wreq <= '0';
    wo0_wreq <= '0';
    case wr_adr_d0(4 downto 2) is
    when "000" =>
      -- Reg rw0
      rw0_wreq <= wr_req_d0;
      wr_ack <= rw0_wack;
      wr_err <= '0';
    when "001" =>
      -- Reg rw1
      rw1_wreq <= wr_req_d0;
      wr_ack <= rw1_wack;
      wr_err <= '0';
    when "010" =>
      -- Reg rw2
      rw2_wreq <= wr_req_d0;
      wr_ack <= rw2_wack;
      wr_err <= '0';
    when "011" =>
      -- Reg ro0
      wr_ack <= wr_req_del_d0;
      wr_err <= wr_req_del_d0;
    when "100" =>
      -- Reg wo0
      wo0_wreq <= wr_req_d0;
      wr_ack <= wo0_wack;
      wr_err <= '0';
    when others =>
      wr_ack <= wr_req_del_d0;
      wr_err <= wr_req_del_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, rw0_reg, rw1_reg, rw2_reg, ro0_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case rd_addr(4 downto 2) is
    when "000" =>
      -- Reg rw0
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= rw0_reg;
    when "001" =>
      -- Reg rw1
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= rw1_reg;
    when "010" =>
      -- Reg rw2
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= rw2_reg;
    when "011" =>
      -- Reg ro0
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= ro0_i;
    when "100" =>
      -- Reg wo0
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= rd_req;
    when others =>
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= rd_req;
    end case;
  end process;
end syn;
