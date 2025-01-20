library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CLK_div_100 is
    port (
        clk_in  : in  std_logic; -- 100MHz input clock
        clk_out : buffer std_logic -- 1MHz output clock
    );
end entity CLK_div_100;

architecture rtl of CLK_div_100 is
    constant DIVISOR : natural := 50;
    signal count    : unsigned(5 downto 0);
begin
    process(clk_in)
    begin
        if rising_edge(clk_in) then
            count <= count + 1;
            
            if count = DIVISOR then
                count <= (others => '0');
                clk_out <= not clk_out;
            end if;
        end if;
    end process;
end architecture rtl;