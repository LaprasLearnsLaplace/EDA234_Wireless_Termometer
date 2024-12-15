----------------------------------------------------------------------------------
-- Group: Group 1
-- Engineer: Ziheng Li
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_200KHz is
    Port (
        clk_100MHz : in std_logic; 
        clk_200KHz : out std_logic 
    );
end clk_200KHz;

architecture arch_clk_200KHz of clk_200KHz is
    signal counter : unsigned(7 downto 0) := (others => '0');
    signal clk_reg : std_logic := '1'; 
begin
    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if counter = 249 then 
                counter <= (others => '0'); 
                clk_reg <= not clk_reg; 
            else
                counter <= counter + 1; 
            end if;
        end if;
    end process;

    clk_200KHz <= clk_reg; 
end arch_clk_200KHz;
