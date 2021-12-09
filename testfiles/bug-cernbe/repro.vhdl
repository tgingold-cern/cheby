library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity example is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(2 downto 1);
    VMERdData            : out   std_logic_vector(15 downto 0);
    VMEWrData            : in    std_logic_vector(15 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- The first register (with some fields)
    regA_o               : out   std_logic_vector(31 downto 0);

    -- CERN-BE bus sm
    sm_VMEAddr_o         : out   std_logic_vector(1 downto 1);
    sm_VMERdData_i       : in    std_logic_vector(15 downto 0);
    sm_VMEWrData_o       : out   std_logic_vector(15 downto 0);
    sm_VMERdMem_o        : out   std_logic;
    sm_VMEWrMem_o        : out   std_logic;
    sm_VMERdDone_i       : in    std_logic;
    sm_VMEWrDone_i       : in    std_logic
  );
end example;

architecture syn of example is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal regA_reg                       : std_logic_vector(31 downto 0);
  signal regA_wreq                      : std_logic_vector(1 downto 0);
  signal regA_wack                      : std_logic_vector(1 downto 0);
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(15 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 1);
  signal wr_dat_d0                      : std_logic_vector(15 downto 0);
  signal sm_ws                          : std_logic;
  signal sm_wt                          : std_logic;
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

  -- Register regA
  regA_o <= regA_reg;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        regA_reg <= "00000000000000000000000000000000";
        regA_wack <= (others => '0');
      else
        if regA_wreq(0) = '1' then
          regA_reg(15 downto 0) <= wr_dat_d0;
        end if;
        if regA_wreq(1) = '1' then
          regA_reg(31 downto 16) <= wr_dat_d0;
        end if;
        regA_wack <= regA_wreq;
      end if;
    end if;
  end process;

  -- Interface sm
  sm_VMEWrData_o <= wr_dat_d0;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        sm_wt <= '0';
      else
        sm_wt <= (sm_wt or sm_ws) and not sm_VMEWrDone_i;
      end if;
    end if;
  end process;
  sm_VMEWrMem_o <= sm_ws;
  process (VMEAddr, wr_adr_d0, sm_wt, sm_ws) begin
    if (sm_ws or sm_wt) = '1' then
      sm_VMEAddr_o <= wr_adr_d0(1 downto 1);
    else
      sm_VMEAddr_o <= VMEAddr(1 downto 1);
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, regA_wack, sm_VMEWrDone_i) begin
    regA_wreq <= (others => '0');
    sm_ws <= '0';
    case wr_adr_d0(2 downto 2) is
    when "0" =>
      case wr_adr_d0(1 downto 1) is
      when "0" =>
        -- Reg regA
        regA_wreq(1) <= wr_req_d0;
        wr_ack_int <= regA_wack(1);
      when "1" =>
        -- Reg regA
        regA_wreq(0) <= wr_req_d0;
        wr_ack_int <= regA_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "1" =>
      -- Submap sm
      sm_ws <= wr_req_d0;
      wr_ack_int <= sm_VMEWrDone_i;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, regA_reg, sm_VMERdData_i, sm_VMERdDone_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    sm_VMERdMem_o <= '0';
    case VMEAddr(2 downto 2) is
    when "0" =>
      case VMEAddr(1 downto 1) is
      when "0" =>
        -- Reg regA
        rd_ack_d0 <= VMERdMem;
        rd_dat_d0 <= regA_reg(31 downto 16);
      when "1" =>
        -- Reg regA
        rd_ack_d0 <= VMERdMem;
        rd_dat_d0 <= regA_reg(15 downto 0);
      when others =>
        rd_ack_d0 <= VMERdMem;
      end case;
    when "1" =>
      -- Submap sm
      sm_VMERdMem_o <= VMERdMem;
      rd_dat_d0 <= sm_VMERdData_i;
      rd_ack_d0 <= sm_VMERdDone_i;
    when others =>
      rd_ack_d0 <= VMERdMem;
    end case;
  end process;
end syn;
