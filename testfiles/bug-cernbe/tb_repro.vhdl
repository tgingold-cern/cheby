library ieee;
use ieee.std_logic_1164.all;

entity tb_repro is
end tb_repro;

architecture behav of tb_repro is
  signal Clk            : std_logic := '0';
  signal Rst            : std_logic;
  signal VMEAddr        : std_logic_vector(2 downto 1);
  signal VMERdData      : std_logic_vector(15 downto 0);
  signal VMEWrData      : std_logic_vector(15 downto 0);
  signal VMERdMem       : std_logic;
  signal VMEWrMem       : std_logic;
  signal VMERdDone      : std_logic;
  signal VMEWrDone      : std_logic;
  signal regA_o         : std_logic_vector(31 downto 0);
  signal sm_VMEAddr_o   : std_logic_vector(1 downto 1);
  signal sm_VMERdData_i : std_logic_vector(15 downto 0);
  signal sm_VMEWrData_o : std_logic_vector(15 downto 0);
  signal sm_VMERdMem_o  : std_logic;
  signal sm_VMEWrMem_o  : std_logic;
  signal sm_VMERdDone_i : std_logic;
  signal sm_VMEWrDone_i : std_logic;
  signal subrA_o        : std_logic_vector(15 downto 0);
  signal subrB_i        : std_logic_vector(15 downto 0);
begin
  Clk <= not Clk after 5 ns;

  subrb_i <= x"000b";
  
  process
  begin
    Rst <= '1';
    VMERdMem <= '0';
    VMEWrMem <= '0';

    wait for 20 ns;
    Rst <= '0';

    --  Write a register
    wait until rising_edge (Clk);
    VmeAddr <= b"00";
    VmeWrData <= x"dead";
    VmeWrMem <= '1';

    loop
      wait until rising_edge (Clk);
      VmeWrMem <= '0';
      exit when VmeWrDone = '1';
    end loop;

    --  Read submap (regb)
    wait until rising_edge (Clk);
    VmeAddr <= b"11";
    VmeRdMem <= '1';

    loop
      wait until rising_edge (Clk);
      VmeRdMem <= '0';
      exit when VmeRdDone = '1';
    end loop;

    assert VmeRdData = subrb_i severity failure;

    --  Write submap (rega)

    assert subra_o = x"0000" severity failure;
    wait until rising_edge (Clk);
    VmeAddr <= b"10";
    VmeWrData <= x"11aa";
    VmeWrMem <= '1';

    loop
      wait until rising_edge (Clk);
      VmeWrMem <= '0';
      exit when VmeWrDone = '1';
    end loop;

    assert subra_o = x"11aa" severity failure;

    report "Test OK" severity note;
    
    wait;
  end process;

  dut: entity work.example
    port map (
      Clk            => Clk,
      Rst            => Rst,
      VMEAddr        => VMEAddr,
      VMERdData      => VMERdData,
      VMEWrData      => VMEWrData,
      VMERdMem       => VMERdMem,
      VMEWrMem       => VMEWrMem,
      VMERdDone      => VMERdDone,
      VMEWrDone      => VMEWrDone,
      regA_o         => regA_o,
      sm_VMEAddr_o   => sm_VMEAddr_o,
      sm_VMERdData_i => sm_VMERdData_i,
      sm_VMEWrData_o => sm_VMEWrData_o,
      sm_VMERdMem_o  => sm_VMERdMem_o,
      sm_VMEWrMem_o  => sm_VMEWrMem_o,
      sm_VMERdDone_i => sm_VMERdDone_i,
      sm_VMEWrDone_i => sm_VMEWrDone_i);

  sub_dut: entity work.sub_repro
    port map (
      Clk       => Clk,
      Rst       => Rst,
      VMEAddr   => sm_VMEAddr_o,
      VMERdData => sm_VMERdData_i,
      VMEWrData => sm_VMEWrData_o,
      VMERdMem  => sm_VMERdMem_o,
      VMEWrMem  => sm_VMEWrMem_o,
      VMERdDone => sm_VMERdDone_i,
      VMEWrDone => sm_VMEWrDone_i,
      subrA_o   => subrA_o,
      subrB_i   => subrB_i);
end behav;
