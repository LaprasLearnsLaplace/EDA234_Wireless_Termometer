library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity find_max_min is
    Port ( 
        clk          : in std_logic;
        reset        : in std_logic;
        temp_sw      : in std_logic;
        data_in      : in std_logic_vector(7 downto 0);
        max_min_temp : out std_logic_vector(15 downto 0)
    );
end find_max_min;

architecture arch_find_max_min of find_max_min is

    signal max_temp_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal min_temp_reg : std_logic_vector(7 downto 0) := (others => '1'); -- Initialize to maximum possible value
    signal clk_counter : integer range 0 to 49;
    signal clk_1mhz : std_logic;

    component printf
    port (
      clk       : in std_logic;
      probe_in0 : in std_logic_vector(7 downto 0)
    );
    end component;

begin

    -- process(clk, reset)
    -- begin
    --     if rising_edge(clk) then
    --         if reset = '1' then
    --             clk_counter <= 0;
    --             clk_1mhz <= '0';
    --         else 
    --             if clk_counter = 19 then
    --                 clk_counter <= 0;
    --                 clk_1mhz <= not clk_1mhz;
    --             else
    --                 clk_counter <= clk_counter + 1;
    --             end if;
    --         end if;
    --     end if;
    -- end process;


    process(clk, reset)
    begin
        if rising_edge(clk) then
            -- if clk_1mhz = '1' then
            if reset = '1' or temp_sw = '1' then
                max_temp_reg <= (others => '0');
                min_temp_reg <= (others => '1');
            else
                if unsigned(data_in) > unsigned(max_temp_reg) then
                    max_temp_reg <= data_in;
                end if;
                if unsigned(min_temp_reg) > unsigned(data_in) then
                    min_temp_reg <= data_in;
                end if;
            end if;
            -- end if;
        end if;
    end process;

    print1 : printf
    port map
    (
      clk       => clk,
      probe_in0 => min_temp_reg
    );

    print2 : printf
    port map
    (
      clk       => clk,
      probe_in0 => max_temp_reg
    );

    max_min_temp <= max_temp_reg & min_temp_reg;

end arch_find_max_min;