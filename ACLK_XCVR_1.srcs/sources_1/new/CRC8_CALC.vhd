-- CRC8_CALC.vhd

--  This IS NOT a general-purpose CRC calculator.
--  This specifically takes a 48-bit parallel input and does an 8-bit CRC calculation
--  on it as though the input were 6 separate 8-bit bytes.
--
--  Logically, this can all happen in one clock cycle but there's no reason it has to.
--  For our application, we're assuming this will happen every 4th or 8th tick of a master clock.
--  To make timing it may make sense to tell the compiler to allow muliticycle paths.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CRC8_CALC is
    port(CLK, RESETn : in std_logic;
         CALC : in std_logic;
         DATA : in std_logic_vector(55 downto 0);
         CRC : out std_logic_vector(7 downto 0);
         CRC_VALID : out std_logic);
end CRC8_CALC;

architecture DEF_ARCH of CRC8_CALC is 

  signal data_reg : std_logic_vector(55 downto 0);
  signal calc0, calc1 : std_logic;
  signal CRC_int, crc_calc : std_logic_vector(7 downto 0);
  
--  type slv_array is array (0 to 50) of std_logic_vector(7 downto 0);
--  signal crc_steps : slv_array;

begin

  process(RESETn, CLK)
  begin
    if RESETn = '0' then
      data_reg <= X"00000000000000";
      
    elsif rising_edge(CLK) then
      if CALC = '1' then
--        data_reg <= DATA & X"00";
        data_reg <= DATA;
      else
        data_reg <= data_reg;
      end if;
    end if;
  end process;
  
  process(data_reg)
    variable result : std_logic_vector(7 downto 0);
    
  begin
    result := not(data_reg(55 downto 48));
--    result :=      (data_reg(55 downto 48));
--    crc_steps(0) <= result;
    
    for i in 55 downto 8 loop
      if result(7) = '1' then
        result := (result(6 downto 0) & data_reg(i-8)) xor X"2F";
      else
        result := (result(6 downto 0) & data_reg(i-8));
      end if;
--      crc_steps(56-i) <= result;
    end loop;

    crc_calc <= result;
    
  end process;
  
  
  process(RESETn, CLK)
  begin
    if RESETn = '0' then
      calc0 <= '0';
      calc1 <= '0';
      
    elsif rising_edge(CLK) then
      calc0 <= CALC;
      calc1 <= calc0;
    end if;
  end process;
  
  process(RESETn, CLK)
  begin
    if RESETn = '0' then
      CRC_int <= X"00";
      
    elsif rising_edge(CLK) then
      if calc0 = '1' then
        CRC_int <= crc_calc;
      else
        CRC_int <= CRC_int;
      end if;
    end if;
  end process;
  
  CRC <= CRC_int;
  CRC_VALID <= calc1;
  
end DEF_ARCH; 







