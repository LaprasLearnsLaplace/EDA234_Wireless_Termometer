----------------------------------------------------------------------------------
-- Group: Group 1
-- Engineer: Ziheng Li
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_ctrl is
    Port (
        clk_200KHz : in std_logic;            
        SDA        : inout std_logic;         
        temp_data  : out std_logic_vector(7 downto 0); 
        SCL        : out std_logic ;            -- I2C clock signal (10kHz)
        tMSB_A, tLSB_A : out std_logic_vector(7 downto 0)
        
    );
end i2c_ctrl;

architecture arch_i2c_ctrl of i2c_ctrl is

    signal counter : unsigned(3 downto 0) := (others => '0'); 
    signal clk_reg : std_logic := '1';

    type state_type is (
        POWER_UP,
        START,
        SEND_ADDR6, SEND_ADDR5, SEND_ADDR4, SEND_ADDR3, SEND_ADDR2, SEND_ADDR1, SEND_ADDR0,
        SEND_RW, REC_ACK,
        REC_MSB7, REC_MSB6, REC_MSB5, REC_MSB4, REC_MSB3, REC_MSB2, REC_MSB1, REC_MSB0,
        SEND_ACK,
        REC_LSB7, REC_LSB6, REC_LSB5, REC_LSB4, REC_LSB3, REC_LSB2, REC_LSB1, REC_LSB0,
        NACK
    );
    signal state_reg : state_type := POWER_UP;

    constant sensor_address_plus_read : std_logic_vector(7 downto 0) := "10010111"; -- A6-A0 + read flag      ---"10010111"
    signal count : unsigned(11 downto 0) := (others => '0');                                                                    
    signal tMSB, tLSB : std_logic_vector(7 downto 0) := (others => '0');           
    signal temp_data_reg : std_logic_vector(7 downto 0) := (others => '0');     
    signal SDA_dir : std_logic := '1';                                             

    signal sda_in : std_logic;                    
    signal sda_out : std_logic := '1';                


