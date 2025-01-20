library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity clk_div is
  port (
    clk_in  : in std_logic; -- 100MHz input clock
    rst_n   : in std_logic; -- low reset
    clk_out : out std_logic -- 12MHz output clock
  );
end clk_div;

architecture Behavioral of clk_div is
  -- 100/12 ≈ 8.33
  constant COUNT_MAX    : integer := 4;
  constant TOGGLE_VALUE : integer := 2;

  signal count       : integer range 0 to COUNT_MAX - 1;
  signal clk_out_reg : std_logic;

begin
  -- clock divider
  clk_div_proc : process (clk_in, rst_n)
  begin
    if rst_n = '0' then
      count       <= 0;
      clk_out_reg <= '0';
    elsif RISING_EDGE(clk_in) then
      if count = COUNT_MAX - 1 then
        count <= 0;
      else
        count <= count + 1;
      end if;
      if count = TOGGLE_VALUE then
        clk_out_reg <= not clk_out_reg;
      end if;
    end if;
  end process;

  -- output
  clk_out <= clk_out_reg;

end Behavioral;