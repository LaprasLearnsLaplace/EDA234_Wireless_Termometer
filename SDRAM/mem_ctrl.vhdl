library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mem_ctrl is
    Port ( 
        clk_100MHz  : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        -- r and w
        playing     : in  STD_LOGIC;
        recording   : in  STD_LOGIC;
        --ram ctrl chip/output/wr
        RamCEn      : out STD_LOGIC;
        RamOEn      : out STD_LOGIC;
        RamWEn      : out STD_LOGIC;
        -- flags
        delete_clear: out STD_LOGIC;
        write_zero  : out STD_LOGIC;
        get_data    : out STD_LOGIC;
        data_ready  : out STD_LOGIC;
        mix_data    : out STD_LOGIC
    );
end mem_ctrl;

architecture Behavioral of mem_ctrl is

    constant MHz44cnt : integer := 2268;

    -- State machine states
    type state_type is (BANK, BANK_ACK, FLAG, INC_BLOCK, WAIT_STATE, 
                       DELETE, DELETE_ACK, DELETE_INC, ONECYCLE, 
                       ENTERDELETE, LEAVEDELETE);
    signal pstate : state_type := WAIT_STATE;
    signal nstate : state_type := BANK;
    
    -- delay count
    signal counter       : integer := 0;
    signal delay_done     : STD_LOGIC := '0';
    signal counterEnable  : STD_LOGIC := '0';
    -- addr incr
    signal increment      : STD_LOGIC := '0';
    -- 44k pulse
    signal count         : unsigned(12 downto 0) := (others => '0');
    signal pulse         : STD_LOGIC := '0';
    -- delete
    signal max_delete_block : unsigned(22 downto 0) := (others => '0');
    signal delete_address   : unsigned(22 downto 0) := (others => '0');
    -- wen
    signal WEn_d1        : STD_LOGIC := '1';
    
begin
    MHz44 : process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if rst = '1' then
                count <= (others => '0');
                pulse <= '0';
            elsif count < to_unsigned(MHz44cnt, 13) then
                count <= count + 1;
                pulse <= '0';
            else
                pulse <= '1';
                count <= (others => '0');
            end if;
        end if;
    end process;
    

    wr_delay : process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            RamWEn <= WEn_d1;
        end if;
    end process;
    

    fsm : process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if rst = '1' then
                pstate <= WAIT_STATE;
                counterEnable <= '0';
                write_zero <= '0';
                get_data <= '0';
                data_ready <= '0';
            else
                if pulse = '1' then
                    nstate <= LEAVEDELETE;
                end if;
                
                case pstate is
                    when BANK =>
                        nstate <= BANK;
                        if recording = '1' then
                            get_data <= '1';
                            counterEnable <= '1';
                            RamCEn <= '0';
                            RamOEn <= '1';
                            WEn_d1 <= '0';
                            pstate <= BANK_ACK;
                        elsif playing = '1' then
                            get_data <= '0';
                            RamCEn <= '0';
                            RamOEn <= '0';
                            WEn_d1 <= '1';
                            counterEnable <= '1';
                            pstate <= BANK_ACK;
                        else
                            get_data <= '0';
                            RamCEn <= '1';
                            RamOEn <= '1';
                            WEn_d1 <= '1';
                            data_ready <= '1';
                            pstate <= FLAG;
                        end if;
                        
                    when FLAG =>
                        data_ready <= '0';
                        pstate <= nstate;
                        
                    when BANK_ACK =>
                        get_data <= '0';   --off
                        if counter = 55 then   -- en data_ready, disable mem signals
                            data_ready <= '1';
                            RamCEn <= '1';
                            RamOEn <= '1';
                            WEn_d1 <= '1';
                        else
                            data_ready <= '0';
                        end if;
                        
                        if delay_done = '1' then
                            pstate <= nstate;
                            counterEnable <= '0';
                        end if;
                        
                    when INC_BLOCK =>
                        increment <= '1';
                        mix_data <= '1';
                        nstate <= WAIT_STATE;
                        pstate <= WAIT_STATE;
                        
                    when WAIT_STATE =>
                        mix_data <= '0';
                        increment <= '0';
                        if pulse = '1' then
                            pstate <= BANK;
                        else
                            pstate <= WAIT_STATE;
                        end if;
                        
                    when ENTERDELETE =>
                        nstate <= DELETE;
                        write_zero <= '1';
                        pstate <= DELETE;
                        
                    when DELETE =>
                        RamCEn <= '0';
                        RamOEn <= '1';
                        WEn_d1 <= '0';
                        counterEnable <= '1';
                        pstate <= DELETE_ACK;
                        
                    when DELETE_ACK =>
                        if delay_done = '1' then
                            pstate <= DELETE_INC;
                            RamCEn <= '1';
                            RamOEn <= '1';
                            WEn_d1 <= '1';
                            counterEnable <= '0';
                        end if;
                        
                    when DELETE_INC =>
                        if delete_address < max_delete_block then
                            delete_address <= delete_address + 1;
                            pstate <= nstate;
                        else                        -- delete done
                            delete_clear <= '1';
                            delete_address <= (others => '0');
                            write_zero <= '0';
                            max_delete_block <= (others => '0');
                            pstate <= ONECYCLE;
                        end if;
                        
                    when ONECYCLE =>
                        delete_clear <= '0';
                        pstate <= WAIT_STATE;
                        
                    when LEAVEDELETE =>
                        write_zero <= '0';
                        counterEnable <= '1';
                        if delay_done = '1' then
                            counterEnable <= '0';
                            pstate <= BANK;
                        end if;
                end case;
            end if;
        end if;
    end process;
    

    delay_proc : process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if counterEnable = '0' then
                counter <= 0;
                delay_done <= '0';
            elsif counter < 60 then
                counter <= counter + 1;
                delay_done <= '0';
            else
                counter <= 0;
                delay_done <= '1';
            end if;
        end if;
    end process;
    
end Behavioral;