begin

    -- Generate 10kHz clock signal for SCL
    process(clk_200KHz)
    begin
        if rising_edge(clk_200KHz) then
            if counter = 9 then
                counter <= (others => '0');
                clk_reg <= not clk_reg; 
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    SCL <= clk_reg;

    -- I2C State Machine
    process(clk_200KHz)
    begin
        if rising_edge(clk_200KHz) then
            count <= count + 1;
            case state_reg is
                when POWER_UP =>
                    if count = to_unsigned(1999, count'length) then
                        state_reg <= START;
                    end if;

                when START =>
                    if count = to_unsigned(2004, count'length) then
                        sda_out <= '0'; -- START condition
                    elsif count = to_unsigned(2013, count'length) then
                        state_reg <= SEND_ADDR6;
                    end if;

                when SEND_ADDR6 =>
                    sda_out <= sensor_address_plus_read(7);
                    if count = to_unsigned(2033, count'length) then
                        state_reg <= SEND_ADDR5;
                    end if;

                when SEND_ADDR5 =>
                    sda_out <= sensor_address_plus_read(6);
                    if count = to_unsigned(2053, count'length) then
                        state_reg <= SEND_ADDR4;
                    end if;

                when SEND_ADDR4 =>
                    sda_out <= sensor_address_plus_read(5);
                    if count = to_unsigned(2073, count'length) then
                        state_reg <= SEND_ADDR3;
                    end if;

                when SEND_ADDR3 =>
                    sda_out <= sensor_address_plus_read(4);
                    if count = to_unsigned(2093, count'length) then
                        state_reg <= SEND_ADDR2;
                    end if;

                when SEND_ADDR2 =>
                    sda_out <= sensor_address_plus_read(3);
                    if count = to_unsigned(2113, count'length) then
                        state_reg <= SEND_ADDR1;
                    end if;

                when SEND_ADDR1 =>
                    sda_out <= sensor_address_plus_read(2);
                    if count = to_unsigned(2133, count'length) then
                        state_reg <= SEND_ADDR0;
                    end if;

                when SEND_ADDR0 =>
                    sda_out <= sensor_address_plus_read(1);
                    if count = to_unsigned(2153, count'length) then
                        state_reg <= SEND_RW;
                    end if;

                when SEND_RW =>
                    sda_out <= sensor_address_plus_read(0);
                    if count = to_unsigned(2169, count'length) then
                        state_reg <= REC_ACK;
                    end if;

                when REC_ACK =>
                    if count = to_unsigned(2189, count'length) then
                        state_reg <= REC_MSB7;
                    end if;

                when REC_MSB7 =>
                    tMSB(7) <= sda_in;
                    if count = to_unsigned(2209, count'length) then
                        state_reg <= REC_MSB6;
                    end if;

                when REC_MSB6 =>
                    tMSB(6) <= sda_in;
                    if count = to_unsigned(2229, count'length) then
                        state_reg <= REC_MSB5;
                    end if;

                when REC_MSB5 =>
                    tMSB(5) <= sda_in;
                    if count = to_unsigned(2249, count'length) then
                        state_reg <= REC_MSB4;
                    end if;

                when REC_MSB4 =>
                    tMSB(4) <= sda_in;
                    if count = to_unsigned(2269, count'length) then
                        state_reg <= REC_MSB3;
                    end if;

                when REC_MSB3 =>
                    tMSB(3) <= sda_in;
                    if count = to_unsigned(2289, count'length) then
                        state_reg <= REC_MSB2;
                    end if;

                when REC_MSB2 =>
                    tMSB(2) <= sda_in;
                    if count = to_unsigned(2309, count'length) then
                        state_reg <= REC_MSB1;
                    end if;

                when REC_MSB1 =>
                    tMSB(1) <= sda_in;
                    if count = to_unsigned(2329, count'length) then
                        state_reg <= REC_MSB0;
                    end if;

                when REC_MSB0 =>
                    tMSB(0) <= sda_in;
                    sda_out <= '0';
                    if count = to_unsigned(2349, count'length) then
                        state_reg <= SEND_ACK;
                    end if;

                when SEND_ACK =>
                    if count = to_unsigned(2369, count'length) then
                        state_reg <= REC_LSB7;
                    end if;

                when REC_LSB7 =>
                    tLSB(7) <= sda_in;
                    if count = to_unsigned(2389, count'length) then
                        state_reg <= REC_LSB6;
                    end if;

                when REC_LSB6 =>
                    tLSB(6) <= sda_in;
                    if count = to_unsigned(2409, count'length) then
                        state_reg <= REC_LSB5;
                    end if;

                when REC_LSB5 =>
                    tLSB(5) <= sda_in;
                    if count = to_unsigned(2429, count'length) then
                        state_reg <= REC_LSB4;
                    end if;

                when REC_LSB4 =>
                    tLSB(4) <= sda_in;
                    if count = to_unsigned(2449, count'length) then
                        state_reg <= REC_LSB3;
                    end if;

                when REC_LSB3 =>
                    tLSB(3) <= sda_in;
                    if count = to_unsigned(2469, count'length) then
                        state_reg <= REC_LSB2;
                    end if;

                when REC_LSB2 =>
                    tLSB(2) <= sda_in;
                    if count = to_unsigned(2489, count'length) then
                        state_reg <= REC_LSB1;
                    end if;

                when REC_LSB1 =>
                    tLSB(1) <= sda_in;
                    if count = to_unsigned(2509, count'length) then
                        state_reg <= REC_LSB0;
                    end if;

                when REC_LSB0 =>
                    tLSB(0) <= sda_in;
                    sda_out <= '1';
                    if count = to_unsigned(2529, count'length) then
                        state_reg <= NACK;
                    end if;

                when NACK =>
                    if count = to_unsigned(2559, count'length) then
                        count <= to_unsigned(2000, count'length);
                        temp_data_reg <= tMSB(6 downto 0) & tLSB(7);
                        state_reg <= START;
                    end if;

                when others =>
                    state_reg <= START;
            end case;
        end if;
    end process;


    SDA_dir <= '1' when (state_reg = POWER_UP or state_reg = START or state_reg = SEND_ADDR6 or
                     state_reg = SEND_ADDR5 or state_reg = SEND_ADDR4 or state_reg = SEND_ADDR3 or
                     state_reg = SEND_ADDR2 or state_reg = SEND_ADDR1 or state_reg = SEND_ADDR0 or
                     state_reg = SEND_RW or state_reg = SEND_ACK or state_reg = NACK)
           else '0';

    SDA <= sda_out when SDA_dir = '1' else 'Z';
    sda_in <= SDA;

    tMSB_A <= tMSB;
    tLSB_A <= tLSB;

    temp_data <= temp_data_reg;
    

end arch_i2c_ctrl;
