LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

ENTITY top IS
    PORT ( 
        rst_n    : IN  STD_LOGIC;
        clk      : IN  STD_LOGIC;
        --uart
        rx       : IN  STD_LOGIC;
        tx       : OUT STD_LOGIC;
        --oled
        oled_csn : OUT STD_LOGIC;
        oled_rst : OUT STD_LOGIC;
        oled_dcn : OUT STD_LOGIC;
        oled_clk : OUT STD_LOGIC;
        oled_dat : OUT STD_LOGIC;
        --ds18s20
        dq        : inout std_logic;        
        --ds1302 
        wr_btn    : in    std_logic;
        set_btn   : in    std_logic;
        ext_input : in    std_logic_vector(5 downto 0);
        seg       : out   std_logic_vector(7 downto 0);
        an        : out   std_logic_vector(7 downto 0);
        CE        : out   std_logic;
        SCLK      : out   std_logic;
        IO        : inout std_logic;
        hr_en     : out   std_logic;
        min_en    : out   std_logic
        
--        sw : in std_logic
    );
END top;

ARCHITECTURE Behavioral OF top IS
    
    component ds18s20_ctrl is
    port(
        clk       : in  std_logic;          -- 100MHz
        rstn       : in  std_logic;         
        dq        : inout std_logic; 
        temp_data : out  std_logic_vector(15 downto 0)       
--        Seg       : out std_logic_vector(7 downto 0);
--        AN        : out std_logic_vector(7 downto 0)
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
    
    component Clock_w_DS1302 is
    port (
        clk100     : in    std_logic;
        rstn      : in    std_logic;
--        rd_btn    : in    std_logic;
        wr_btn    : in    std_logic;
        set_btn   : in    std_logic;
        ext_input : in    std_logic_vector(5 downto 0);
        seg       : out   std_logic_vector(7 downto 0);
        an        : out   std_logic_vector(7 downto 0);
        CE        : out   std_logic;
        SCLK      : out   std_logic;
        IO        : inout std_logic;
        hr_en     : out   std_logic;
        min_en    : out   std_logic
--        sec_en    : out   std_logic
    );
end component;

       component OLED12864
        port (
            clk         : in  std_logic;          -- 12MHz系统时钟
            rst_n       : in  std_logic;          -- 系统复位，低有效
            temp_in     : in  std_logic_vector(15 downto 0); -- 温度传感器数据
            --temp_int_out: out std_logic_vector(7 downto 0);  -- 温度整数部分输出
            oled_csn    : out std_logic;          -- OLCD液晶屏使能
            oled_rst    : out std_logic;          -- OLCD液晶屏复位
            oled_dcn    : out std_logic;          -- OLCD数据指令控制
            oled_clk    : out std_logic;          -- OLCD时钟信号
            oled_dat    : out std_logic           -- OLCD数据信号
        );
    end component;

--    -- 添加时钟分频模块的组件声明
    COMPONENT clk_div IS
        PORT (
            clk_in  : IN  STD_LOGIC;
            rst_n   : IN  STD_LOGIC;
            clk_out : OUT STD_LOGIC
        );
    END COMPONENT;
    
    -- 信号定义
    SIGNAL oled_csn_sig  : STD_LOGIC;
    SIGNAL oled_rst_sig  : STD_LOGIC;
    SIGNAL oled_dcn_sig  : STD_LOGIC;
    SIGNAL oled_clk_sig  : STD_LOGIC;
    SIGNAL oled_dat_sig  : STD_LOGIC;
    
--    signal seg1 : std_logic_vector(7 downto 0);
--    signal an1 : std_logic_vector(7 downto 0);
--    signal seg2 : std_logic_vector(7 downto 0);
--    signal an2 : std_logic_vector(7 downto 0);
    
    
    SIGNAL clk_12MHz     : STD_LOGIC;
    
    signal wire_rx_data : STD_LOGIC_VECTOR(7 downto 0);
    signal wire_rx_valid : STD_LOGIC;
    signal wire_tx_done : STD_LOGIC;
    signal wire_tx_busy : STD_LOGIC;
    signal wire_tx_start : STD_LOGIC := '0';
    signal outdoor_temp :  std_logic_vector(15 downto 0); 
    signal temp_int : std_logic_vector(7 downto 0);
    
    constant COUNTER_MAX : integer := 100000000;  
    signal counter : integer range 0 to COUNTER_MAX-1 := 0;
    
BEGIN
    temp: ds18s20_ctrl 
    port map (
        clk  => clk,
        rstn => rst_n,
        temp_data => outdoor_temp,   
        dq  => dq        
--        Seg => seg2,
--        AN  => an2
    );
   
   Clock_w_DS1302_inst : Clock_w_DS1302
   port map (
       clk100     => clk,
       rstn       => rst_n, 
       wr_btn     => wr_btn,
       set_btn    => set_btn,
       ext_input  => ext_input,
       seg        => seg,
       an         => an,
       CE         => CE,
       SCLK       => SCLK,
       IO         => IO,
       hr_en      => hr_en,
       min_en     => min_en
   );
   
    -- 时钟分频模块例化
    u_clk_div : clk_div
    PORT MAP (
        clk_in  => clk,      -- 100MHz
        rst_n   => rst_n,    
        clk_out => clk_12MHz -- 12MHz
    );

    uart_tx_inst : uart_tx
    port map (
        clk => clk,
        tx_data_in => temp_int,
        tx_start => wire_tx_start,
        tx => tx,
        tx_busy => wire_tx_busy,
        tx_done => wire_tx_done
    );
    
    -- OLED模块例化
    u_oled : OLED12864
    PORT MAP (
        clk      => clk_12MHz,    
        rst_n    => rst_n,
        temp_in => outdoor_temp,
        --temp_int_out=> temp_int,
        oled_csn => oled_csn_sig,
        oled_rst => oled_rst_sig,
        oled_dcn => oled_dcn_sig,
        oled_clk => oled_clk_sig,
        oled_dat => oled_dat_sig
    );
    
    
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            counter <= 0;
            wire_tx_start <= '0';
        elsif rising_edge(clk) then
            wire_tx_start <= '0';  
            
            if wire_tx_busy = '0' then  
                if counter = COUNTER_MAX-1 then
                    counter <= 0;
                    wire_tx_start <= '1';  
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;
    
--    process(sw, seg1, seg2, an1, an2)
--    begin
--       if sw = '1' then
--           seg <= seg1;
--           an <= an1;
--       else
--           seg <= seg2;
--           an <= an2;
--       end if;
--    end process;
    
      process(outdoor_temp)
   begin
       if outdoor_temp(15) = '1' then
            temp_int <= std_logic_vector(resize(unsigned(not outdoor_temp(11 downto 5)) + 1, 8));
       else
           temp_int <= "0" & outdoor_temp(11 downto 5);
       end if;
   end process;

    -- 连接OLED信号到输出端口
    oled_csn <= oled_csn_sig;
    oled_rst <= oled_rst_sig;
    oled_dcn <= oled_dcn_sig;
    oled_clk <= oled_clk_sig;
    oled_dat <= oled_dat_sig;
    
END Behavioral;