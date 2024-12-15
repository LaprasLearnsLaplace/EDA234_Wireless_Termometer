----------------------------------------------------------------------------------
-- Group: Group 1
-- Engineer: Ziheng Li
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7 is
    port (
        clk        : in std_logic;              
        data       : in std_logic_vector(7 downto 0); 
        SEG        : out std_logic_vector(6 downto 0); 
        AN         : out std_logic_vector(7 downto 0)  
    );
end seg7;

architecture arch_seg7 of seg7 is

    constant ZERO  : std_logic_vector(6 downto 0) := "0000001";  -- 0
    constant ONE   : std_logic_vector(6 downto 0) := "1001111";  -- 1
    constant TWO   : std_logic_vector(6 downto 0) := "0010010";  -- 2 
    constant THREE : std_logic_vector(6 downto 0) := "0000110";  -- 3
    constant FOUR  : std_logic_vector(6 downto 0) := "1001100";  -- 4
    constant FIVE  : std_logic_vector(6 downto 0) := "0100100";  -- 5
    constant SIX   : std_logic_vector(6 downto 0) := "0100000";  -- 6
    constant SEVEN : std_logic_vector(6 downto 0) := "0001111";  -- 7
    constant EIGHT : std_logic_vector(6 downto 0) := "0000000";  -- 8
    constant NINE  : std_logic_vector(6 downto 0) := "0000100";  -- 9
    constant DEG   : std_logic_vector(6 downto 0) := "0011100";  -- degree symbol
    constant C_sym : std_logic_vector(6 downto 0) := "0110001";  -- C

    signal tens, ones : unsigned(3 downto 0);
    signal anode_select   : unsigned(2 downto 0) := (others => '0');
    signal anode_timer    : unsigned(16 downto 0) := (others => '0');

begin

    compute_digits: process(data) 
        variable data_int : integer;
    begin
        data_int := to_integer(unsigned(data));
        tens <= to_unsigned(data_int / 10, 4);
        ones <= to_unsigned(data_int mod 10, 4);
    end process;

    anode_control: process(clk)
    begin
        if rising_edge(clk) then
            if anode_timer = to_unsigned(99999, 17) then
                anode_timer <= (others => '0');
                anode_select <= anode_select + 1;
            else
                anode_timer <= anode_timer + 1;
            end if;
        end if;
    end process;

    anode_output: process(anode_select)
    begin
        case anode_select is
            when "000" => AN <= "11111110";
            when "001" => AN <= "11111101";
            when "010" => AN <= "11111011";
            when "011" => AN <= "11110111";
            when "100" => AN <= "11101111";
            when "101" => AN <= "11011111";
            when "110" => AN <= "10111111";
            when "111" => AN <= "01111111";
            when others => AN <= (others => '1'); 
        end case;
    end process;

    seg_output: process(anode_select, tens, ones)
    begin
        case anode_select is
            when "000" => SEG <= C_sym; 
            when "001" => SEG <= DEG;   
            when "010" =>
                case ones is
                    when "0000" => SEG <= ZERO;
                    when "0001" => SEG <= ONE;
                    when "0010" => SEG <= TWO;
                    when "0011" => SEG <= THREE;
                    when "0100" => SEG <= FOUR;
                    when "0101" => SEG <= FIVE;
                    when "0110" => SEG <= SIX;
                    when "0111" => SEG <= SEVEN;
                    when "1000" => SEG <= EIGHT;
                    when "1001" => SEG <= NINE;
                    when others => SEG <= (others => '1'); 
                end case;
            when "011" => 
                case tens is
                    when "0000" => SEG <= ZERO;
                    when "0001" => SEG <= ONE;
                    when "0010" => SEG <= TWO;
                    when "0011" => SEG <= THREE;
                    when "0100" => SEG <= FOUR;
                    when "0101" => SEG <= FIVE;
                    when "0110" => SEG <= SIX;
                    when "0111" => SEG <= SEVEN;
                    when "1000" => SEG <= EIGHT;
                    when "1001" => SEG <= NINE;
                    when others => SEG <= (others => '1');
                end case;
            when others => SEG <= (others => '1'); 
        end case;
    end process;

end arch_seg7;

