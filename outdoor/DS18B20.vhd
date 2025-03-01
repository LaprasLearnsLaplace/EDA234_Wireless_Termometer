--EDA234 Group1
--Fu Xuqi 20241206

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ds18s20_ctrl is
    port(
        clk       : in  std_logic;          -- 100MHz
        rstn       : in  std_logic;         
        dq        : inout std_logic;        
        temp_data : out  std_logic_vector(15 downto 0)
--        Seg       : out std_logic_vector(7 downto 0);
--        AN        : out std_logic_vector(7 downto 0)
    );
end ds18s20_ctrl;

architecture rtl of ds18s20_ctrl is
    COMPONENT ila_0
    PORT (
        clk    : IN STD_LOGIC;
        probe0 : IN unsigned(3 downto 0); 
        probe1 : IN STD_LOGIC; 
        probe2 : IN unsigned(19 DOWNTO 0); 
        probe3 : IN unsigned(3 DOWNTO 0); 
        probe4 : IN STD_LOGIC;
        probe5 : IN STD_LOGIC
    );
    END COMPONENT;

    type state_type is (INIT, WR_CMD, WAITING, INIT_AGAIN, RD_CMD, RD_TEMP);

    constant WR_44CC_CMD : std_logic_vector(15 downto 0) :="0100010011001100";
    constant WR_BECC_CMD : std_logic_vector(15 downto 0) :="1011111011001100";

    constant WAITING_MAX  : integer := 750000;  -- 750ms
    
    -- 1us计数器
    signal cnt_div_1us : unsigned(5 downto 0) := (others => '0');  
    signal clk_1us     : std_logic := '0';           
    signal cnt_1us     : unsigned(19 downto 0) := (others => '0');
    signal clk_1us_rising : std_logic := '0';

    signal state      : state_type := INIT;
    signal bit_cnt    : unsigned(3 downto 0) := (others => '0');
    signal flag_pulse : std_logic := '0';
    
    signal data_tmp      : std_logic_vector(15 downto 0):= (others => '0');
    signal data_reg      : std_logic_vector(19 downto 0) ;
    signal data_reg_out  : std_logic_vector(15 downto 0) ;
    signal t_result      : std_logic_vector(21 downto 0) ;
    signal t_sign_reg    : std_logic := '0';

    --signal dq_out        : std_logic := '0';
    signal dq_en         : std_logic := '0';
    signal dq_in         : std_logic := '0';
    signal statt         : unsigned(3 downto 0):= (others => '1');

    signal disp_cnt  : integer range 0 to 999 := 0;
    signal disp_sel  : unsigned(2 downto 0)   := "000";
--    signal Seg_int   : std_logic_vector(7 downto 0) := (others => '1');
--    signal AN_int    : std_logic_vector(7 downto 0) := (others => '1');

--    signal hex_digit_3 : std_logic_vector(3 downto 0) := (others => '1');
--    signal hex_digit_2 : std_logic_vector(3 downto 0) := (others => '1');
--    signal hex_digit_1 : std_logic_vector(3 downto 0) := (others => '1');
--    signal hex_digit_4 : std_logic;

--    signal seg_code_1 : std_logic_vector(7 downto 0) := (others => '1');
--    signal seg_code_2 : std_logic_vector(7 downto 0) := (others => '1');
--    signal seg_code_3 : std_logic_vector(7 downto 0) := (others => '1');
--    signal seg_code_4 : std_logic_vector(7 downto 0) := (others => '1');

--    -- 探针信号声明
--    signal probe0_sig : unsigned(3 downto 0);
--    signal probe1_sig : STD_LOGIC;
--    signal probe2_sig : unsigned(19 DOWNTO 0);
--    signal probe3_sig : unsigned(3 DOWNTO 0);
--    signal probe4_sig : STD_LOGIC;
--    signal probe5_sig : STD_LOGIC;




begin
--    -- 信号赋值给探针信号
--    probe0_sig <= statt;
--    probe1_sig <= dq_in;
--    probe2_sig <= cnt_1us;
--    probe3_sig <= bit_cnt;
--    probe4_sig <= flag_pulse;
--    probe5_sig <= dq;

--    -- ILA 组件实例化
--    ila_inst : ila_0
--        PORT MAP (
--            clk    => clk,               -- 系统时钟
--            probe0 => probe0_sig,        -- statt
--            probe1 => probe1_sig,        -- dq_in
--            probe2 => probe2_sig,        -- cnt_1us
--            probe3 => probe3_sig,        -- bit_cnt
--            probe4 => probe4_sig,        -- flag
--            probe5 => probe5_sig         -- dq
--        );

