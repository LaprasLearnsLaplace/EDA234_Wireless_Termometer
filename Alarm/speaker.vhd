library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity speaker_alarm is
    Port (
        clk         : in  std_logic;  -- 100MHz clock input
        reset     : in  std_logic;  -- Active-low asynchronous reset
        enable      : in  std_logic;  -- Enable signal
        speaker_out : out std_logic   -- Speaker output signal
    );
end speaker_alarm;

architecture Behavioral of speaker_alarm is
    constant CLOCK_FREQ   : integer := 100_000_000; -- Clock frequency in Hz
    constant ALARM_FREQ   : integer := 1_000;      -- Alarm frequency in Hz
    constant TOGGLE_COUNT : integer := CLOCK_FREQ / (2 * ALARM_FREQ); -- Toggle period
    signal counter        : integer range 0 to TOGGLE_COUNT := 0;
    signal speaker_signal : std_logic := '0';
begin
    process (clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                counter <= 0;
                speaker_signal <= '0';
            else
                if enable = '1' then
                    -- Counter logic works only when enable is high
                    if counter = TOGGLE_COUNT then
                        counter <= 0;
                        speaker_signal <= not speaker_signal; -- Toggle speaker signal
                    else
                        counter <= counter + 1;
                    end if;
                else
                    -- When enable is low, reset counter and disable output
                    counter <= 0;
                    speaker_signal <= '0';
                end if;
            end if;
        end if;
    end process;

    speaker_out <= speaker_signal;

end Behavioral;
