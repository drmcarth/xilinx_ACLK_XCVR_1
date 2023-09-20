-- MOD_MANCH_DEC08.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MOD_MANCH_DEC08 is

    port(CLK, RESETn : in std_logic;
         DATA_IN : in std_logic_vector(15 downto 0);
         DATA_OUT : out std_logic_vector(7 downto 0)
         );

end MOD_MANCH_DEC08;

architecture DEF_ARCH of MOD_MANCH_DEC08 is 

  signal decoder : std_logic_vector(7 downto 0);
  signal DATA_OUT_int : std_logic_vector(7 downto 0);

begin

  process(RESETn, CLK)
  begin
    if RESETn = '0' then
      DATA_OUT_int <= X"00";
    elsif rising_edge(CLK) then
      DATA_OUT_int <= decoder;

    end if;
  end process;
  
  process(DATA_IN)
  begin
--     decoder(15) <= DATA_IN(31) xor DATA_IN(30);
--     decoder(14) <= DATA_IN(29) xor DATA_IN(28);
--     decoder(13) <= DATA_IN(27) xor DATA_IN(26);
--     decoder(12) <= DATA_IN(25) xor DATA_IN(24);
--     decoder(11) <= DATA_IN(23) xor DATA_IN(22);
--     decoder(10) <= DATA_IN(21) xor DATA_IN(20);
--     decoder( 9) <= DATA_IN(19) xor DATA_IN(18);
--     decoder( 8) <= DATA_IN(17) xor DATA_IN(16);
    decoder( 7) <= DATA_IN(15) xor DATA_IN(14);
    decoder( 6) <= DATA_IN(13) xor DATA_IN(12);
    decoder( 5) <= DATA_IN(11) xor DATA_IN(10);
    decoder( 4) <= DATA_IN( 9) xor DATA_IN( 8);
    decoder( 3) <= DATA_IN( 7) xor DATA_IN( 6);
    decoder( 2) <= DATA_IN( 5) xor DATA_IN( 4);
    decoder( 1) <= DATA_IN( 3) xor DATA_IN( 2);
    decoder( 0) <= DATA_IN( 1) xor DATA_IN( 0);
  end process;

  DATA_OUT <= DATA_OUT_int;

end DEF_ARCH; 