--dq信号的输出使能与输入采样
--dq <= dq_out when (dq_en = '1') else 'Z';
dq_in <= dq;
process(dq_en)
begin
    dq<= 'Z';
    if dq_en = '1' then
        dq <= '0';
        --dq <= dq_out;
    end if;
end process;
    
    -- 2) 产生 1us 信号 (clk_1us)，并在主时钟下检测其上升沿
    
    process(clk, rstn)
    begin
        if rstn = '0' then
            cnt_div_1us    <= (others => '0');
            clk_1us        <= '0';
            clk_1us_rising <= '0';
        elsif rising_edge(clk) then
            -- 默认情况下，清除"上升沿"标志
            clk_1us_rising <= '0';
            -- 分频 1μs
            if cnt_div_1us = 49 then
                cnt_div_1us <= (others => '0');
                clk_1us     <= not clk_1us;
            -- 当 clk_1us 从 '0' 切换到 '1' 时，生成脉冲
                if clk_1us = '0' then
                    clk_1us_rising <= '1';
                end if;
            else
                cnt_div_1us <= cnt_div_1us + 1;
            end if;
        end if;
    end process;

    -- -- 3) cnt_1us 计数器: 基于 clk_1us_rising 做 +1 或清零
    -- process(clk, rstn)
    -- begin
    --     if rstn = '0' then
    --         cnt_1us <= (others => '0');
    --     elsif rising_edge(clk) then
    --         if clk_1us_rising = '1' then
    --             if ((state = WR_CMD or state = RD_CMD or state = RD_TEMP) and cnt_1us = to_unsigned(64,20)) or
    --                ((state = INIT or state = INIT_AGAIN) and cnt_1us = to_unsigned(1199,20)) or (state = WAITING and cnt_1us = to_unsigned(WAITING_MAX,20)) then
    --                 cnt_1us <= (others => '0');
    --             else
    --                 cnt_1us <= cnt_1us + 1;
    --             end if;
    --         end if;
    --     end if;
    -- end process;

    -- --bit_cnt
    -- process(clk, rstn)
    -- begin
    --     if rstn = '0' then
    --         bit_cnt <= (others => '0');
    --     elsif rising_edge(clk) then
    --         if clk_1us_rising = '1' then
    --             if ((state = RD_TEMP or state = WR_CMD or state = RD_CMD) and 
    --                 cnt_1us = to_unsigned(64,20) and bit_cnt = to_unsigned(15,4)) then
    --                 bit_cnt <= (others => '0');
    --             elsif ((state = WR_CMD or state = RD_CMD or state = RD_TEMP) and cnt_1us = to_unsigned(64,20)) then
    --                 bit_cnt <= bit_cnt + 1;
    --             end if;
    --         end if;
    --     end if;
    -- end process;

    --flag_pulse: 检测 "存在脉冲" (当 dq_in 在指定时间内拉低)
    process(clk, rstn)
    begin
        if rstn = '0' then
            flag_pulse <= '0';
        elsif rising_edge(clk) then
            if clk_1us_rising = '1' then
                if ((state=INIT or state=INIT_AGAIN) and (cnt_1us > to_unsigned(769,20)) and (dq_in='0')) then
                    flag_pulse <= '1';
                elsif ((state = WR_CMD or state = RD_CMD) and cnt_1us = to_unsigned(1,20)) then
                    flag_pulse <= '0';
                end if;
            end if;
        end if;
    end process;

    --状态机
    process(clk, rstn)
    begin
        if rstn = '0' then
            state <= INIT;
            cnt_1us <= (others => '0');
            --cnt_750ms  <= (others => '0');
        elsif rising_edge(clk) then
            if clk_1us_rising = '1' then
                case state is
                    when INIT =>
                    statt <= to_unsigned(1,4);
                        if cnt_1us = to_unsigned(1199,20) and flag_pulse='1' then
                            state <= WR_CMD;
                            cnt_1us <= (others => '0');
                        else
                            cnt_1us <= cnt_1us+1;
                            --state <= INIT;
                        end if;

                    when WR_CMD =>
                    statt <= to_unsigned(2,4);
                        if cnt_1us = to_unsigned(64,20) then
                            bit_cnt <= bit_cnt + 1;
                            cnt_1us <= (others => '0');
                            if bit_cnt = to_unsigned(15,4)  then
                                state <= WAITING;
                                bit_cnt <= (others => '0');
                                cnt_1us <= (others => '0');
                            end if;
                        else
                            cnt_1us <= cnt_1us+1;
                            --state <= WR_CMD;
                        end if;

                    when WAITING =>
                    statt <= to_unsigned(3,4);
                        if cnt_1us = to_unsigned(WAITING_MAX,20) then
                            state <= INIT_AGAIN;
                            cnt_1us <= (others => '0');
                        else
                            cnt_1us <= cnt_1us+1;
                        end if;

                    when INIT_AGAIN =>
                    statt <= to_unsigned(4,4);
                    if cnt_1us = to_unsigned(1199,20) and flag_pulse='1' then
                        state <= RD_CMD;
                        cnt_1us <= (others => '0');
                    else
                    cnt_1us <= cnt_1us+1;
                        --state <= INIT;;
                    end if;

                    when RD_CMD =>
                    statt <= to_unsigned(5,4);
                    if cnt_1us = to_unsigned(64,20) then
                        bit_cnt <= bit_cnt + 1;
                        cnt_1us <= (others => '0');
                        if bit_cnt = to_unsigned(15,4)  then
                            state <= RD_TEMP;
                            bit_cnt <= (others => '0');
                            cnt_1us <= (others => '0');
                        end if;
                    else
                    cnt_1us <= cnt_1us+1;
                    end if;

                    when RD_TEMP =>
                    if cnt_1us = to_unsigned(64,20) then
                        bit_cnt <= bit_cnt + 1;
                        cnt_1us <= (others => '0');
                        if bit_cnt = to_unsigned(15,4)  then
                            state <= INIT;
                            bit_cnt <= (others => '0');
                            cnt_1us <= (others => '0');
                        end if;
                    else
                    cnt_1us <= cnt_1us+1;
                    end if;

                    when others =>
                        state <= INIT;
                end case;
            end if;
        end if;
    end process;

    --dq_out, dq_en 控制
    
    process(clk, rstn)
    begin
        if rstn = '0' then
            --dq_out <= '0';
            dq_en  <= '0';
        elsif rising_edge(clk) then
            if clk_1us_rising = '1' then
                case state is
                    when INIT =>
                        --if unsigned(cnt_1us) <= 10 then
                            --dq_en  <= '1';
                            --dq_out <= '1';
                        if cnt_1us < to_unsigned(699,20) then
                            dq_en  <= '1';
                            --dq_out <= '0';
                        --elsif unsigned(cnt_1us) <= 640  and unsigned(cnt_1us) > 610 then
                            --dq_en  <= '1';
                            --dq_out <= '1';
                        else
                            dq_en  <= '0';
                            --dq_out <= '0';
                        end if;

                    when WR_CMD =>
                        if cnt_1us > to_unsigned(62,20) then
                            dq_en  <= '0';
                            --dq_out <= '0';
                        elsif cnt_1us <= to_unsigned(1,20) then
                            dq_en  <= '1';
                            --dq_out <= '0';
                        else
                            if WR_44CC_CMD(to_integer(bit_cnt)) = '0' then
                                dq_en  <= '1';
                                --dq_out <= '0';  
                            else
                                --if unsigned(cnt_1us) <= 10 then
                                    --dq_en  <= '1';
                                    --dq_out <= '0';
                                --else
                                    dq_en  <= '0';
                                    --dq_out <= '0';
                                --end if;
                            end if;   
                        end if;

                    when WAITING =>
                        dq_en  <= '0';
                        --dq_out <= '1';

                    when INIT_AGAIN =>
                        --if unsigned(cnt_1us) <= 10 then
                            --dq_en  <= '1';
                            --dq_out <= '1';
                        if cnt_1us < to_unsigned(699,20) then
                            dq_en  <= '1';
                            --dq_out <= '0';
                        --elsif unsigned(cnt_1us) <= 640  and unsigned(cnt_1us) > 610 then
                            --dq_en  <= '1';
                            --dq_out <= '1';
                        else
                            dq_en  <= '0';
                            --dq_out <= '0';
                    end if;

                    when RD_CMD =>
                        if cnt_1us > to_unsigned(62,20) then
                            dq_en  <= '0';
                            --dq_out <= '0';
                        elsif cnt_1us <= to_unsigned(1,20) then
                            dq_en  <= '1';
                            --dq_out <= '0';
                        else
                            if WR_BECC_CMD(to_integer(bit_cnt)) = '0' then
                                dq_en  <= '1';
                                --dq_out <= '0';  
                            else
                                --if unsigned(cnt_1us) <= 10 then
                                    --dq_en  <= '1';
                                    --dq_out <= '0';
                                --else
                                    dq_en  <= '0';
                                    --dq_out <= '0';
                                --end if;
                            end if;   
                        end if;

                    when RD_TEMP =>
                        if cnt_1us <= to_unsigned(1,20) then
                            dq_en  <= '1';
                            --dq_out <= '0';
                        else
                            dq_en  <= '0';
                            --dq_out <= '0';
                        end if;

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    
    -- 8) data_tmp：在读温度时将数据读入
    
    process(clk, rstn, cnt_1us)
    begin
        if rstn = '0' then
            data_tmp <= (others => '0');
            temp_data <= (others => '0');
            
        elsif rising_edge(clk) then
            if clk_1us_rising = '1' then
                if (state = RD_TEMP and cnt_1us = to_unsigned(13,20)) then
                    data_tmp <= dq_in & data_tmp(15 downto 1);
                    temp_data <= data_tmp;
                end if;
            end if;
        end if;
    end process;

    
