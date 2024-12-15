library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_fifo is
    generic (
        FIFO_DEPTH : integer := 1024;  
        DATA_WIDTH : integer := 8    
    );
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        
        wr_en : in STD_LOGIC;
        wr_data : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        full : out STD_LOGIC;
        
        rd_en : in STD_LOGIC;
        rd_data : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        empty : out STD_LOGIC
    );
end uart_fifo;

architecture Behavioral of uart_fifo is
    type ram_type is array (0 to FIFO_DEPTH-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal ram : ram_type := (others => (others => '0'));
    
    signal wr_ptr : unsigned(9 downto 0) := (others => '0');  -- 10bit addr wire for 1024
    signal rd_ptr : unsigned(9 downto 0) := (others => '0');
    signal count : unsigned(10 downto 0) := (others => '0');   -- for full/emp
    
begin

    write_proc : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                wr_ptr <= (others => '0');
            elsif wr_en = '1' and count < FIFO_DEPTH then
                ram(to_integer(wr_ptr)) <= wr_data;
                wr_ptr <= wr_ptr + 1;
            end if;
        end if;
    end process;


    read_proc : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rd_ptr <= (others => '0');
            elsif rd_en = '1' and count > 0 then
                rd_data <= ram(to_integer(rd_ptr));
                rd_ptr <= rd_ptr + 1;
            end if;
        end if;
    end process;


    count_proc : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= (others => '0');
            else
                if wr_en = '1' and rd_en = '0' and count < FIFO_DEPTH then
                    count <= count + 1;
                elsif wr_en = '0' and rd_en = '1' and count > 0 then
                    count <= count - 1;
                end if;
            end if;
        end if;
    end process;

    full <= '1' when count = FIFO_DEPTH else '0';
    empty <= '1' when count = 0 else '0';

end Behavioral;