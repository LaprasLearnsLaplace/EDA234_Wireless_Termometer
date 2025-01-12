library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity temp_comparator is
    Port ( 
        clk : in STD_LOGIC;                                    
        rst : in STD_LOGIC;                                   
        temp_set : in STD_LOGIC_VECTOR(7 downto 0);          
        ADT7420_DATA : in STD_LOGIC_VECTOR(7 downto 0);      
        DS18S20_DATA : in STD_LOGIC_VECTOR(7 downto 0);                                    
        ADT7420_alarm : out STD_LOGIC;                      
        DS18S20_alarm : out STD_LOGIC                         
    );
end temp_comparator;

architecture Behavioral of temp_comparator is

    signal temp_set_signed : signed(7 downto 0);
    signal ADT7420_signed : signed(7 downto 0);
    signal DS18S20_signed : signed(7 downto 0);

    -- component printf
    -- port (
    --   clk       : in std_logic;
    --   probe_in0 : in std_logic_vector(7 downto 0)
    -- );
    -- end component;
    
begin
    
    temp_set_signed <= signed(temp_set);
    ADT7420_signed <= signed(ADT7420_DATA);
    DS18S20_signed <= signed(DS18S20_DATA);
    
    -- print3 : printf
    -- port map
    -- (
    --   clk       => clk,
    --   probe_in0 => temp_set
    -- );


    process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ADT7420_alarm <= '0';
                DS18S20_alarm <= '0';
            else
                if temp_set_signed = "00000000" then
                    ADT7420_alarm <= '0';
                elsif ADT7420_signed >= temp_set_signed then
                    ADT7420_alarm <= '1';
                else
                    ADT7420_alarm <= '0';
                end if;
                
                if temp_set_signed = "00000000" then
                    DS18S20_alarm <= '0';
                elsif DS18S20_signed >= temp_set_signed then
                    DS18S20_alarm <= '1';
                else
                    DS18S20_alarm <= '0';
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;