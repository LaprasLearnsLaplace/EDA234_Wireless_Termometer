library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Time_Setting is
    port (
        clk       : in  std_logic;
        rstn      : in  std_logic;
        set       : in  std_logic;
        ext_input : in  std_logic_vector(5 downto 0);
        hr        : out std_logic_vector(4 downto 0);    
        min       : out std_logic_vector(5 downto 0);    
        sec       : out std_logic_vector(5 downto 0);
        hr_en     : out std_logic;
        min_en    : out std_logic
    );
end entity Time_Setting;

architecture rtl of Time_Setting is
    -- State type declaration
    type States is (SET_HR, SET_MIN, IDLE);
    signal state_reg, next_state : States;
    
    -- Registered values for time
    signal hr_reg  : std_logic_vector(4 downto 0);
    signal min_reg : std_logic_vector(5 downto 0);
    signal sec_reg : std_logic_vector(5 downto 0);
    
    -- Enable signals
    signal hr_en_reg  : std_logic;
    signal min_en_reg : std_logic;
    
    -- Set button edge detection
    signal set_reg, set_prev : std_logic;
    signal set_falling_edge : std_logic;
    
begin
    -- Set button edge detection
    process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                set_reg  <= '0';
                set_prev <= '0';
            else
                set_reg  <= set;
                set_prev <= set_reg;
            end if;
        end if;
    end process;
    
    set_falling_edge <= '1' when set_prev = '1' and set_reg = '0' else '0';
    
    -- State register process
    process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                state_reg <= IDLE;
            else
                state_reg <= next_state;
            end if;
        end if;
    end process;

    -- Next state logic
    process(state_reg, set_falling_edge)
    begin
        case state_reg is
            when IDLE =>
                if set_falling_edge = '1' then
                    next_state <= SET_HR;
                else
                    next_state <= IDLE;
                end if;
                
            when SET_HR =>
                if set_falling_edge = '1' then
                    next_state <= SET_MIN;
                else
                    next_state <= SET_HR;
                end if;
                
            when SET_MIN =>
                if set_falling_edge = '1' then
                    next_state <= IDLE;
                else
                    next_state <= SET_MIN;
                end if;
        end case;
    end process;

    -- Time value setting process
    process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                hr_reg  <= (others => '0');
                min_reg <= (others => '0');
                sec_reg <= (others => '0');
            else
                case state_reg is
                    when SET_HR =>
                        if unsigned(ext_input) > 23 then
                            hr_reg <= std_logic_vector(to_unsigned(23, 5));
                        else
                            hr_reg <= ext_input(4 downto 0);
                        end if;
                        
                    when SET_MIN =>
                        if unsigned(ext_input) > 59 then
                            min_reg <= std_logic_vector(to_unsigned(59, 6));
                        else
                            min_reg <= ext_input;
                        end if;
                        
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    -- Enable signals generation
    process(state_reg)
    begin
        -- Default assignments
        hr_en_reg  <= '0';
        min_en_reg <= '0';
        
        case state_reg is
            when SET_HR =>
                hr_en_reg <= '1';
            when SET_MIN =>
                min_en_reg <= '1';
            when others =>
                null;
        end case;
    end process;

    -- Output assignments
    hr    <= hr_reg;
    min   <= min_reg;
    sec   <= sec_reg;
    hr_en <= hr_en_reg;
    min_en <= min_en_reg;
    
end architecture rtl;