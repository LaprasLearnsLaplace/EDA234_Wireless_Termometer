LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY clk_div IS
    PORT (
        clk_in  : IN  STD_LOGIC;  -- 100MHz输入时钟
        rst_n   : IN  STD_LOGIC;  -- 异步复位，低有效
        clk_out : OUT STD_LOGIC   -- 12MHz输出时钟
    );
END clk_div;

ARCHITECTURE Behavioral OF clk_div IS
    -- 100MHz到12MHz的分频比为100/12 ≈ 8.33
    -- 需要计数到4，即计数范围0-3，在计数值到达2时翻转时钟
    CONSTANT COUNT_MAX : INTEGER := 4;
    CONSTANT TOGGLE_VALUE : INTEGER := 2;
    
    SIGNAL count : INTEGER RANGE 0 TO COUNT_MAX-1;
    SIGNAL clk_out_reg : STD_LOGIC;
    
BEGIN
    -- 分频进程
    clk_div_proc : PROCESS(clk_in, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            count <= 0;
            clk_out_reg <= '0';
        ELSIF RISING_EDGE(clk_in) THEN
            IF count = COUNT_MAX-1 THEN
                count <= 0;
            ELSE
                count <= count + 1;
            END IF;
            
            -- 在计数器达到切换值时翻转时钟
            IF count = TOGGLE_VALUE THEN
                clk_out_reg <= NOT clk_out_reg;
            END IF;
        END IF;
    END PROCESS;
    
    -- 输出时钟赋值
    clk_out <= clk_out_reg;
    
END Behavioral;