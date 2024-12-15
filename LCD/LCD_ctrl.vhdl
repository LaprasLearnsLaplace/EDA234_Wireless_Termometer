library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity lcd_controller is
  generic (LCD_DATA_WIDTH : positive := 48);
  port (
    clk                   : in std_logic;
    reset                 : in std_logic;
    lcd_di                : in std_logic_vector(7 downto 0);
    lcd_rw, lcd_rs, lcd_e : out std_logic;
    lcd_db                : out std_logic_vector(7 downto 0) --data 
  );
end lcd_controller;

architecture arch_lcd_controller of lcd_controller is

  type STATE_TYPE is(POWER_UP, INIT, BYTE_RESET, BYTE_SHIFT, SEND);
  signal state     : STATE_TYPE;
  signal counter   : integer := 0;
  signal byte_idx  : natural := 0;
  signal ascii_out : std_logic_vector (LCD_DATA_WIDTH - 1 downto 0);

  constant one_us       : integer                      := 100; --100MHz  -10ns
  constant one_ms       : integer                      := 100000;
  constant FUNCTION_SET : std_logic_vector(7 downto 0) := "00111000";
  constant DISPLAY_ON   : std_logic_vector(7 downto 0) := "00001100";
  constant CLEAR        : std_logic_vector(7 downto 0) := "00000001";
  constant MODE_SET     : std_logic_vector(7 downto 0) := "00000110";
  --constant test_di         : std_logic_vector(7 downto 0) := "01000001"; --"A"
  constant MAX   : std_logic_vector(31 downto 0) := "01001101010000010101100000111010";
  constant MIN   : std_logic_vector(31 downto 0) := "01001101010010010100111000111010";
  constant EMPTY : std_logic_vector(7 downto 0)  := (others => '0');
begin
    
  binary2ascii: process (lcd_di)
    variable data_int : integer;
    variable tens, ones : unsigned(3 downto 0);
    variable ascii1 : std_logic_vector(7 downto 0);
    variable ascii2 : std_logic_vector(7 downto 0);
  begin
    data_int := to_integer(unsigned(lcd_di));
    tens := to_unsigned(data_int / 10, 4);
    ones := to_unsigned(data_int mod 10, 4);
    ascii1 := std_logic_vector(to_unsigned(48 + to_integer(tens), 8));
    ascii2 := std_logic_vector(to_unsigned(48 + to_integer(ones), 8));

    ascii_out <= MAX & ascii1 & ascii2;
  end process binary2ascii;


  
  process (clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        state <= POWER_UP;
      else
        case state is
          when POWER_UP =>
            if (counter < (20 * one_ms)) then --Wait more than 15ms after Vcc = 4.5V, 20 > 15
              counter <= counter + 1;
              state   <= POWER_UP;
            else
              counter <= 0;
              lcd_rs  <= '0';
              lcd_rw  <= '0';
              lcd_db  <= "00000000";
              state   <= INIT;
            end if;
          when INIT =>
            counter <= counter + 1;
            lcd_e   <= '1';
            lcd_db  <= FUNCTION_SET; -- Sets 8 bit interface data length, selects 5 x 7 dots, 1-BYTE_SHIFT display
              state   <= INIT;
            if (counter < (50 * one_us)) then --Execution time is 40 us, 50 > 40
              lcd_e <= '0';
            elsif (counter < ((50 + 10) * one_us)) then
              lcd_db <= DISPLAY_ON;
              lcd_e  <= '1';
              state  <= INIT;
            elsif (counter < ((50 + 10 + 50) * one_us)) then
              lcd_e <= '0';

            elsif (counter < ((50 + 10 + 50 + 10) * one_us)) then
              lcd_db <= CLEAR;
              lcd_e  <= '1';
              state  <= INIT;
            elsif (counter < ((50 + 10 + 50 + 10) * one_us + 20 * one_ms)) then -- Execution time is 15.2ms, 20 > 15.2
              lcd_e <= '0';

            elsif (counter < ((50 + 10 + 50 + 10 + 10) * one_us + 20 * one_ms)) then
              lcd_db <= MODE_SET; --Sets mode to increment the address by one and to shift cursor to the right at the time of write to internal RAM.
              lcd_e  <= '1';
              state  <= INIT;
            elsif (counter < ((50 + 10 + 50 + 10 + 10 + 50) * one_us + 20 * one_ms)) then
              lcd_e <= '0';
            else
              counter <= 0;
              state   <= BYTE_RESET;
            end if;
          when BYTE_RESET =>
            byte_idx <= LCD_DATA_WIDTH/8;
            lcd_db   <= "10000000";
            lcd_rs   <= '0';
            lcd_rw   <= '0';
            counter  <= 0;
            state    <= SEND;
          when BYTE_SHIFT =>
            lcd_db  <= ascii_out(byte_idx * 8 + 7 downto byte_idx * 8);
            lcd_rs  <= '1';
            lcd_rw  <= '0';
            counter <= 0;
            state   <= SEND;
          when SEND =>
            if (counter < (50 * one_us)) then -- tDDR have no minimal requirement but tcycle >= 1000ns but 50 us considered data set time above
              state <= SEND;
              lcd_e <= '0';
              if (counter < one_us) then -- Enable pulse width “High” level PWEH 450ns  < 1 us
                lcd_e <= '1';
              end if;
              counter <= counter + 1;
            else
              lcd_e   <= '0';
              counter <= 0;
              if byte_idx = 0 then
                state <= BYTE_RESET;
              else
                byte_idx <= byte_idx - 1;
                state    <= BYTE_SHIFT;
              end if;
            end if;
        end case;

      end if;
    end if;
  end process;
end arch_lcd_controller;