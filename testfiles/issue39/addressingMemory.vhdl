library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eda02175v2 is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(20 downto 1);
    VMERdData            : out   std_logic_vector(15 downto 0);
    VMEWrData            : in    std_logic_vector(15 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- ViewPort to the internal acquisition RAM/SRAM blocs
    acqVP_VMEAddr_o      : out   std_logic_vector(16 downto 1);
    acqVP_VMERdData_i    : in    std_logic_vector(15 downto 0);
    acqVP_VMEWrData_o    : out   std_logic_vector(15 downto 0);
    acqVP_VMERdMem_o     : out   std_logic;
    acqVP_VMEWrMem_o     : out   std_logic;
    acqVP_VMERdDone_i    : in    std_logic;
    acqVP_VMEWrDone_i    : in    std_logic;

    -- Resets the system part of the logic in the FPGA. ONLY FOR LAB PURPOSES
    softReset_reset_o    : out   std_logic
  );
end eda02175v2;

architecture syn of eda02175v2 is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal softReset_reset_reg            : std_logic;
  signal softReset_wreq                 : std_logic;
  signal softReset_wack                 : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(15 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(20 downto 1);
  signal wr_dat_d0                      : std_logic_vector(15 downto 0);
  signal acqVP_ws                       : std_logic;
  signal acqVP_wt                       : std_logic;
begin
  rst_n <= not Rst;
  VMERdDone <= rd_ack_int;
  VMEWrDone <= wr_ack_int;

  -- pipelining for wr-in+rd-out
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_adr_d0 <= VMEAddr;
        wr_dat_d0 <= VMEWrData;
      end if;
    end if;
  end process;

  -- Interface acqVP
  acqVP_VMEWrData_o <= wr_dat_d0;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        acqVP_wt <= '0';
      else
        acqVP_wt <= (acqVP_wt or acqVP_ws) and not acqVP_VMEWrDone_i;
      end if;
    end if;
  end process;
  acqVP_VMEWrMem_o <= acqVP_ws;
  process (VMEAddr, wr_adr_d0, acqVP_wt, acqVP_ws) begin
    if (acqVP_ws or acqVP_wt) = '1' then
      acqVP_VMEAddr_o <= wr_adr_d0(16 downto 1);
    else
      acqVP_VMEAddr_o <= VMEAddr(16 downto 1);
    end if;
  end process;

  -- Register softReset
  softReset_reset_o <= softReset_reset_reg;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        softReset_reset_reg <= '0';
        softReset_wack <= '0';
      else
        if softReset_wreq = '1' then
          softReset_reset_reg <= wr_dat_d0(0);
        end if;
        softReset_wack <= softReset_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, acqVP_VMEWrDone_i, softReset_wack) begin
    acqVP_ws <= '0';
    softReset_wreq <= '0';
    case wr_adr_d0(20 downto 20) is
    when "0" =>
      -- Memory acqVP
      acqVP_ws <= wr_req_d0;
      wr_ack_int <= acqVP_VMEWrDone_i;
    when "1" =>
      case wr_adr_d0(19 downto 1) is
      when "0000000000000000000" =>
        -- Reg softReset
        softReset_wreq <= wr_req_d0;
        wr_ack_int <= softReset_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, acqVP_VMERdData_i, acqVP_VMERdDone_i,
           softReset_reset_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    acqVP_VMERdMem_o <= '0';
    case VMEAddr(20 downto 20) is
    when "0" =>
      -- Memory acqVP
      acqVP_VMERdMem_o <= VMERdMem;
      rd_dat_d0 <= acqVP_VMERdData_i;
      rd_ack_d0 <= acqVP_VMERdDone_i;
    when "1" =>
      case VMEAddr(19 downto 1) is
      when "0000000000000000000" =>
        -- Reg softReset
        rd_ack_d0 <= VMERdMem;
        rd_dat_d0(0) <= softReset_reset_reg;
        rd_dat_d0(15 downto 1) <= (others => '0');
      when others =>
        rd_ack_d0 <= VMERdMem;
      end case;
    when others =>
      rd_ack_d0 <= VMERdMem;
    end case;
  end process;
end syn;
