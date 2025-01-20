library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Sev_Seg_Display is
  port (
    clk, rstn    : in std_logic;
    hr, min, sec : in std_logic_vector(7 downto 0); -- in BCD
    an           : out std_logic_vector(7 downto 0);
    seg          : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of Sev_Seg_Display is

  signal disp_sel : std_logic_vector(2 downto 0);
  signal disp_cnt : integer range 0 to 999;
  signal seg_int  : std_logic_vector(7 downto 0);

  --Store the decoding result of each digit
  type hex_array is array (0 to 5) of std_logic_vector(7 downto 0);
  signal hex_out : hex_array;
  constant ZERO  : std_logic_vector(7 downto 0) := "11000000"; -- 0  abcdef-
  constant ONE   : std_logic_vector(7 downto 0) := "11111001"; -- 1  bc-----
  constant TWO   : std_logic_vector(7 downto 0) := "10100100"; -- 2  ab-de-g
  constant THREE : std_logic_vector(7 downto 0) := "10110000"; -- 3  abcd--g
  constant FOUR  : std_logic_vector(7 downto 0) := "10011001"; -- 4  -bc--fg
  constant FIVE  : std_logic_vector(7 downto 0) := "10010010"; -- 5  a-cd-fg
  constant SIX   : std_logic_vector(7 downto 0) := "10000010"; -- 6  a-cdefg
  constant SEVEN : std_logic_vector(7 downto 0) := "11111000"; -- 7  abc----
  constant EIGHT : std_logic_vector(7 downto 0) := "10000000"; -- 8  abcdefg
  constant NINE  : std_logic_vector(7 downto 0) := "10010000"; -- 9  abcd-fg
  constant DASH  : std_logic_vector(7 downto 0) := "10111111"; -- -  ------g

begin
  process (clk, rstn)
  begin
    if rstn = '0' then
      disp_sel <= "000";
      disp_cnt <= 0;
      seg_int  <= "11111111";
      an       <= "11111111";
    elsif rising_edge(clk) then
      -- count
      if disp_cnt < 999 then
        disp_cnt <= disp_cnt + 1;
      else
        disp_cnt <= 0;
        if disp_sel < "111" then
          disp_sel <= std_logic_vector(unsigned(disp_sel) + 1);
        else
          disp_sel <= "000";
        end if;
      end if;

      case disp_sel is
        when "000" => -- hour tens
          an      <= "11011111";
          seg_int <= hex_out(5);
        when "001" => -- hour units
          an      <= "11101111";
          seg_int <= hex_out(4);
        when "010" => -- minute tens
          an      <= "11110111";
          seg_int <= hex_out(3);
        when "011" => -- minute units
          an      <= "11111011";
          seg_int <= hex_out(2);
        when "100" => -- second tens
          an      <= "11111101";
          seg_int <= hex_out(1);
        when "101" => -- second units
          an      <= "11111110";
          seg_int <= hex_out(0);
        when others =>
          an      <= "11111111";
          seg_int <= "11111111";
      end case;
    end if;
  end process;

  -- decode the BCD to 7-segment
  process (hr)
  begin
    case "00" & hr(5 downto 4) is
      when "0000" => hex_out(5) <= ZERO;
      when "0001" => hex_out(5) <= ONE;
      when "0010" => hex_out(5) <= TWO;
      when "0011" => hex_out(5) <= THREE;
      when "0100" => hex_out(5) <= FOUR;
      when "0101" => hex_out(5) <= FIVE;
      when "0110" => hex_out(5) <= SIX;
      when "0111" => hex_out(5) <= SEVEN;
      when "1000" => hex_out(5) <= EIGHT;
      when "1001" => hex_out(5) <= NINE;
      when others => hex_out(5) <= DASH;
    end case;
  end process;

  process (hr)
  begin
    case hr(3 downto 0) is
      when "0000" => hex_out(4) <= ZERO;
      when "0001" => hex_out(4) <= ONE;
      when "0010" => hex_out(4) <= TWO;
      when "0011" => hex_out(4) <= THREE;
      when "0100" => hex_out(4) <= FOUR;
      when "0101" => hex_out(4) <= FIVE;
      when "0110" => hex_out(4) <= SIX;
      when "0111" => hex_out(4) <= SEVEN;
      when "1000" => hex_out(4) <= EIGHT;
      when "1001" => hex_out(4) <= NINE;
      when others => hex_out(4) <= DASH;
    end case;
  end process;

  process (min)
  begin
    case '0' & min(6 downto 4) is
      when "0000" => hex_out(3) <= ZERO;
      when "0001" => hex_out(3) <= ONE;
      when "0010" => hex_out(3) <= TWO;
      when "0011" => hex_out(3) <= THREE;
      when "0100" => hex_out(3) <= FOUR;
      when "0101" => hex_out(3) <= FIVE;
      when "0110" => hex_out(3) <= SIX;
      when "0111" => hex_out(3) <= SEVEN;
      when "1000" => hex_out(3) <= EIGHT;
      when "1001" => hex_out(3) <= NINE;
      when others => hex_out(3) <= DASH;
    end case;
  end process;

  process (min)
  begin
    case min(3 downto 0) is
      when "0000" => hex_out(2) <= ZERO;
      when "0001" => hex_out(2) <= ONE;
      when "0010" => hex_out(2) <= TWO;
      when "0011" => hex_out(2) <= THREE;
      when "0100" => hex_out(2) <= FOUR;
      when "0101" => hex_out(2) <= FIVE;
      when "0110" => hex_out(2) <= SIX;
      when "0111" => hex_out(2) <= SEVEN;
      when "1000" => hex_out(2) <= EIGHT;
      when "1001" => hex_out(2) <= NINE;
      when others => hex_out(2) <= DASH;
    end case;
  end process;

  process (sec)
  begin
    case '0' & sec(6 downto 4) is
      when "0000" => hex_out(1) <= ZERO;
      when "0001" => hex_out(1) <= ONE;
      when "0010" => hex_out(1) <= TWO;
      when "0011" => hex_out(1) <= THREE;
      when "0100" => hex_out(1) <= FOUR;
      when "0101" => hex_out(1) <= FIVE;
      when "0110" => hex_out(1) <= SIX;
      when "0111" => hex_out(1) <= SEVEN;
      when "1000" => hex_out(1) <= EIGHT;
      when "1001" => hex_out(1) <= NINE;
      when others => hex_out(1) <= DASH;
    end case;
  end process;

  process (sec)
  begin
    case sec(3 downto 0) is
      when "0000" => hex_out(0) <= ZERO;
      when "0001" => hex_out(0) <= ONE;
      when "0010" => hex_out(0) <= TWO;
      when "0011" => hex_out(0) <= THREE;
      when "0100" => hex_out(0) <= FOUR;
      when "0101" => hex_out(0) <= FIVE;
      when "0110" => hex_out(0) <= SIX;
      when "0111" => hex_out(0) <= SEVEN;
      when "1000" => hex_out(0) <= EIGHT;
      when "1001" => hex_out(0) <= NINE;
      when others => hex_out(0) <= DASH;
    end case;
  end process;

  -- output
  seg <= seg_int;

end architecture;