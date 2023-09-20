-- MOD_MANCH_ENC65.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MOD_MANCH_ENC65 is

    port(CLK, RESETn : in std_logic;
         ENCODE : in std_logic;
         DATA48_IN : in std_logic_vector(47 downto 0);
         CRC_IN : in std_logic_vector(7 downto 0);
         DATA_OUT : out std_logic_vector(129 downto 0);
         DATA_OUT_VALID : out std_logic
         );

end MOD_MANCH_ENC65;

architecture DEF_ARCH of MOD_MANCH_ENC65 is 

  signal encoder : std_logic_vector(129 downto 0);
  signal DATA48_IN_reg : std_logic_vector(47 downto 0);
  signal CRC_IN_reg : std_logic_vector(7 downto 0);
  signal DATA_OUT_int : std_logic_vector(129 downto 0);
  signal data_in_valid, DATA_OUT_VALID_int : std_logic;

begin

  process(RESETn, CLK)
  begin
    if RESETn = '0' then
      DATA48_IN_reg <= (others => '0');
      CRC_IN_reg <= (others => '0');
      data_in_valid <= '0';
    elsif rising_edge(CLK) then
      if ENCODE = '1' then
        DATA48_IN_reg <= DATA48_IN;
        CRC_IN_reg <= CRC_IN;
        data_in_valid <= '1';
      else
        DATA48_IN_reg <= DATA48_IN_reg;
        CRC_IN_reg <= CRC_IN_reg;
        data_in_valid <= '0';
      end if;
    end if;
  end process;
  
  process(DATA48_IN_reg, CRC_IN_reg, encoder) is
  begin
  -- Two leading zeros
    encoder(129) <= '1';
    encoder(128) <= '1';
    encoder(127) <= '0';
    encoder(126) <= '0';
  
  -- 48 Data Bits (16 + 32)    
    for i in 62 downto 15 loop
      encoder(2*i+1) <= not encoder(2*i+2);
      encoder(2*i)   <= encoder(2*i+1) xor DATA48_IN_reg(i-15);
    end loop;
    
  -- 8-bit CRC  
    for i in 14 downto 7 loop
      encoder(2*i+1) <= not encoder(2*i+2);
      encoder(2*i)   <= encoder(2*i+1) xor CRC_IN_reg(i-7);
    end loop;
    
  -- Parity Bit - Always restore clock phase  
    encoder(13) <= not encoder(14);
    encoder(12) <= '0';
    
  -- Pad remaining 6 bits  
    for i in 5 downto 0 loop
      encoder(2*i+1) <= '1';
      encoder(2*i)   <= '0';
    end loop;
    
  end process;
  
  process(RESETn, CLK)
  begin
    if RESETn = '0' then
      DATA_OUT_int <= (others => '0');
      DATA_OUT_VALID_int <= '0';
    elsif rising_edge(CLK) then
      DATA_OUT_int <= encoder;
      DATA_OUT_VALID_int <= data_in_valid;
    end if;
  end process;
  
  DATA_OUT <= DATA_OUT_int;
  DATA_OUT_VALID <= DATA_OUT_VALID_int;

end DEF_ARCH; 
