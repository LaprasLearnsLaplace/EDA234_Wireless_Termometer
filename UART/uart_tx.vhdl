library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    Port ( 
        clk : in STD_LOGIC;
        tx_data_in : in STD_LOGIC_VECTOR(7 downto 0);
        tx_start : in STD_LOGIC;
        tx : out STD_LOGIC;
        tx_busy : out STD_LOGIC;
        tx_done : out STD_LOGIC       
    );
end uart_tx;

architecture Behavioral of uart_tx is
    constant CLOCKS_PER_BIT : integer := 10417;
    
    type tx_states_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal tx_state : tx_states_t := IDLE;
    
    signal clk_count : integer range 0 to CLOCKS_PER_BIT-1 := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal tx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal tx_done_i : STD_LOGIC := '0';

begin
    process(clk)
    begin
        if rising_edge(clk) then
            tx_done_i <= '0'; 

            case tx_state is
                when IDLE =>
                    tx <= '1';
                    tx_busy <= '0';
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if tx_start = '1' then
                        tx_data <= tx_data_in;
                        tx_state <= START_BIT;
                        tx_busy <= '1';
                    end if;
                    
                when START_BIT =>
                    tx <= '0';
                    
                    if clk_count = CLOCKS_PER_BIT-1 then
                        clk_count <= 0;
                        tx_state <= DATA_BITS;
                    else
                        clk_count <= clk_count + 1;
                    end if;
                    
                when DATA_BITS =>
                    tx <= tx_data(bit_index);
                    
                    if clk_count = CLOCKS_PER_BIT-1 then
                        clk_count <= 0;
                        
                        if bit_index = 7 then
                            tx_state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;
                    
                when STOP_BIT =>
                    tx <= '1';
                    
                    if clk_count = CLOCKS_PER_BIT-1 then
                        tx_done_i <= '1';  
                        tx_state <= IDLE;
                        clk_count <= 0;
                    else
                        clk_count <= clk_count + 1;
                    end if;
            end case;
        end if;
    end process;

    tx_done <= tx_done_i;

end Behavioral;