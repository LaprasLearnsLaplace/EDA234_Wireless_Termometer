library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LCD_Controller is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        lcd_db     : out std_logic_vector(7 downto 0);
        lcd_rs     : out std_logic;
        lcd_rw     : out std_logic;
        lcd_e      : out std_logic
    );
end LCD_Controller;

architecture Behavioral of LCD_Controller is

    -- State type for the state machine
    type state_type is (INIT, CMD, DATA, WAIT_STATE, DONE);
    signal current_state : state_type := INIT;

    -- Internal signals
    signal lcd_db_internal : std_logic_vector(7 downto 0) := (others => '0'); -- Internal data bus
    signal e_pulse : std_logic := '0'; -- Enable pulse
    signal counter : integer := 0; -- Delay counter

    -- Command constants
    constant FUNCTION_SET_CMD : std_logic_vector(7 downto 0) := "00110000"; -- 8-bit mode, 1-line display, 5x7 dots
    constant DISPLAY_ON_CMD   : std_logic_vector(7 downto 0) := "00001100"; -- Display ON
    constant CLEAR_CMD        : std_logic_vector(7 downto 0) := "00000001"; -- Clear display

begin

    -- Assign internal signal to output
    lcd_db <= lcd_db_internal;

    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all states and signals
            current_state <= INIT;
            e_pulse <= '0';
            lcd_rs <= '0';
            lcd_rw <= '0';
            lcd_db_internal <= (others => '0');
            counter <= 0;
        elsif rising_edge(clk) then
            case current_state is
                when INIT =>
                    if counter < 200000 then
                        counter <= counter + 1;
                    else
                        lcd_rs <= '0';
                        lcd_rw <= '0';
                        lcd_db_internal <= FUNCTION_SET_CMD;
                        e_pulse <= '1';
                        counter <= 0;
                        current_state <= CMD;
                    end if;

                when CMD =>
                    if counter < 20000 then
                        counter <= counter + 1;
                        e_pulse <= '0';
                    else
                        if lcd_db_internal = FUNCTION_SET_CMD then
                            lcd_db_internal <= CLEAR_CMD;
                        elsif lcd_db_internal = CLEAR_CMD then
                            lcd_db_internal <= DISPLAY_ON_CMD;
                        else
                            current_state <= DATA;
                        end if;
                        e_pulse <= '1';
                        counter <= 0;
                    end if;

                when DATA =>
                    if counter < 20000 then
                        counter <= counter + 1;
                        e_pulse <= '0';
                    else
                        lcd_rs <= '1';
                        lcd_db_internal <= "01011000"; -- ASCII for "X"
                        e_pulse <= '1';
                        counter <= 0;
                        current_state <= DONE;
                    end if;

                when DONE =>
                    e_pulse <= '0'; -- Stop pulse

                when others =>
                    current_state <= INIT;
            end case;
        end if;
    end process;

    -- Output enable signal
    lcd_e <= e_pulse;

end Behavioral;

-- ASCII Table (Hexadecimal Format):
-- --------------------------------
-- Uppercase Letters:
-- 'A' -> 0x41, 'B' -> 0x42, 'C' -> 0x43, 'D' -> 0x44, 'E' -> 0x45, 'F' -> 0x46
-- 'G' -> 0x47, 'H' -> 0x48, 'I' -> 0x49, 'J' -> 0x4A, 'K' -> 0x4B, 'L' -> 0x4C
-- 'M' -> 0x4D, 'N' -> 0x4E, 'O' -> 0x4F, 'P' -> 0x50, 'Q' -> 0x51, 'R' -> 0x52
-- 'S' -> 0x53, 'T' -> 0x54, 'U' -> 0x55, 'V' -> 0x56, 'W' -> 0x57, 'X' -> 0x58
-- 'Y' -> 0x59, 'Z' -> 0x5A

-- Lowercase Letters:
-- 'a' -> 0x61, 'b' -> 0x62, 'c' -> 0x63, 'd' -> 0x64, 'e' -> 0x65, 'f' -> 0x66
-- 'g' -> 0x67, 'h' -> 0x68, 'i' -> 0x69, 'j' -> 0x6A, 'k' -> 0x6B, 'l' -> 0x6C
-- 'm' -> 0x6D, 'n' -> 0x6E, 'o' -> 0x6F, 'p' -> 0x70, 'q' -> 0x71, 'r' -> 0x72
-- 's' -> 0x73, 't' -> 0x74, 'u' -> 0x75, 'v' -> 0x76, 'w' -> 0x77, 'x' -> 0x78
-- 'y' -> 0x79, 'z' -> 0x7A

-- Numbers:
-- '0' -> 0x30, '1' -> 0x31, '2' -> 0x32, '3' -> 0x33, '4' -> 0x34
-- '5' -> 0x35, '6' -> 0x36, '7' -> 0x37, '8' -> 0x38, '9' -> 0x39

-- Special Characters:
-- Space (' ')    -> 0x20
-- Exclamation ('!') -> 0x21
-- Double Quote ('"') -> 0x22
-- Apostrophe (')') -> 0x27
-- Comma (',')    -> 0x2C
-- Dash ('-')     -> 0x2D
-- Period ('.')   -> 0x2E
-- Slash ('/')    -> 0x2F
-- Colon (':')    -> 0x3A
-- Semicolon (';')-> 0x3B
-- Less Than ('<')-> 0x3C
-- Equal ('=')    -> 0x3D
-- Greater Than ('>')-> 0x3E
-- Question ('?') -> 0x3F

