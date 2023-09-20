-- GEARBOX_08_TO_65.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity GEARBOX_08_TO_65 is
    port(RESETn, CLK_08BIT : in std_logic;
         DATA08 : in std_logic_vector(7 downto 0);
         
         CLK_65BIT : in std_logic;
         DATA65 : out std_logic_vector(64 downto 0);
         DATA65_VALID : out std_logic;
         BYTESLIP : in std_logic;
         BYTESLIP_COUNT : out std_logic_vector(3 downto 0)
         );
end GEARBOX_08_TO_65;

architecture DEF_ARCH of GEARBOX_08_TO_65 is 

  signal counter : std_logic_vector(3 downto 0);
  signal DATA64_temp : std_logic_vector(63 downto 0);
  signal DATA64 : std_logic_vector(63 downto 0);
  signal DATA64_VALID : std_logic;
  
  signal BYTESLIP_cap, BYTESLIP_smpl, BYTESLIP_posedge : std_logic;
  
  component RX_DATASYNC65 is
      port(RESETn, CLK_64BIT : in std_logic;
           VALID_IN : in std_logic;
           DATA_IN : in std_logic_vector(63 downto 0);

           CLK_65BIT : in std_logic;
           DATA_OUT : out std_logic_vector(64 downto 0);
           VALID_OUT : out std_logic);
  end component;
    

  
begin

  process(RESETn, CLK_08BIT)
  begin
    if (RESETn = '0') then
      BYTESLIP_cap <= '0';
      BYTESLIP_smpl <= '0';
    elsif rising_edge(CLK_08BIT) then
      BYTESLIP_cap <= BYTESLIP;
      BYTESLIP_smpl <= BYTESLIP_cap;
    end if;
  end process;
  
  BYTESLIP_posedge <= BYTESLIP_cap and not BYTESLIP_smpl;
  
  process(RESETn, CLK_08BIT)
  begin
    if (RESETn = '0') then
      counter <= X"0";
    elsif rising_edge(CLK_08BIT) then
      if counter = X"7" then
        if BYTESLIP_posedge = '1' then
          counter <= X"1";
        else
          counter <= X"0";
        end if;
      else
        if BYTESLIP_posedge = '1' then
          counter <= counter + 2;
        else
          counter <= counter + 1;
        end if;
      end if;
    end if;
  end process;
  
  process(RESETn, CLK_08BIT)
  begin
    if (RESETn = '0') then
      DATA64_temp <= X"0000000000000000";
      DATA64_VALID <= '0';
    elsif rising_edge(CLK_08BIT) then
      if counter = X"7" then
        DATA64_temp(7 downto 0) <= DATA08;
        DATA64(7 downto 0) <= DATA08;
        DATA64(63 downto 08) <= DATA64_temp(63 downto 08);
        DATA64_VALID <= '1';
      else
        DATA64_temp(7 downto 0) <= DATA64_temp(7 downto 0);
        DATA64 <= DATA64;
        DATA64_VALID <= '0';
      end if;
      
      if counter = X"6" then
        DATA64_temp(15 downto 8) <= DATA08;
      else
        DATA64_temp(15 downto 8) <= DATA64_temp(15 downto 8);
      end if;
      
      if counter = X"5" then
        DATA64_temp(23 downto 16) <= DATA08;
      else
        DATA64_temp(23 downto 16) <= DATA64_temp(23 downto 16);
      end if;
      
      if counter = X"4" then
        DATA64_temp(31 downto 24) <= DATA08;
      else
        DATA64_temp(31 downto 24) <= DATA64_temp(31 downto 24);
      end if;
      
      if counter = X"3" then
        DATA64_temp(39 downto 32) <= DATA08;
      else
        DATA64_temp(39 downto 32) <= DATA64_temp(39 downto 32);
      end if;
      
      if counter = X"2" then
        DATA64_temp(47 downto 40) <= DATA08;
      else
        DATA64_temp(47 downto 40) <= DATA64_temp(47 downto 40);
      end if;
      
      if counter = X"1" then
        DATA64_temp(55 downto 48) <= DATA08;
      else
        DATA64_temp(55 downto 48) <= DATA64_temp(55 downto 48);
      end if;
      
      if counter = X"0" then
        DATA64_temp(63 downto 56) <= DATA08;
      else
        DATA64_temp(63 downto 56) <= DATA64_temp(63 downto 56);
      end if;
      
    end if;
  end process;
  
    
  uRX_DATASYNC : RX_DATASYNC65
    port map(RESETn => RESETn,
             CLK_64BIT => CLK_08BIT, 
             VALID_IN => DATA64_VALID,
             DATA_IN => DATA64,
             
             CLK_65BIT => CLK_65BIT,
             DATA_OUT => DATA65,
             VALID_OUT => DATA65_VALID
            );

end DEF_ARCH; 
