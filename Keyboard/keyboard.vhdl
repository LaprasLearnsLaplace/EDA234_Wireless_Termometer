--Group 1
--Xuqi Fu 20241202
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity keyboard is
    Port (
        clk             : in  std_logic;
        reset             : in  std_logic;
        keyboard4x4_col : in  std_logic_vector(3 downto 0);    -- 行输入
        keyboard4x4_row : out std_logic_vector(3 downto 0);    -- 列输出
        key_num         : out std_logic_vector(3 downto 0);    -- 按键编号输出
        flag_key        : out std_logic;                       -- 有效性判断
        Seg             : out std_logic_vector(6 downto 0);    
        AN              : out std_logic_vector(7 downto 0);
        temp_set        : out std_logic_vector(7 downto 0) 
    );
end keyboard;

architecture keyboard_arch of keyboard is
    constant T_10ms : integer := 50000; -- 50ms，1MHz

    -- 状态机状态定义
    type state_type is (STATE_OFF, STATE_ON_SHAKE, STATE_OUT_SCAN,
                        STATE_SCAN_WAIT0, STATE_SCAN_WAIT1, STATE_SCAN_WAIT2, STATE_SCAN_WAIT3,
                        STATE_CHECK_PRESS, STATE_OFF_SHAKE);
    signal c_state : state_type := STATE_OFF;
    signal n_state : state_type;

    -- 行信号同步
    signal row_r  : std_logic_vector(3 downto 0) := "1111";
    signal row_rr : std_logic_vector(3 downto 0) := "1111";

    -- 10ms 计数器
    signal cnt_10ms : integer range 0 to T_10ms := 0;

    -- 行列组合信号
    signal row_col      : std_logic_vector(7 downto 0) := "00000000";
    signal flag_row_col : std_logic := '0';

    -- 内部信号
    signal keyboard4x4_row_int : std_logic_vector(3 downto 0) := "0000";
    signal key_num_int         : std_logic_vector(3 downto 0) := "0000";
    signal flag_key_int        : std_logic := '0';
    signal Seg_int             : std_logic_vector(6 downto 0) := "1111111";

    -- 分频信号
    signal clk_div : unsigned(19 downto 0) := (others => '0');
    signal scan_clk : std_logic;

    -- 数码管多路复用计数器
    signal disp_cnt : integer range 0 to 999 := 0; -- 用于多路复用计数
    signal disp_sel : unsigned(2 downto 0) := "000"; -- 显示选择信号

    -- 按键按压计数器
    signal press_count : integer range 0 to 3 := 0;

    -- key_num_int1 和 key_num_int2 用于存储两个按键编号
    signal key_num_int1 : std_logic_vector(3 downto 0) := "0000";
    signal key_num_int2 : std_logic_vector(3 downto 0) := "0000";
    signal key_num1_valid : std_logic := '0';
    signal key_num2_valid : std_logic := '0';

    -- key_num_int1 和 key_num_int2 映射到 7 段显示
    signal key_seg1 : std_logic_vector(6 downto 0) := "1111111";
    signal key_seg2 : std_logic_vector(6 downto 0) := "1111111";

    -- 延迟信号
    signal flag_row_col_prev : std_logic := '0';

