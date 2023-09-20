-- LFSR48.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity LFSR48 is
    port(CLK, RESETn : in std_logic;
         ADV : in std_logic;
         LOAD : in std_logic;
         D : in std_logic_vector(47 downto 0);
         Q : out std_logic_vector(47 downto 0)
         );
end LFSR48;

architecture DEF_ARCH of LFSR48 is 

  signal Q_int : std_logic_vector(47 downto 0);

begin

  process(RESETn, CLK)
  begin
    if RESETn = '0' then
      Q_int <= X"000000000000";
      
    elsif rising_edge(CLK) then
      if LOAD = '1' then
        Q_int <= D;
        
      else
        if ADV = '1' then
          Q_int(47 downto 1) <= Q_int(46 downto 0);
          
          if Q_int = X"FFFFFFFFFFFF" then
            Q_int(0) <= '0';
          else
            Q_int(0) <= Q_int(47) xnor Q_int(46) xnor Q_int(20) xnor Q_int(19);
          end if;
        else
          Q_int <= Q_int;
        end if;
        
      end if;
      
    end if;
  end process;
  
  Q <= Q_int;
  
end DEF_ARCH; 
