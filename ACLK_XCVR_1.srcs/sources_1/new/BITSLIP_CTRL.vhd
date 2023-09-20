-- BITSLIP_CTRL.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity BITSLIP_CTRL is

    port(CLK65, RESETn : in std_logic;
         ALIGNED_IN, VALID_IN : in std_logic;
         BITSLIP, BYTESLIP : out std_logic
         );

end BITSLIP_CTRL;

architecture DEF_ARCH of BITSLIP_CTRL is 

  signal retry_timer : std_logic_vector(7 downto 0);
  signal bitslip_counter : std_logic_vector(7 downto 0);
  signal BITSLIP_int,  bitslip72 : std_logic;
  signal BYTESLIP_int, byteslip_int_reg : std_logic;
  
begin

  process(RESETn, CLK65)
  begin
    if RESETn = '0' then
      retry_timer <= X"00";
    elsif rising_edge(CLK65) then
      if retry_timer = X"7F" then
        retry_timer <= X"00";
      elsif (BITSLIP_int = '1') or (retry_timer /= X"00") then
        retry_timer <= retry_timer+1;
      else
        retry_timer <= retry_timer;
      end if;
    end if;
  end process;
  
  process(ALIGNED_IN, VALID_IN, retry_timer)
  begin
    if (VALID_IN = '1') and (ALIGNED_IN = '0') and (retry_timer = X"00") then
      BITSLIP_int <= '1';
    else
      BITSLIP_int <= '0';
    end if;
  end process;
  
  process(RESETn, CLK65)
  begin
    if RESETn = '0' then
      bitslip72 <= '0';
    elsif rising_edge(CLK65) then
      if (BITSLIP_int = '1') or (retry_timer = X"01") then
        bitslip72 <= '1';
      else
        bitslip72 <= '0';
      end if;
    end if;
  end process;
  
  BITSLIP <= bitslip72;
  
  process(RESETn, CLK65)
  begin
    if RESETn = '0' then
      bitslip_counter <= X"00";
    elsif rising_edge(CLK65) then
      if BITSLIP_int = '1' then
        bitslip_counter <= bitslip_counter + 1;
      else
        bitslip_counter <= bitslip_counter;
      end if;
    end if;
  end process;

--   process(BITSLIP_int, bitslip_counter)
--   begin
--     if (BITSLIP_int = '1') and (bitslip_counter(3 downto 0) = "1111") then
--       BYTESLIP_int <= '1';
--     else
--       BYTESLIP_int <= '0';
--     end if;
--   end process;
  
--   process(RESETn, CLK65)
--   begin
--     if RESETn = '0' then
--       byteslip_int_reg <= '0';
--       byteslip72 <= '0';
--     elsif rising_edge(CLK65) then
--       byteslip_int_reg <= BYTESLIP_int;
--       byteslip72 <= BYTESLIP_int or byteslip_int_reg;
--     end if;
--   end process;
  
--  BYTESLIP <= byteslip72;

  process(RESETn, CLK65)
  begin
    if RESETn = '0' then
      BYTESLIP_int <= '0';
    elsif rising_edge(CLK65) then
      if (BITSLIP_int = '1') and (bitslip_counter(3 downto 0) = "1111") then
        BYTESLIP_int <= '1';
      else
        BYTESLIP_int <= '0';
      end if;
    end if;
  end process;
  
  -- Use byteslip_int_reg to stretch BYTESLIP to 2 clocks long
  process(RESETn, CLK65)
  begin
    if RESETn = '0' then
      byteslip_int_reg <= '0';
    elsif rising_edge(CLK65) then
      byteslip_int_reg <= BYTESLIP_int;
    end if;
  end process;

  process(RESETn, CLK65)
  begin
    if RESETn = '0' then
      BYTESLIP <= '0';
    elsif rising_edge(CLK65) then
      BYTESLIP <= BYTESLIP_int or byteslip_int_reg;
    end if;
  end process;
  
end DEF_ARCH; 
