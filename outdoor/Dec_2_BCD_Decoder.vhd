library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Dec_2_BCD_Decoder is
    port (
        hr_in   : in  std_logic_vector(4 downto 0);
        min_in  : in  std_logic_vector(5 downto 0);
        sec_in  : in  std_logic_vector(5 downto 0);
        hr_out  : out std_logic_vector(7 downto 0);
        min_out : out std_logic_vector(7 downto 0);
        sec_out : out std_logic_vector(7 downto 0)
    );
end entity Dec_2_BCD_Decoder;

architecture rtl of Dec_2_BCD_Decoder is
begin
    process(hr_in, min_in, sec_in)
        variable hr_int  : integer;
        variable min_int : integer;
        variable sec_int : integer;
    begin
        -- Convert std_logic_vector to integer
        hr_int  := to_integer(unsigned(hr_in));
        min_int := to_integer(unsigned(min_in));
        sec_int := to_integer(unsigned(sec_in));
        
        -- Calculate BCD values and convert back to std_logic_vector
        hr_out  <= std_logic_vector(to_unsigned((hr_int/10) * 16 + (hr_int mod 10), 8));
        min_out <= std_logic_vector(to_unsigned((min_int/10) * 16 + (min_int mod 10), 8));
        sec_out <= std_logic_vector(to_unsigned((sec_int/10) * 16 + (sec_int mod 10), 8));
    end process;
end architecture rtl;