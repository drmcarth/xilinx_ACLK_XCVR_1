-- GEARBOX_130_TO_16.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity GEARBOX_130_TO_16 is

    port(RESETn, CLK_130BIT : in std_logic;
         VALID_IN : in std_logic;
         DATA_IN : in std_logic_vector(129 downto 0);
         
         CLK_16BIT : in std_logic;
         DATA_OUT : out std_logic_vector(15 downto 0)
         );


end GEARBOX_130_TO_16;

architecture DEF_ARCH of GEARBOX_130_TO_16 is 

  signal counter : std_logic_vector(11 downto 0);
  signal calc_index : integer := 0;
  
  signal regA, regB : std_logic_vector(129 downto 0);
  signal regQ, regQ2 : std_logic_vector(127 downto 0);
  signal regQ_del1, regQ_del2, regQ_del3, regQ_del4 : std_logic_vector(127 downto 0);
  signal regQ2_flag_130bit : std_logic;

  signal regQ2_flag_128bit, regQ2_flag_128bit_reg : std_logic;
  signal regQ2_flag_128bit_stb0,regQ2_flag_128bit_stb1, regQ2_flag_128bit_stb2, regQ2_flag_128bit_stb3 : std_logic;
  signal data_out_sync_ctr : std_logic_vector(1 downto 0);
  signal data_out_sync_ctr_marker : std_logic;
  signal data128refctr : std_logic_vector(11 downto 0);
  signal data128refctr_mark : std_logic;
  signal data128refctr_mark0, data128refctr_mark1, data128refctr_mark2, data128refctr_mark3 : std_logic;
  signal data_out_mux_sel : std_logic_vector(3 downto 0);
  signal VALID_OUT_int : std_logic;
  signal data128 : std_logic_vector(127 downto 0);
  signal tx_data_select : std_logic_vector(2 downto 0);

  
begin

  process(RESETn, CLK_130BIT)
  begin
    if (RESETn = '0') then
      counter <= X"000";
    elsif rising_edge(CLK_130BIT) then
      if VALID_IN = '1' then
        if counter = X"03F" then
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
      
  process(RESETn, CLK_130BIT)
  begin
    if (RESETn = '0') then
      regA <= (others => '0');
      regB <= (others => '0');
    elsif rising_edge(CLK_130BIT) then
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
-- Transform a 130-bit x 64-word array into a 128-bit x 65-word
--  array for transmission:
--
--  0  D00-129 .................................. D00-02
--  1  D00-01 D00-00 D01-129 .................... D01-04
--  2  D01-03 ... D01-00 D02-129 ................ D02-06
--
-- 63  D62-125 .................. D62-00 D63-129 D63-128
-- 64  D63-127 .................................. D63-00
--------------------------------------------------------------------------
  process(RESETn, CLK_130BIT)
  begin
    if (RESETn = '0') then
      regQ <= (others => '0');
      regQ2 <= (others => '0');
      regQ2_flag_130bit <= '0';
    elsif rising_edge(CLK_130BIT) then
        if calc_index = 0 then
          regQ <= regA(129 downto 2);
        else
--          regQ <= regB((2*calc_index-1) downto 0) & regA(129 downto (2*calc_index+2)); -- Vivado can't synthesize this - break it up
          regQ(127 downto 128-2*calc_index) <= regB((2*calc_index-1) downto 0);
          regQ(128-2*calc_index-1 downto 0) <= regA(129 downto (2*calc_index+2));
        end if;
        
        if calc_index = 63 then
          regQ2_flag_130bit <= '1';
          regQ2 <= regA(127 downto 0);
        else
          regQ2_flag_130bit <= '0';
          regQ2 <= regQ2;
        end if;
    end if;
  end process;
  
  process(RESETn, CLK_130BIT)
  begin
    if RESETn = '0' then
      regQ_del1 <= (others => '0');
      regQ_del2 <= (others => '0');
      regQ_del3 <= (others => '0');
      regQ_del4 <= (others => '0');
    elsif rising_edge(CLK_130BIT) then
      regQ_del1 <= regQ;
      regQ_del2 <= regQ_del1;
      regQ_del3 <= regQ_del2;
      regQ_del4 <= regQ_del3;
    end if;
  end process;
  
--------------------------------------------------------------------------
--------------------------------------------------------------------------

  process(RESETn, CLK_16BIT)
  begin
    if RESETn = '0' then
      regQ2_flag_128bit <= '0';
      regQ2_flag_128bit_reg <= '0';
    elsif rising_edge(CLK_16BIT) then
      regQ2_flag_128bit <= regQ2_flag_130bit;
      regQ2_flag_128bit_reg <= regQ2_flag_128bit;
    end if;
  end process;
  
  process(RESETn, CLK_16BIT)
  begin
    if (RESETn = '0') then
      regQ2_flag_128bit_stb0 <= '0';
      regQ2_flag_128bit_stb1 <= '0';
      regQ2_flag_128bit_stb2 <= '0';
      regQ2_flag_128bit_stb3 <= '0';
    elsif rising_edge(CLK_16BIT) then
      regQ2_flag_128bit_stb0 <= regQ2_flag_128bit and (not regQ2_flag_128bit_reg);
      regQ2_flag_128bit_stb1 <= regQ2_flag_128bit_stb0;
      regQ2_flag_128bit_stb2 <= regQ2_flag_128bit_stb1;
      regQ2_flag_128bit_stb3 <= regQ2_flag_128bit_stb2;
    end if;
  end process;
  
