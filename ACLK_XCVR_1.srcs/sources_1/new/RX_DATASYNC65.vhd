-- RX_DATASYNC65.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity RX_DATASYNC65 is
    port(RESETn, CLK_64BIT : in std_logic;
         VALID_IN : in std_logic;
         DATA_IN : in std_logic_vector(63 downto 0);
         
         CLK_65BIT : in std_logic;
         DATA_OUT : out std_logic_vector(64 downto 0);
         VALID_OUT : out std_logic);
end RX_DATASYNC65;

architecture DEF_ARCH of RX_DATASYNC65 is 

  signal counter : std_logic_vector(11 downto 0);
  signal calc_index : integer := 0;
  
  signal regA, regB : std_logic_vector(63 downto 0);
  signal regQ : std_logic_vector(64 downto 0);
  signal regQ_del1, regQ_del2, regQ_del3, regQ_del4 : std_logic_vector(64 downto 0);
  signal sync64 : std_logic;
  
  signal sync64_cap, sync64_smpl, sync65 : std_logic;
  signal data65refctr : std_logic_vector(11 downto 0);
  signal data65refctr_mark : std_logic;
  signal data65refctr_mark0, data65refctr_mark1, data65refctr_mark2, data65refctr_mark3 : std_logic;
  signal data_out_mux_sel : std_logic_vector(3 downto 0);
  signal VALID_OUT_int : std_logic;
  signal DATA_OUT_int : std_logic_vector(64 downto 0);

  
begin

  process(RESETn, CLK_64BIT)
  begin
    if (RESETn = '0') then
      counter <= X"000";
    elsif rising_edge(CLK_64BIT) then
      if VALID_IN = '1' then
        if counter = X"040" then
          counter <= X"000";
        else
          counter <= counter + 1;
        end if;
      else
        counter <= counter;
      end if;
    end if;
  end process;
  
  calc_index <= to_integer(unsigned(counter));
      
  process(RESETn, CLK_64BIT)
  begin
    if (RESETn = '0') then
      regA <= (others => '0');
      regB <= (others => '0');
    elsif rising_edge(CLK_64BIT) then
      if VALID_IN = '1' then
        regA <= DATA_IN;
        regB <= regA;
      else
        regA <= regA;
        regB <= regB;
      end if;
    end if;
  end process;
  
--------------------------------------------------------------------------
-- Transform a 64-bit x 65-word array into a 65-bit x 64-word
--  array for transmission:
--
--  0  D00-63 ........................... D00-00 D01-63
--  1  D01-62 .................... D01-00 D02-63 D02-62
--  2  D02-61 ............. D02-00 D03-63 ...... D03-61
--
-- 62  D62-01 D62-00 D63-63..................... D63-01
-- 63  D63-00 D64-63............................ D64-00
--------------------------------------------------------------------------
  process(RESETn, CLK_64BIT)
  begin
    if (RESETn = '0') then
      regQ <= (others => '0');
      sync64 <= '0';
    elsif rising_edge(CLK_64BIT) then
      if calc_index = 0 then
        regQ <= regQ;
      else
--        regQ <= regB((64-calc_index) downto 0) & regA(63 downto (64-calc_index)); -- Vivado can't synthesize this - break it up
        regQ(64 downto calc_index) <= regB((64-calc_index) downto 0);
        regQ(calc_index-1 downto 0) <= regA(63 downto (64-calc_index));
      end if;

-- counter will hold each value, including X"000" for multiple clocks
--  while it waits for the next VALID_IN.  Thus, sync64 will be stretched
--  multiple clocks.  When sync64 passes into the CLK_65BIT domain (sync64_cap),
--  a multi-cycle path can be declared to take care of timing issues.
      if counter = X"000" then
        sync64 <= '1';
      else
        sync64 <= '0';
      end if;
    end if;
  end process;
  
  process(RESETn, CLK_64BIT)
  begin
    if RESETn = '0' then
      regQ_del1 <= (others => '0');
      regQ_del2 <= (others => '0');
      regQ_del3 <= (others => '0');
      regQ_del4 <= (others => '0');
    elsif rising_edge(CLK_64BIT) then
      regQ_del1 <= regQ;
      regQ_del2 <= regQ_del1;
      regQ_del3 <= regQ_del2;
      regQ_del4 <= regQ_del3;
    end if;
  end process;
  
  process(RESETn, CLK_65BIT)
  begin
    if RESETn = '0' then
      sync64_cap <= '0';
      sync64_smpl <= '0';
    elsif rising_edge(CLK_65BIT) then
      sync64_cap <= sync64;
      sync64_smpl <= sync64_cap;
    end if;
  end process;
  
  sync65 <= sync64_cap and (not sync64_smpl);
  
  process(RESETn, CLK_65BIT)
  begin
    if (RESETn = '0') then
      data65refctr <= X"000";
    elsif rising_edge(CLK_65BIT) then
       if sync65 = '1' then
         data65refctr <= X"000";
       elsif data65refctr = X"0FF" then
         data65refctr <= X"000";
       else
         data65refctr <= data65refctr + 1;
       end if;
    end if;
  end process;

  process(data65refctr)
  begin
    if data65refctr = X"0FF" then
      data65refctr_mark <= '1';
    else
      data65refctr_mark <= '0';
    end if;

    if data65refctr(2 downto 0) = "000" then
      data65refctr_mark0 <= '1';
    else
      data65refctr_mark0 <= '0';
    end if;

    if data65refctr(2 downto 0) = "001" then
      data65refctr_mark1 <= '1';
    else
      data65refctr_mark1 <= '0';
    end if;

    if data65refctr(2 downto 0) = "010" then
      data65refctr_mark2 <= '1';
    else
      data65refctr_mark2 <= '0';
    end if;

    if data65refctr(2 downto 0) = "011" then
      data65refctr_mark3 <= '1';
    else
      data65refctr_mark3 <= '0';
    end if;

  end process;
  
  process(RESETn, CLK_65BIT)
  begin
    if (RESETn = '0') then
      data_out_mux_sel <= X"0";
    elsif rising_edge(CLK_65BIT) then
      case data65refctr is
        when X"001" =>
          data_out_mux_sel <= X"0";
          
        when X"041" =>
          data_out_mux_sel <= X"1";
          
        when X"081" =>
          data_out_mux_sel <= X"2";
          
        when X"0C1" =>
          data_out_mux_sel <= X"3";
          
        when others =>
          data_out_mux_sel <= data_out_mux_sel;
      end case;
    end if;
  end process;
  
  process(RESETn, CLK_65BIT)
  begin
    if RESETn = '0' then
      DATA_OUT_int <= (others => '0');
    elsif rising_edge(CLK_65BIT) then
      if data65refctr_mark0 = '1' then
        case data_out_mux_sel is
          when X"0" =>
            DATA_OUT_int <= regQ_del1;
        
          when X"1" =>
            DATA_OUT_int <= regQ_del2;
        
          when X"2" =>
            DATA_OUT_int <= regQ_del3;
        
          when X"3" =>
            DATA_OUT_int <= regQ_del4;
        
          when others =>
            DATA_OUT_int <= (others => '0');
        end case;
      else
        DATA_OUT_int <= DATA_OUT_int;
      end if;
    end if;
  end process;
  
  DATA_OUT <= DATA_OUT_int;

  process(RESETn, CLK_65BIT)
  begin
    if (RESETn = '0') then
      VALID_OUT_int <= '0';
    elsif rising_edge(CLK_65BIT) then
      VALID_OUT_int <= data65refctr_mark0;
    end if;
  end process;
  
  VALID_OUT <= VALID_OUT_int;
    
end DEF_ARCH; 
