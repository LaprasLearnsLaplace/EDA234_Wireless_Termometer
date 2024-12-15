library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    Port ( 
        clk : in STD_LOGIC;         
        rx  : in STD_LOGIC;        

        rx_data_out : out STD_LOGIC_VECTOR(7 downto 0); 
        rx_data_valid : out STD_LOGIC  
    );
end uart_rx;

architecture Behavioral of uart_rx is
    -- 100MHz / 9600 = 10417 clocks per bit
    constant CLOCKS_PER_BIT : integer := 10417;
    
    type rx_states_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal rx_state : rx_states_t := IDLE;
    
    signal rx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal clk_count : integer range 0 to CLOCKS_PER_BIT-1 := 0;
    signal bit_index : integer range 0 to 7 := 0;
    
    -- for metastability
    signal rx_sync_1 : STD_LOGIC := '1';
    signal rx_sync_2 : STD_LOGIC := '1';

begin

    sync : process(clk)
    begin
        if rising_edge(clk) then
            rx_sync_1 <= rx;
            rx_sync_2 <= rx_sync_1;
        end if;
    end process;

    fsm : process(clk)
    begin
        if rising_edge(clk) then
            rx_data_valid <= '0';  -- Default state
            
            case rx_state is
                when IDLE =>
                    if rx_sync_2 = '0' then  -- Start bit detected
                        clk_count <= 0;
                        rx_state <= START_BIT;
                    end if;
                    
                when START_BIT =>
                    if clk_count = CLOCKS_PER_BIT/2 then
                        if rx_sync_2 = '0' then  -- Verify still in start bit
                            clk_count <= 0;
                            bit_index <= 0;
                            rx_state <= DATA_BITS;
                        else
                            rx_state <= IDLE;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;
                    
                when DATA_BITS =>
                    if clk_count = CLOCKS_PER_BIT-1 then
                        clk_count <= 0;
                        rx_data(bit_index) <= rx_sync_2;
                        
                        if bit_index = 7 then
                            rx_state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;
                    
                when STOP_BIT =>
                    if clk_count = CLOCKS_PER_BIT-1 then
                        if rx_sync_2 = '1' then  -- Verify stop bit
                            rx_data_out <= rx_data;
                            rx_data_valid <= '1';
                        end if;
                        rx_state <= IDLE;
                        clk_count <= 0;
                    else
                        clk_count <= clk_count + 1;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;