--  process(RESETn, CLK_16BIT)
--  begin
--    if (RESETn = '0') then
--      data_out_sync_ctr <= "00";
--    elsif rising_edge(CLK_16BIT) then
--      if regQ2_flag_128bit_stb0 = '1' then
--        data_out_sync_ctr <= "00";
--      else
--        data_out_sync_ctr <= data_out_sync_ctr + 1;
--      end if;
--    end if;
--  end process;
  
--  data_out_sync_ctr_marker <= not (data_out_sync_ctr(1) or data_out_sync_ctr(0));

  process(RESETn, CLK_16BIT)
  begin
    if (RESETn = '0') then
      data128refctr <= X"000";
    elsif rising_edge(CLK_16BIT) then
      if regQ2_flag_128bit_stb0 = '1' then
        data128refctr <= X"000";
--      elsif data128refctr = X"103" then
      elsif data128refctr = X"207" then  -- 519 = 520-1
        data128refctr <= X"000";
      else
        data128refctr <= data128refctr + 1;
      end if;
    end if;
  end process;

  process(data128refctr)
  begin
--    if data128refctr = X"103" then
    if data128refctr = X"207" then
      data128refctr_mark <= '1';
    else
      data128refctr_mark <= '0';
    end if;

    if data128refctr(2 downto 0) = "000" then
      data128refctr_mark0 <= '1';
    else
      data128refctr_mark0 <= '0';
    end if;

    if data128refctr(2 downto 0) = "001" then
      data128refctr_mark1 <= '1';
    else
      data128refctr_mark1 <= '0';
    end if;

    if data128refctr(2 downto 0) = "010" then
      data128refctr_mark2 <= '1';
    else
      data128refctr_mark2 <= '0';
    end if;

    if data128refctr(2 downto 0) = "011" then
      data128refctr_mark3 <= '1';
    else
      data128refctr_mark3 <= '0';
    end if;

  end process;
  
  process(RESETn, CLK_16BIT)
  begin
    if (RESETn = '0') then
      data_out_mux_sel <= X"0";
    elsif rising_edge(CLK_16BIT) then
      case data128refctr is
        when X"009" =>
          data_out_mux_sel <= X"0";
          
--        when X"045" =>
        when X"089" =>
          data_out_mux_sel <= X"1";
          
--        when X"085" =>
        when X"109" =>
          data_out_mux_sel <= X"2";
          
--        when X"0C5" =>
        when X"189" =>
          data_out_mux_sel <= X"3";
          
        when X"001" =>
          data_out_mux_sel <= X"4";
          
        when others =>
          data_out_mux_sel <= data_out_mux_sel;
      end case;
    end if;
  end process;
  
  process(RESETn, CLK_16BIT)
  begin
    if RESETn = '0' then
      data128 <= (others => '0');
    elsif rising_edge(CLK_16BIT) then
      if data128refctr_mark0 = '1' then
        case data_out_mux_sel is
          when X"0" =>
            data128 <= regQ_del4;
        
          when X"1" =>
            data128 <= regQ_del3;
        
          when X"2" =>
            data128 <= regQ_del2;
        
          when X"3" =>
            data128 <= regQ_del1;
        
          when X"4" =>
            data128 <= regQ2;
        
          when others =>
            data128 <= (others => '0');
        end case;
      else
        data128 <= data128;
      end if;
    end if;
  end process;

  process(data128, tx_data_select)
  begin
    if tx_data_select = "000" then
      DATA_OUT <= data128(127 downto 112);
    elsif tx_data_select = "001" then
      DATA_OUT <= data128(111 downto 96);
    elsif tx_data_select = "010" then
      DATA_OUT <= data128(95 downto 80);
    elsif tx_data_select = "011" then
      DATA_OUT <= data128(79 downto 64);
    elsif tx_data_select = "100" then
      DATA_OUT <= data128(63 downto 48);
    elsif tx_data_select = "101" then
      DATA_OUT <= data128(47 downto 32);
    elsif tx_data_select = "110" then
      DATA_OUT <= data128(31 downto 16);
    else
      DATA_OUT <= data128(15 downto 0);
    end  if;
  end process;
  

--  process(RESETn, CLK_16BIT)
--  begin
--    if (RESETn = '0') then
--      VALID_OUT_int <= '0';
--    elsif rising_edge(CLK_16BIT) then
--      VALID_OUT_int <= data128refctr_mark0;
--    end if;
--  end process;
  
--  VALID_OUT <= VALID_OUT_int;

  process(RESETn, CLK_16BIT)
  begin
    if RESETn = '0' then
      tx_data_select <= "000";
    elsif rising_edge(CLK_16BIT) then
--      if VALID_OUT_int = '1' then
      if data128refctr_mark0 = '1' then
        tx_data_select <= "000";
      else
        tx_data_select <= tx_data_select + 1;
      end if;
    end if;
  end process;
  


  
    
    
end DEF_ARCH; 