--    -- 9) data_reg: 读完 2 字节温度后根据符号位进行扩展并保存
    
--process(clk, rstn)
--    variable data_int : integer;
--    variable temp_data_reg : std_logic_vector(19 downto 0);
--    variable temp_t_result : std_logic_vector(21 downto 0);
--    begin
--        if rstn = '0' then
--            -- 重置信号
--            --data_reg     <= (others => '0');
--            data_reg_out <= (others => '0');
--            t_result     <= (others => '0');
--            hex_digit_3  <= (others => '0');
--            hex_digit_2  <= (others => '0');
--            hex_digit_1  <= (others => '0');
--        elsif rising_edge(clk) then
--            if clk_1us_rising = '1' then
--                if (state = RD_TEMP and bit_cnt = to_unsigned(15, 4)) then
--                    -- 处理正数和负数
--                    if data_tmp(15) = '0' then
--                        -- 正数
--                        temp_data_reg := (8 downto 0 => '0') & data_tmp(10 downto 0);
--                    else
--                        -- 负数：取补码 + 1
--                        temp_data_reg := (8 downto 0 => '0') & std_logic_vector(unsigned(not data_tmp(10 downto 0)) + 1);
--                    end if;
                    
--                    -- 计算 t_result
--                    temp_t_result := std_logic_vector((unsigned(temp_data_reg(10 downto 0))*625)/1000);
--                    -- t_result <= temp_t_result;
                    
