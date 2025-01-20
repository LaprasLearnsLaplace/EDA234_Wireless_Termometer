-- 数码管输出时间，可以设置小时和分钟
-- seg displays time, can set hours and minutes
-- 左边按钮选择设置小时/分钟，右边按钮生效，亮灯提示正在编辑小时/分钟 按键设置输入（二进制输入 switch0-5）
-- left button selects setting hours/minutes, right button takes effect, light indicates editing hours/minutes, key setting input (binary input switch0-5)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Clock_w_DS1302 is
  port (
    clk100    : in std_logic;
    rstn      : in std_logic;
    wr_btn    : in std_logic;
    set_btn   : in std_logic;
    ext_input : in std_logic_vector(5 downto 0);
    seg       : out std_logic_vector(7 downto 0);
    an        : out std_logic_vector(7 downto 0);
    CE        : out std_logic;
    SCLK      : out std_logic;
    IO        : inout std_logic;
    hr_en     : out std_logic;
    min_en    : out std_logic
    --        sec_en    : out   std_logic
  );
end entity Clock_w_DS1302;

architecture rtl of Clock_w_DS1302 is
  -- Component declarations
  component Time_Setting is
    port (
      clk       : in std_logic;
      rstn      : in std_logic;
      set       : in std_logic;
      ext_input : in std_logic_vector(5 downto 0);
      hr        : out std_logic_vector(4 downto 0);
      min       : out std_logic_vector(5 downto 0);
      sec       : out std_logic_vector(5 downto 0);
      hr_en     : out std_logic;
      min_en    : out std_logic
      --            sec_en     : out std_logic
    );
  end component;

  component CLK_div_100 is
    port (
      clk_in  : in std_logic;
      clk_out : out std_logic
    );
  end component;

  component Dec_2_BCD_Decoder is
    port (
      hr_in   : in std_logic_vector(4 downto 0);
      min_in  : in std_logic_vector(5 downto 0);
      sec_in  : in std_logic_vector(5 downto 0);
      hr_out  : out std_logic_vector(7 downto 0);
      min_out : out std_logic_vector(7 downto 0);
      sec_out : out std_logic_vector(7 downto 0)
    );
  end component;

  component DS1302_Controller is
    port (
      clk1     : in std_logic;
      rstn     : in std_logic;
      wr_btn   : in std_logic;
      hr       : in std_logic_vector(7 downto 0);
      min      : in std_logic_vector(7 downto 0);
      sec      : in std_logic_vector(7 downto 0);
      time_out : out std_logic_vector(63 downto 0);
      CE       : out std_logic;
      SCLK     : out std_logic;
      IO       : inout std_logic
    );
  end component;

  component Sev_Seg_Display is
    port (
      clk, rstn : in std_logic;
      hr        : in std_logic_vector(7 downto 0);
      min       : in std_logic_vector(7 downto 0);
      sec       : in std_logic_vector(7 downto 0);
      seg       : out std_logic_vector(7 downto 0);
      an        : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Internal signals
  signal clk1          : std_logic;
  signal hr            : std_logic_vector(4 downto 0);
  signal min, sec      : std_logic_vector(5 downto 0);
  signal hr_bcd        : std_logic_vector(7 downto 0);
  signal min_bcd       : std_logic_vector(7 downto 0);
  signal sec_bcd       : std_logic_vector(7 downto 0);
  signal time_data_out : std_logic_vector(63 downto 0);
  signal hr_internal   : std_logic_vector(7 downto 0);
  signal min_internal  : std_logic_vector(7 downto 0);
  signal sec_internal  : std_logic_vector(7 downto 0);

begin
  -- Component instantiations
  Time_Set : Time_Setting
  port map
  (
    clk       => clk1,
    rstn      => rstn,
    set       => set_btn,
    ext_input => ext_input,
    hr        => hr,
    min       => min,
    sec       => sec,
    hr_en     => hr_en,
    min_en    => min_en
    --            sec_en    => sec_en
  );

  CLK_divider_100 : CLK_div_100
  port map
  (
    clk_in  => clk100, --100MHz
    clk_out => clk1 --1MHz
  );

  D2BCD : Dec_2_BCD_Decoder
  port map
  (
    hr_in   => hr,
    min_in  => min,
    sec_in  => sec,
    hr_out  => hr_bcd,
    min_out => min_bcd,
    sec_out => sec_bcd
  );

  Controller : DS1302_Controller
  port map
  (
    clk1     => clk1,
    rstn     => rstn,
    wr_btn   => wr_btn,
    hr       => hr_bcd,
    min      => min_bcd,
    sec      => sec_bcd,
    time_out => time_data_out,
    CE       => CE,
    SCLK     => SCLK,
    IO       => IO
  );

  HEX_Disp : Sev_Seg_Display
  port map
  (
    clk  => clk1,
    rstn => rstn,
    hr   => hr_internal,
    min  => min_internal,
    sec  => sec_internal,
    seg  => seg,
    an   => an
  );

  -- Extract time data from RTC data
  hr_internal  <= "00" & time_data_out(21 downto 16);
  min_internal <= '0' & time_data_out(14 downto 8);
  sec_internal <= '0' & time_data_out(6 downto 0);

end architecture rtl;