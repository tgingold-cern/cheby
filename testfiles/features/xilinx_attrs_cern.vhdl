library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xilinx_attrs is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(2 downto 2);
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- cern-be-vme bus subm
    subm_VMEAddr_o       : out   std_logic_vector(2 downto 2);
    subm_VMERdData_i     : in    std_logic_vector(31 downto 0);
    subm_VMEWrData_o     : out   std_logic_vector(31 downto 0);
    subm_VMERdMem_o      : out   std_logic;
    subm_VMEWrMem_o      : out   std_logic;
    subm_VMERdDone_i     : in    std_logic;
    subm_VMEWrDone_i     : in    std_logic
  );
end xilinx_attrs;

architecture syn of xilinx_attrs is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal subm_ws                        : std_logic;
  signal subm_wt                        : std_logic;
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of VMEAddr : signal is
    "cern.ch:interface:cheburashka:1.0 slave ADR";
  attribute X_INTERFACE_INFO of VMERdData : signal is
    "cern.ch:interface:cheburashka:1.0 slave DATO";
  attribute X_INTERFACE_INFO of VMEWrData : signal is
    "cern.ch:interface:cheburashka:1.0 slave DATI";
  attribute X_INTERFACE_INFO of VMERdMem : signal is
    "cern.ch:interface:cheburashka:1.0 slave RD";
  attribute X_INTERFACE_INFO of VMEWrMem : signal is
    "cern.ch:interface:cheburashka:1.0 slave WR";
  attribute X_INTERFACE_INFO of VMERdDone : signal is
    "cern.ch:interface:cheburashka:1.0 slave RACK";
  attribute X_INTERFACE_INFO of VMEWrDone : signal is
    "cern.ch:interface:cheburashka:1.0 slave WACK";
  attribute X_INTERFACE_INFO of subm_VMEAddr_o : signal is
    "cern.ch:interface:cheburashka:1.0 subm ADR";
  attribute X_INTERFACE_INFO of subm_VMERdData_i : signal is
    "cern.ch:interface:cheburashka:1.0 subm DATO";
  attribute X_INTERFACE_INFO of subm_VMEWrData_o : signal is
    "cern.ch:interface:cheburashka:1.0 subm DATI";
  attribute X_INTERFACE_INFO of subm_VMERdMem_o : signal is
    "cern.ch:interface:cheburashka:1.0 subm RD";
  attribute X_INTERFACE_INFO of subm_VMEWrMem_o : signal is
    "cern.ch:interface:cheburashka:1.0 subm WR";
  attribute X_INTERFACE_INFO of subm_VMERdDone_i : signal is
    "cern.ch:interface:cheburashka:1.0 subm RACK";
  attribute X_INTERFACE_INFO of subm_VMEWrDone_i : signal is
    "cern.ch:interface:cheburashka:1.0 subm WACK";
begin
  rst_n <= not Rst;
  VMERdDone <= rd_ack_int;
  VMEWrDone <= wr_ack_int;

  -- pipelining for wr-in+rd-out
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        rd_ack_int <= '0';
        VMERdData <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "0";
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_adr_d0 <= VMEAddr;
        wr_dat_d0 <= VMEWrData;
      end if;
    end if;
  end process;

  -- Interface subm
  subm_VMEWrData_o <= wr_dat_d0;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        subm_wt <= '0';
      else
        subm_wt <= (subm_wt or subm_ws) and not subm_VMEWrDone_i;
      end if;
    end if;
  end process;
  subm_VMEWrMem_o <= subm_ws;
  process (VMEAddr, wr_adr_d0, subm_wt, subm_ws) begin
    if (subm_ws or subm_wt) = '1' then
      subm_VMEAddr_o <= wr_adr_d0(2 downto 2);
    else
      subm_VMEAddr_o <= VMEAddr(2 downto 2);
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, subm_VMEWrDone_i) begin
    subm_ws <= '0';
    -- Submap subm
    subm_ws <= wr_req_d0;
    wr_ack_int <= subm_VMEWrDone_i;
  end process;

  -- Process for read requests.
  process (VMERdMem, subm_VMERdData_i, subm_VMERdDone_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    subm_VMERdMem_o <= '0';
    -- Submap subm
    subm_VMERdMem_o <= VMERdMem;
    rd_dat_d0 <= subm_VMERdData_i;
    rd_ack_d0 <= subm_VMERdDone_i;
  end process;
end syn;
