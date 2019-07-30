library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(4 downto 2);
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
    araddr               : in    std_logic_vector(4 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- Test register 1
    register1_o          : out   std_logic_vector(63 downto 0);

    -- Test field 1
    block1_register2_field1_i : in    std_logic;

    -- Test field 2
    block1_register2_field2_i : in    std_logic_vector(2 downto 0);

    -- Test register 3
    block1_register3_o   : out   std_logic_vector(31 downto 0);

    -- Test field 3
    block1_block2_register4_field3_i : in    std_logic;

    -- Test field 4
    block1_block2_register4_field4_i : in    std_logic_vector(2 downto 0)
  );
end test;

architecture syn of test is
  signal rd_int                         : std_logic;
  signal wr_int                         : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal dato                           : std_logic_vector(31 downto 0);
  signal axi_wip                        : std_logic;
  signal axi_wdone                      : std_logic;
  signal axi_rip                        : std_logic;
  signal axi_rdone                      : std_logic;
  signal register1_reg                  : std_logic_vector(63 downto 0);
  signal block1_register3_reg           : std_logic_vector(31 downto 0);
  signal reg_rdat_int                   : std_logic_vector(31 downto 0);
  signal rd_ack1_int                    : std_logic;
begin

  -- AW, W and B channels
  wr_int <= (awvalid and wvalid) and not axi_wip;
  awready <= axi_wip and wr_ack_int;
  wready <= axi_wip and wr_ack_int;
  bvalid <= axi_wdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        axi_wip <= '0';
        axi_wdone <= '0';
      else
        axi_wip <= (awvalid and wvalid) and not axi_wdone;
        axi_wdone <= wr_ack_int or (axi_wdone and not bready);
      end if;
    end if;
  end process;
  bresp <= "00";

  -- AR and R channels
  rd_int <= arvalid and not axi_rip;
  arready <= axi_rip and rd_ack_int;
  rvalid <= axi_rdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        axi_rip <= '0';
        axi_rdone <= '0';
        rdata <= (others => '0');
      else
        axi_rip <= arvalid and not axi_rdone;
        if rd_ack_int = '1' then
          rdata <= dato;
        end if;
        axi_rdone <= rd_ack_int or (axi_rdone and not rready);
      end if;
    end if;
  end process;
  rresp <= "00";

  -- Assign outputs
  register1_o <= register1_reg;
  block1_register3_o <= block1_register3_reg;

  -- Process for write requests.
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        wr_ack_int <= '0';
        register1_reg <= "0000000000000000000000000000000000000000000000000000000000000000";
        block1_register3_reg <= "00000000000000000000000000000000";
      else
        wr_ack_int <= '0';
        case awaddr(4 downto 3) is
        when "00" => 
          case awaddr(2 downto 2) is
          when "0" => 
            -- Register register1
            if wr_int = '1' then
              register1_reg(31 downto 0) <= wdata;
            end if;
            wr_ack_int <= wr_int;
          when "1" => 
            -- Register register1
            if wr_int = '1' then
              register1_reg(63 downto 32) <= wdata;
            end if;
            wr_ack_int <= wr_int;
          when others =>
            wr_ack_int <= wr_int;
          end case;
        when "10" => 
          case awaddr(2 downto 2) is
          when "0" => 
            -- Register block1_register2
          when "1" => 
            -- Register block1_register3
            if wr_int = '1' then
              block1_register3_reg <= wdata;
            end if;
            wr_ack_int <= wr_int;
          when others =>
            wr_ack_int <= wr_int;
          end case;
        when "11" => 
          case awaddr(2 downto 2) is
          when "0" => 
            -- Register block1_block2_register4
          when others =>
            wr_ack_int <= wr_int;
          end case;
        when others =>
          wr_ack_int <= wr_int;
        end case;
      end if;
    end if;
  end process;

  -- Process for registers read.
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_ack1_int <= '0';
        reg_rdat_int <= (others => 'X');
      else
        reg_rdat_int <= (others => '0');
        case araddr(4 downto 3) is
        when "00" => 
          case araddr(2 downto 2) is
          when "0" => 
            -- register1
            rd_ack1_int <= rd_int;
          when "1" => 
            -- register1
            rd_ack1_int <= rd_int;
          when others =>
            rd_ack1_int <= rd_int;
          end case;
        when "10" => 
          case araddr(2 downto 2) is
          when "0" => 
            -- block1_register2
            reg_rdat_int(0) <= block1_register2_field1_i;
            reg_rdat_int(3 downto 1) <= block1_register2_field2_i;
            rd_ack1_int <= rd_int;
          when "1" => 
            -- block1_register3
            reg_rdat_int <= block1_register3_reg;
            rd_ack1_int <= rd_int;
          when others =>
            rd_ack1_int <= rd_int;
          end case;
        when "11" => 
          case araddr(2 downto 2) is
          when "0" => 
            -- block1_block2_register4
            reg_rdat_int(0) <= block1_block2_register4_field3_i;
            reg_rdat_int(3 downto 1) <= block1_block2_register4_field4_i;
            rd_ack1_int <= rd_int;
          when others =>
            rd_ack1_int <= rd_int;
          end case;
        when others =>
          rd_ack1_int <= rd_int;
        end case;
      end if;
    end if;
  end process;

  -- Process for read requests.
  process (araddr, reg_rdat_int, rd_ack1_int, rd_int) begin
    -- By default ack read requests
    dato <= (others => '0');
    case araddr(4 downto 3) is
    when "00" => 
      case araddr(2 downto 2) is
      when "0" => 
        -- register1
        dato <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when "1" => 
        -- register1
        dato <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
        rd_ack_int <= rd_int;
      end case;
    when "10" => 
      case araddr(2 downto 2) is
      when "0" => 
        -- block1_register2
        dato <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when "1" => 
        -- block1_register3
        dato <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
        rd_ack_int <= rd_int;
      end case;
    when "11" => 
      case araddr(2 downto 2) is
      when "0" => 
        -- block1_block2_register4
        dato <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
        rd_ack_int <= rd_int;
      end case;
    when others =>
      rd_ack_int <= rd_int;
    end case;
  end process;
end syn;
