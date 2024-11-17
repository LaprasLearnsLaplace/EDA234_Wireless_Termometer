----------------------------------------------------------------------------------
-- Group: EDA234 Group 1
-- Author: Ziheng
-- 
-- Create Date: 2024/11/17 18:32:59
-- Design Name: 
-- Module Name: uart_ctrl - arch_uart_ctrl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity uart_ctrl is
  port (
    clk : in std_logic;
    rst : in std_logic;
    -- UART ports
    UART_TXD_IN  : in std_logic;
    UART_RXD_OUT : out std_logic;
    UART_CTS     : out std_logic;
    UART_RTS     : in std_logic
  );
end uart_ctrl;

architecture arch_uart_ctrl of uart_ctrl is
  signal UART_TXD_IN_reg : std_logic;
  signal UART_RTS_reg    : std_logic := '1';

  --send data
  constant SEND_DATA_WIDTH : integer                                    := 9;
  signal send_data         : std_logic_vector(SEND_DATA_WIDTH downto 0) := (others => '0');
  signal send_bit_done     : std_logic                                  := '0';
  signal assign_data       : std_logic                                  := '1';
  -- 9600 baud rate -> 100MHz / 9600 - 1 = 10416
  constant BAUD_COUNT : unsigned(13 downto 0) := "10100010110000";
  signal baud_counter : unsigned(13 downto 0) := (others => '0');

begin

  Init_input_proc : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        UART_TXD_IN_reg <= '0';
        UART_RTS_reg    <= '0';
      else
        UART_TXD_IN_reg <= UART_TXD_IN;
        UART_RTS_reg    <= UART_RTS;
      end if;
    end if;
  end process Init_input_proc;
  
  -- SEND
  Send_data_proc : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        UART_RXD_OUT  <= '1';
        baud_counter  <= (others => '0');
        UART_CTS      <= '1';
        send_bit_done <= '0';
        assign_data   <= '1';

      else

        if assign_data = '1' then
          send_data   <= "0011000101";
          assign_data <= '0';
        end if;

        -- Counter logic
        if baud_counter = BAUD_COUNT then
          baud_counter  <= (others => '0');
          send_bit_done <= '1';
        else
          baud_counter  <= baud_counter + 1;
          send_bit_done <= '0';
        end if;

        -- Shift DATA
        if send_bit_done = '1' then
          UART_RXD_OUT <= send_data(SEND_DATA_WIDTH);
          send_data    <= send_data(SEND_DATA_WIDTH - 1 downto 0) & send_data(SEND_DATA_WIDTH);
        end if;

        -- CTS logic
        UART_CTS <= '0';
      end if;
    end if;
  end process SEND_DATA_PROC;

end arch_uart_ctrl;
