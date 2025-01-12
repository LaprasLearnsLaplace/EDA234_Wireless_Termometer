library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DS1302_Controller is
    Port ( 
        clk1     : in  STD_LOGIC;
        rstn     : in  STD_LOGIC;
--        rd_btn   : in  STD_LOGIC;
        wr_btn   : in  STD_LOGIC;
        hr       : in  STD_LOGIC_VECTOR(7 downto 0);  -- Time to write, in BCD format
        min      : in  STD_LOGIC_VECTOR(7 downto 0);
        sec      : in  STD_LOGIC_VECTOR(7 downto 0);
        time_out : out STD_LOGIC_VECTOR(63 downto 0);
        CE       : out STD_LOGIC;
        SCLK     : out STD_LOGIC;
        IO       : inout STD_LOGIC
    );
end DS1302_Controller;

architecture Behavioral of DS1302_Controller is
    -- Clock address of DS1302 RTC module
    constant BURST_RD_ADDR     : STD_LOGIC_VECTOR(7 downto 0) := x"BF";
    constant BURST_WR_ADDR     : STD_LOGIC_VECTOR(7 downto 0) := x"BE";
    constant WR_CTRL_REG_ADDR  : STD_LOGIC_VECTOR(7 downto 0) := x"8E";
    constant WR_SEC_REG_ADDR   : STD_LOGIC_VECTOR(7 downto 0) := x"80";
    
    -- State type definition
    type state_type is (IDLE, WR_ADDR_PREP, WR_ADDR, CNT_RST, WR_BURST_PREP, WR_BURST, WR_SINGLE_PREP, WR_SINGLE, RD_BURST, STO_BURST, TERMINATE);
    signal state : state_type;
    
    -- Internal signals
    signal prev_rd_btn, prev_wr_btn : STD_LOGIC;
    signal io_dir  : STD_LOGIC;  -- io_dir = '1': output, io_dir = '0': input
    signal io_reg  : STD_LOGIC;
    signal CH_init : STD_LOGIC;  -- Clock Halt initialization flag
    signal WP_init : STD_LOGIC;  -- Write Protection initialization flag
    signal count   : INTEGER range 0 to 63;
    signal addr    : STD_LOGIC_VECTOR(7 downto 0);
    signal burst_data : STD_LOGIC_VECTOR(63 downto 0);

    signal clk_slow : STD_LOGIC := '0'; -- 慢时钟信号
    signal slow_count : INTEGER range 0 to 9_999_999 := 0;

begin
    -- Time data to write to RTC module
    -- day, date, month, year are sent as 0s
    burst_data <= x"00" & x"00" & x"00" & x"00" & x"00" & hr & min & sec;

    -- IO tri-state buffer control
    IO <= io_reg when io_dir = '1' else 'Z';

    process(clk1)
    begin
        if rising_edge(clk1) then
            if slow_count = 199_999 then  -- 假设 clk1 为 50MHz，200ms = 10,000,000 个周期
                slow_count <= 0;
                clk_slow <= not clk_slow; -- 翻转慢时钟信号
            else
                slow_count <= slow_count + 1;
            end if;
        end if;
    end process;


    -- Detect Read button falling edge
    process(clk1)
    begin
        if rising_edge(clk1) then
            if clk_slow = '1' then 
                prev_rd_btn <= '1';
            elsif prev_rd_btn = '1' then
                prev_rd_btn <= '0';
            end if;
        end if;
    end process;

    -- Detect Write button falling edge
    process(clk1)
    begin
        if rising_edge(clk1) then
            if wr_btn = '1' then 
                prev_wr_btn <= '1';
            elsif prev_wr_btn = '1' then
                prev_wr_btn <= '0';
            end if;
        end if;
    end process;

    -- Main control process
    process(clk1)
    begin
        if rising_edge(clk1) then
            if rstn = '0' then --cpu reset
                count <= 0;
                state <= IDLE;
                CE <= '0';
                SCLK <= '0';
                io_dir <= '1';
                io_reg <= '0';
                time_out <= (others => '0');
                WP_init <= '0';
                CH_init <= '0';
            else
                case state is
                    when IDLE =>
                        CE <= '0';
                        SCLK <= '0';
                        count <= 0;
                        io_dir <= '1';
                        
                        if WP_init = '0' then
                            addr <= WR_CTRL_REG_ADDR;
                            state <= WR_ADDR_PREP;
                        elsif CH_init = '0' then
                            addr <= WR_SEC_REG_ADDR;
                            state <= WR_ADDR_PREP;
                        elsif wr_btn = '0' and prev_wr_btn = '1' then
                            addr <= BURST_WR_ADDR;
                            state <= WR_ADDR_PREP;
                        elsif clk_slow = '0' and prev_rd_btn = '1' then
                            addr <= BURST_RD_ADDR;
                            state <= WR_ADDR_PREP;
                        else
                            state <= IDLE;
                        end if;

                    when WR_ADDR_PREP =>
                        CE <= '1';
                        SCLK <= '0';
                        io_dir <= '1';
                        io_reg <= addr(count);
                        state <= WR_ADDR;

                    when WR_ADDR =>
                        SCLK <= '1';
                        count <= count + 1;
                        if count = 7 then
                            state <= CNT_RST;
                        else
                            state <= WR_ADDR_PREP;
                        end if;

                    when CNT_RST =>
                        count <= 0;
                        if addr = WR_CTRL_REG_ADDR then
                            state <= WR_SINGLE_PREP;
                        elsif addr = WR_SEC_REG_ADDR then
                            state <= WR_SINGLE_PREP;
                        elsif addr = BURST_RD_ADDR then
                            state <= RD_BURST;
                            io_dir <= '0';
                        elsif addr = BURST_WR_ADDR then
                            state <= WR_BURST_PREP;
                        else
                            state <= IDLE;
                        end if;

                    when WR_SINGLE_PREP =>
                        SCLK <= '0';
                        io_reg <= '0';
                        state <= WR_SINGLE;

                    when WR_SINGLE =>
                        SCLK <= '1';
                        count <= count + 1;
                        if count = 7 then
                            state <= TERMINATE;
                        else
                            state <= WR_SINGLE_PREP;
                        end if;

                    when WR_BURST_PREP =>
                        SCLK <= '0';
                        io_reg <= burst_data(count);
                        state <= WR_BURST;

                    when WR_BURST =>
                        SCLK <= '1';
                        count <= count + 1;
                        if count = 63 then
                            state <= TERMINATE;
                        else
                            state <= WR_BURST_PREP;
                        end if;

                    when RD_BURST =>
                        SCLK <= '0';
                        state <= STO_BURST;

                    when STO_BURST =>
                        SCLK <= '1';
                        time_out(count) <= IO;
                        count <= count + 1;
                        
                        if count = 63 then
                            state <= TERMINATE;
                        else
                            state <= RD_BURST;
                        end if;

                    when TERMINATE =>
                        CE <= '0';
                        SCLK <= '0';
                        count <= 0;
                        if addr = WR_CTRL_REG_ADDR then
                            WP_init <= '1';
                        end if;
                        if addr = WR_SEC_REG_ADDR then
                            CH_init <= '1';
                        end if;
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

end Behavioral;