begin
    -- 分频生成 1MHz 的 scan_clk
    -- 假设输入 clk 为 100MHz
    process(clk, reset)
    begin
        if reset = '1' then
            clk_div <= (others => '0');
        elsif rising_edge(clk) then
            if clk_div < 99 then -- 100MHz / 100 = 1MHz
                clk_div <= clk_div + 1;
            else
                clk_div <= (others => '0');
            end if;
        end if;
    end process;

    -- 生成 scan_clk = 1MHz
    scan_clk <= '1' when clk_div < 50 else '0'; -- 1MHz, '1' for first half of the cycle

    -- 行信号同步
    process(scan_clk, reset)
    begin
        if reset = '1' then
            row_r <= "1111";
            row_rr <= "1111";
        elsif rising_edge(scan_clk) then
            row_r <= keyboard4x4_col;
            row_rr <= row_r;
        end if;
    end process;

    -- 状态寄存器
    process(scan_clk, reset)
    begin
        if reset = '1' then
            c_state <= STATE_OFF;
        elsif rising_edge(scan_clk) then
            c_state <= n_state;
        end if;
    end process;

    -- 下一个状态逻辑
    process(c_state, row_rr, cnt_10ms, keyboard4x4_row_int)
    begin
        case c_state is
            when STATE_OFF =>
                if row_rr /= "1111" then
                    n_state <= STATE_ON_SHAKE;
                else
                    n_state <= STATE_OFF;
                end if;

            when STATE_ON_SHAKE =>
                if row_rr = "1111" then
                    n_state <= STATE_OFF;
                elsif cnt_10ms < (T_10ms - 1) then
                    n_state <= STATE_ON_SHAKE;
                else
                    n_state <= STATE_OUT_SCAN;
                end if;

            when STATE_OUT_SCAN =>
                n_state <= STATE_SCAN_WAIT0;

            when STATE_SCAN_WAIT0 =>
                n_state <= STATE_SCAN_WAIT1;

            when STATE_SCAN_WAIT1 =>
                n_state <= STATE_SCAN_WAIT2;

            when STATE_SCAN_WAIT2 =>
                n_state <= STATE_SCAN_WAIT3;

            when STATE_SCAN_WAIT3 =>
                n_state <= STATE_CHECK_PRESS;

            when STATE_CHECK_PRESS =>
                if row_rr = "1111" then
                    if keyboard4x4_row_int = "0111" then
                        n_state <= STATE_OFF;
                    else
                        n_state <= STATE_OUT_SCAN;
                    end if;
                else
                    n_state <= STATE_OFF_SHAKE;
                end if;

            when STATE_OFF_SHAKE =>
                if (row_rr = "1111") and (cnt_10ms = (T_10ms - 1)) then
                    n_state <= STATE_OFF;
                else
                    n_state <= STATE_OFF_SHAKE;
                end if;

            when others =>
                n_state <= STATE_OFF;
        end case;
    end process;

    -- 输出逻辑
    process(scan_clk, reset)
    begin
        if reset = '1' then
            keyboard4x4_row_int <= "0000";
        elsif rising_edge(scan_clk) then
            case c_state is
                when STATE_OFF =>
                    keyboard4x4_row_int <= "0000";

                when STATE_ON_SHAKE =>
                    if (row_rr /= "1111") and (cnt_10ms = (T_10ms - 1)) then
                        keyboard4x4_row_int <= "0111";
                    else
                        keyboard4x4_row_int <= "0000";
                    end if;

                when STATE_OUT_SCAN =>
                    keyboard4x4_row_int <= keyboard4x4_row_int(2 downto 0) & keyboard4x4_row_int(3);

                when STATE_SCAN_WAIT0 | STATE_SCAN_WAIT1 | STATE_SCAN_WAIT2 | STATE_SCAN_WAIT3 |
                     STATE_CHECK_PRESS | STATE_OFF_SHAKE =>
                    keyboard4x4_row_int <= keyboard4x4_row_int;

                when others =>
                    keyboard4x4_row_int <= "0000";
            end case;
            keyboard4x4_row <= keyboard4x4_row_int;
        end if;
    end process;

    -- 10ms 计数器
    process(scan_clk, reset)
    begin
        if reset = '1' then
            cnt_10ms <= 0;
        elsif rising_edge(scan_clk) then
            if ((c_state = STATE_ON_SHAKE and cnt_10ms < (T_10ms - 1) and row_rr /= "1111") or
                (c_state = STATE_OFF_SHAKE and cnt_10ms < (T_10ms - 1) and row_rr = "1111")) then
                cnt_10ms <= cnt_10ms + 1;
            else
                cnt_10ms <= 0;
            end if;
        end if;
    end process;

    -- 延迟 flag_row_col 信号，确保 key_num_int 已经更新
    process(scan_clk, reset)
    begin
        if reset = '1' then
            flag_row_col_prev <= '0';
        elsif rising_edge(scan_clk) then
            flag_row_col_prev <= flag_row_col;
        end if;
    end process;

    -- 行列组合信号捕获
    process(scan_clk, reset)
    begin
        if reset = '1' then
            row_col <= "00000000";
        elsif rising_edge(scan_clk) then
            if (c_state = STATE_CHECK_PRESS) and (row_rr /= "1111") then
                -- 正确组合顺序：行 & 列
                row_col <= row_rr & keyboard4x4_row_int;
            else
                row_col <= row_col;
            end if;
        end if;
    end process;

    -- 有效性判断
    process(scan_clk, reset)
    begin
        if reset = '1' then
            flag_row_col <= '0';
        elsif rising_edge(scan_clk) then
            if (c_state = STATE_CHECK_PRESS) and (row_rr /= "1111") then
                flag_row_col <= '1';
            else
                flag_row_col <= '0';
            end if;
        end if;
    end process;

    -- 按键编号映射
    process(scan_clk, reset)
    begin
        if reset = '1' then
            key_num_int <= "0000";
        elsif rising_edge(scan_clk) then
            case row_col is
                when "11101110" => key_num_int <= "0001"; -- 1
                when "11101101" => key_num_int <= "0010"; -- 2
                when "11101011" => key_num_int <= "0011"; -- 3
                when "11100111" => key_num_int <= "1010"; -- A
                when "11011110" => key_num_int <= "0100"; -- 4
                when "11011101" => key_num_int <= "0101"; -- 5
                when "11011011" => key_num_int <= "0110"; -- 6
                when "11010111" => key_num_int <= "1011"; -- B
                when "10111110" => key_num_int <= "0111"; -- 7
                when "10111101" => key_num_int <= "1000"; -- 8
                when "10111011" => key_num_int <= "1001"; -- 9
                when "10110111" => key_num_int <= "1100"; -- C
                when "01111110" => key_num_int <= "1101"; -- E
                when "01111101" => key_num_int <= "0000"; -- 0
                when "01111011" => key_num_int <= "1110"; -- F
                when "01110111" => key_num_int <= "1111"; -- D
                when others     => key_num_int <= "0000";
            end case;
            key_num <= key_num_int;
        end if;
    end process;

    -- 有效后输出
    process(scan_clk, reset)
    begin
        if reset = '1' then
            flag_key_int <= '0';
        elsif rising_edge(scan_clk) then
            flag_key_int <= flag_row_col;
        end if;
        flag_key <= flag_key_int;
    end process;



    -- key_num_int1 和 key_num_int2 的按键输入缓存
    process(scan_clk, reset)
    begin
        if reset = '1' then
            key_num_int1 <= "0000";
            key_num_int2 <= "0000";
            key_num1_valid <= '0';
            key_num2_valid <= '0';
            press_count <= 0;
            --key_num_int <= "0000";
        elsif rising_edge(scan_clk) then
            if flag_row_col_prev ='1' then 
                case press_count is
                    when 0 =>
                        key_num2_valid <= '1';
                        key_num_int2 <= key_num_int;
                        press_count <= 1;
                    when 1 =>
                        key_num1_valid <= '1';
                        key_num_int1 <= key_num_int;
                        press_count <= 2;
                    when 2 =>
                        temp_set <= std_logic_vector(to_unsigned(
                            (to_integer(unsigned(key_num_int2)) * 10) + 
                            to_integer(unsigned(key_num_int1)),
                            temp_set'length)) ;
                        press_count <= 3;
                    when 3 =>
                        key_num_int1 <= "0000";
                        key_num_int2 <= "0000";
                        key_num1_valid <= '0';
                        key_num2_valid <= '0';
                        press_count <= 0;
                    when others =>
                        key_num_int1 <= "0000";
                        key_num_int2 <= "0000";
                        key_num1_valid <= '0';
                        key_num2_valid <= '0';
                        press_count <= 0;
                end case;
            end if;
        end if;
    end process;


    -- key_num_int1 映射到 7 段显示
    process(key_num_int1)
    begin
        case key_num_int1 is
            when "0000" => key_seg1 <= "0000001"; -- 0
            when "0001" => key_seg1 <= "1001111"; -- 1
            when "0010" => key_seg1 <= "0010010"; -- 2
            when "0011" => key_seg1 <= "0000110"; -- 3
            when "0100" => key_seg1 <= "1001100"; -- 4
            when "0101" => key_seg1 <= "0100100"; -- 5
            when "0110" => key_seg1 <= "0100000"; -- 6
            when "0111" => key_seg1 <= "0001111"; -- 7
            when "1000" => key_seg1 <= "0000000"; -- 8
            when "1001" => key_seg1 <= "0000100"; -- 9
            when "1010" => key_seg1 <= "0001000"; -- A
            when "1011" => key_seg1 <= "1100000"; -- B
            when "1100" => key_seg1 <= "0110001"; -- C
            when "1101" => key_seg1 <= "1000010"; -- E
            when "1110" => key_seg1 <= "0110000"; -- F
            when "1111" => key_seg1 <= "0111000"; -- D
            when others => key_seg1 <= "1111111"; -- All segments off
        end case;
    end process;

    -- key_num_int2 映射到 7 段显示
    process(key_num_int2)
    begin
        case key_num_int2 is
            when "0000" => key_seg2 <= "0000001"; -- 0
            when "0001" => key_seg2 <= "1001111"; -- 1
            when "0010" => key_seg2 <= "0010010"; -- 2
            when "0011" => key_seg2 <= "0000110"; -- 3
            when "0100" => key_seg2 <= "1001100"; -- 4
            when "0101" => key_seg2 <= "0100100"; -- 5
            when "0110" => key_seg2 <= "0100000"; -- 6
            when "0111" => key_seg2 <= "0001111"; -- 7
            when "1000" => key_seg2 <= "0000000"; -- 8
            when "1001" => key_seg2 <= "0000100"; -- 9
            when "1010" => key_seg2 <= "0001000"; -- A
            when "1011" => key_seg2 <= "1100000"; -- B
            when "1100" => key_seg2 <= "0110001"; -- C
            when "1101" => key_seg2 <= "1000010"; -- E
            when "1110" => key_seg2 <= "0110000"; -- F
            when "1111" => key_seg2 <= "0111000"; -- D
            when others => key_seg2 <= "1111111"; -- All segments off
        end case;
    end process;

    -- 数码管多路复用与显示
    process(scan_clk, reset)
    begin
        if reset = '1' then
            disp_sel <= "000";
            disp_cnt <= 0;
            Seg_int <= "1110111"; -- 初始显示 "__"
            AN <= "11111101";      -- 激活第2位
        elsif rising_edge(scan_clk) then
            -- 多路复用计数器，控制刷新频率
            if disp_cnt < 999 then
                disp_cnt <= disp_cnt + 1;
            else
                disp_cnt <= 0;
                if disp_sel < "111" then
                    disp_sel <= disp_sel + 1;
                else
                    disp_sel <= "000";
                end if;
            end if;

            -- 根据 disp_sel 信号选择激活的数码管位并显示相应内容
            case disp_sel is
                when "000" => 
                    -- 第1位数码管
                    if key_num1_valid = '1' then
                        AN <= "10111111"; -- 第1位激活
                        Seg_int <= key_seg1; -- 显示 key_num_int2
                    else
                        AN <= "10111111"; -- 第1位激活
                        Seg_int <= "1110111"; -- 显示 "__"
                    end if;
                when "001" =>
                    -- 第2位数码管
                    if key_num2_valid = '1' then
                        AN <= "01111111"; -- 第2位激活
                        Seg_int <= key_seg2; -- 显示 key_num_int1
                    else
                        AN <= "01111111"; -- 第2位激活
                        Seg_int <= "1110111"; -- 显示 "__"
                    end if;
                when others =>
                    -- 关闭其他数码管位
                    AN <= "11111111"; -- 关闭所有位
                    Seg_int <= "1111111"; -- 所有段关闭
            end case;
        end if;
    end process;

    -- 输出赋值
    Seg <= Seg_int;
    -- AN 信号已经在上述进程中被驱动，不再需要其他赋值
    -- AN <= AN_int;

end keyboard_arch;