--                    -- 计算 data_int 和 hex_digit
--                    data_int := to_integer(unsigned(temp_t_result(11 downto 0)));
--                    hex_digit_3 <= std_logic_vector(to_unsigned(data_int / 100, 4));
--                    hex_digit_2 <= std_logic_vector(to_unsigned((data_int / 10) mod 10, 4));
--                    hex_digit_1 <= std_logic_vector(to_unsigned(data_int mod 10, 4));
--                end if;
--            end if;
--        end if;
--end process;
    

    
--    --符号位
    
--    process(clk, rstn)
--    begin
--        if rstn = '0' then
--            t_sign_reg <= '0';
--        elsif rising_edge(clk) then
--            --if clk_1us_rising = '1' then
--                if (state=RD_TEMP and cnt_1us=to_unsigned(64,20) and bit_cnt=to_unsigned(15,4)) then
--                    if data_tmp(15)='0' then
--                        t_sign_reg <= '0';
--                    else
--                        t_sign_reg <= '1';
--                    end if;
--                    hex_digit_4 <= t_sign_reg;
--                end if;
--            --end if;
--        end if;
--    end process;

--    --数码管
    
--    process(hex_digit_3)
--    begin
--        case hex_digit_3 is
--            when "0000" => seg_code_3 <= "11000000"; -- 0
--            when "0001" => seg_code_3 <= "11111001"; -- 1
--            when "0010" => seg_code_3 <= "10100100"; -- 2
--            when "0011" => seg_code_3 <= "10110000"; -- 3
--            when "0100" => seg_code_3 <= "10011001"; -- 4
--            when "0101" => seg_code_3 <= "10010010"; -- 5
--            when "0110" => seg_code_3 <= "10000010"; -- 6
--            when "0111" => seg_code_3 <= "11111000"; -- 7
--            when "1000" => seg_code_3 <= "10000000"; -- 8
--            when "1001" => seg_code_3 <= "10010000"; -- 9
--            when "1010" => seg_code_3 <= "10001000"; -- A
--            when "1011" => seg_code_3 <= "10000011"; -- b
--            when "1100" => seg_code_3 <= "11000110"; -- C
--            when "1101" => seg_code_3 <= "10100001"; -- d
--            when "1110" => seg_code_3 <= "10000110"; -- E
--            when "1111" => seg_code_3 <= "10001110"; -- F
--            when others => seg_code_3 <= "11111111";
--        end case;
--    end process;

