library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sub_repro is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(1 downto 1);
    VMERdData            : out   std_logic_vector(15 downto 0);
    VMEWrData            : in    std_logic_vector(15 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- The first register (with some fields)
    subrA_o              : out   std_logic_vector(15 downto 0);

    -- The first register (with some fields)
    subrB_i              : in    std_logic_vector(15 downto 0)
  );
end sub_repro;

architecture syn of sub_repro is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal subrA_reg                      : std_logic_vector(15 downto 0);
  signal subrA_wreq                     : std_logic;
  signal subrA_wack                     : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(15 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(1 downto 1);
  signal wr_dat_d0                      : std_logic_vector(15 downto 0);
begin
  rst_n <= not Rst;
  VMERdDone <= rd_ack_int;
  VMEWrDone <= wr_ack_int;

  -- pipelining for wr-in+rd-out
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        rd_ack_int <= '0';
        VMERdData <= "0000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "0";
        wr_dat_d0 <= "0000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_adr_d0 <= VMEAddr;
        wr_dat_d0 <= VMEWrData;
      end if;
    end if;
  end process;

  -- Register subrA
  subrA_o <= subrA_reg;
  subrA_wack <= subrA_wreq;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        subrA_reg <= "0000000000000000";
      else
        if subrA_wreq = '1' then
          subrA_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register subrB

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, subrA_wack) begin
    subrA_wreq <= '0';
    case wr_adr_d0(1 downto 1) is
    when "0" =>
      -- Reg subrA
      subrA_wreq <= wr_req_d0;
      wr_ack_int <= subrA_wack;
    when "1" =>
      -- Reg subrB
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, subrA_reg, subrB_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case VMEAddr(1 downto 1) is
    when "0" =>
      -- Reg subrA
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= subrA_reg;
    when "1" =>
      -- Reg subrB
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= subrB_i;
    when others =>
      rd_ack_d0 <= VMERdMem;
    end case;
  end process;
end syn;
