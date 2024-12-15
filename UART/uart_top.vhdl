library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_top is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        rx  : in STD_LOGIC;
        tx  : out STD_LOGIC;
        rxdata : out STD_LOGIC_VECTOR(7 downto 0)
    );
end uart_top;

architecture Behavioral of uart_top is
    component uart_rx is
        Port ( 
            clk : in STD_LOGIC;
            rx  : in STD_LOGIC;
            rx_data_out : out STD_LOGIC_VECTOR(7 downto 0);
            rx_data_valid : out STD_LOGIC
        );
    end component;
    
    component uart_tx is
        Port ( 
            clk : in STD_LOGIC;
            tx_data_in : in STD_LOGIC_VECTOR(7 downto 0);
            tx_start : in STD_LOGIC;
            tx : out STD_LOGIC;
            tx_busy : out STD_LOGIC;
            tx_done : out STD_LOGIC
        );
    end component;
    
    component uart_fifo is
        generic (
            FIFO_DEPTH : integer := 1024;
            DATA_WIDTH : integer := 8
        );
        Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            wr_en : in STD_LOGIC;
            wr_data : in STD_LOGIC_VECTOR(7 downto 0);
            full : out STD_LOGIC;
            rd_en : in STD_LOGIC;
            rd_data : out STD_LOGIC_VECTOR(7 downto 0);
            empty : out STD_LOGIC
        );
    end component;
    
    type state_type is (IDLE, READ_DATA, WAIT_DATA, START_TX, WAIT_TX);
    signal current_state : state_type := IDLE;
    
    signal wire_rx_data : STD_LOGIC_VECTOR(7 downto 0);
    signal wire_rx_valid : STD_LOGIC;
    signal wire_tx_busy : STD_LOGIC;
    signal wire_tx_done : STD_LOGIC;
    signal wire_fifo_full : STD_LOGIC;
    signal wire_fifo_empty : STD_LOGIC;
    signal wire_fifo_data : STD_LOGIC_VECTOR(7 downto 0);
    signal wire_tx_start : STD_LOGIC;
    signal wire_rd_en : STD_LOGIC;
    signal tx_data_reg : STD_LOGIC_VECTOR(7 downto 0);
    signal data_valid : STD_LOGIC := '0';
    
begin

    uart_rx_inst : uart_rx
    port map (
        clk => clk,
        rx => rx,
        rx_data_out => wire_rx_data,
        rx_data_valid => wire_rx_valid
    );
    
    fifo_inst : uart_fifo
    generic map (
        FIFO_DEPTH => 1024,
        DATA_WIDTH => 8
    )
    port map (
        clk => clk,
        rst => rst,
        wr_en => wire_rx_valid,
        wr_data => wire_rx_data,
        full => wire_fifo_full,
        rd_en => wire_rd_en,
        rd_data => wire_fifo_data,
        empty => wire_fifo_empty
    );

    
    fsm : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= IDLE;
                wire_rd_en <= '0';
                wire_tx_start <= '0';
                data_valid <= '0';
            else
                wire_rd_en <= '0';   
                wire_tx_start <= '0'; 
                
                case current_state is
                    when IDLE =>
                        if wire_fifo_empty = '0' and wire_tx_busy = '0' then
                            current_state <= READ_DATA;
                            wire_rd_en <= '1';  
                        end if;
                        
                    when READ_DATA =>
                        current_state <= WAIT_DATA;
                        data_valid <= '1';      
                        
                    when WAIT_DATA =>
                        if data_valid = '1' then
                            tx_data_reg <= wire_fifo_data;  
                            current_state <= START_TX;
                            data_valid <= '0';  
                        end if;
                        
                    when START_TX =>
                        wire_tx_start <= '1';  
                        current_state <= WAIT_TX;
                        
                    when WAIT_TX =>
                        if wire_tx_busy = '1' then
                            current_state <= IDLE;  
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    uart_tx_inst : uart_tx
    port map (
        clk => clk,
        tx_data_in => tx_data_reg,
        tx_start => wire_tx_start,
        tx => tx,
        tx_busy => wire_tx_busy,
        tx_done => wire_tx_done
    );
    
    rxdata <= wire_rx_data;

end Behavioral;