--    process(hex_digit_2)
--    begin
--        case hex_digit_2 is
--            when "0000" => seg_code_2 <= "01000000"; -- 0
--            when "0001" => seg_code_2 <= "01111001"; -- 1
--            when "0010" => seg_code_2 <= "00100100"; -- 2
--            when "0011" => seg_code_2 <= "00110000"; -- 3
--            when "0100" => seg_code_2 <= "00011001"; -- 4
--            when "0101" => seg_code_2 <= "00010010"; -- 5
--            when "0110" => seg_code_2 <= "00000010"; -- 6
--            when "0111" => seg_code_2 <= "01111000"; -- 7
--            when "1000" => seg_code_2 <= "00000000"; -- 8
--            when "1001" => seg_code_2 <= "00010000"; -- 9
--            when "1010" => seg_code_2 <= "00001000"; -- A
--            when "1011" => seg_code_2 <= "00000011"; -- b
--            when "1100" => seg_code_2 <= "01000110"; -- C
--            when "1101" => seg_code_2 <= "00100001"; -- d
--            when "1110" => seg_code_2 <= "00000110"; -- E
--            when "1111" => seg_code_2 <= "00001110"; -- F
--            when others => seg_code_2 <= "01111111";
--        end case;
--    end process;

--    process(hex_digit_1)
--    begin
--        case hex_digit_1 is
--            when "0000" => seg_code_1 <= "11000000"; -- 0
--            when "0001" => seg_code_1 <= "11111001"; -- 1
--            when "0010" => seg_code_1 <= "10100100"; -- 2
--            when "0011" => seg_code_1 <= "10110000"; -- 3
--            when "0100" => seg_code_1 <= "10011001"; -- 4
--            when "0101" => seg_code_1 <= "10010010"; -- 5
--            when "0110" => seg_code_1 <= "10000010"; -- 6
--            when "0111" => seg_code_1 <= "11111000"; -- 7
--            when "1000" => seg_code_1 <= "10000000"; -- 8
--            when "1001" => seg_code_1 <= "10010000"; -- 9
--            when "1010" => seg_code_1 <= "10001000"; -- A
--            when "1011" => seg_code_1 <= "10000011"; -- b
--            when "1100" => seg_code_1 <= "11000110"; -- C
--            when "1101" => seg_code_1 <= "10100001"; -- d
--            when "1110" => seg_code_1 <= "10000110"; -- E
--            when "1111" => seg_code_1 <= "10001110"; -- F
--            when others => seg_code_1 <= "11111111";
--        end case;
--    end process;

--    process(hex_digit_4)
--    begin
--        case hex_digit_4 is
--            when '0' => seg_code_4 <= "11111111"; -- 正数不亮
--            when '1' => seg_code_4 <= "10111111"; -- 显示"-"
--            when others => seg_code_4 <= "11111111";
--        end case;
--    end process;
    
--    --数码管多路扫描
--    process(clk, rstn)
--    begin
--        if rstn='0' then
--            disp_cnt <= 0;
--            disp_sel <= "000";
--        elsif rising_edge(clk) then
--            if disp_cnt < 999 then
--                disp_cnt <= disp_cnt + 1;
--            else
--                disp_cnt <= 0;
--                if disp_sel < "001" then
--                    disp_sel <= disp_sel + 1; 
--                elsif disp_sel < "010" then
--                    disp_sel <= disp_sel + 1;
--                elsif disp_sel < "011" then
--                    disp_sel <= disp_sel + 1;
--                else
--                    disp_sel <= "000";
--                end if;
--            end if;
--        end if;
--    end process;

--    process(disp_sel, seg_code_1, seg_code_2, seg_code_3, seg_code_4)
--    begin
--        Seg_int <= (others => '1');
--        AN_int  <= (others => '1');
--        case disp_sel is
--            when "000" => 
--                AN_int <= "11111110";
--                Seg_int <= seg_code_1;
--            when "001" =>
--                AN_int <= "11111101";
--                Seg_int <= seg_code_2;
--            when "010" =>
--                AN_int <= "11111011";
--                Seg_int <= seg_code_3;
--            when "011" =>
--                AN_int <= "11110111";
--                Seg_int <= seg_code_4;
--            when others =>
--                AN_int <= "11111111";
--                Seg_int <= "11111111";
--        end case;
--    end process;

--    Seg <= Seg_int;
--    AN  <= AN_int;

end rtl;