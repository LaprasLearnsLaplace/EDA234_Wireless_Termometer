----------------------------------------------------------------------------------
-- Group: Group 1
-- Engineer: Ziheng Li
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity temp_top is
  port (
    clk     : in std_logic;
    TMP_SDA : inout std_logic;
    TMP_SCL : out std_logic;
    ADT7420_DATA : out std_logic_vector(7 downto 0)
  );
end temp_top;

architecture Behavioral of temp_top is

  signal wire_200KHz        : std_logic;
  signal wire_temp_data     : std_logic_vector(7 downto 0);
  signal tMSB, tLSB         : std_logic_vector(7 downto 0) := (others => '0');

  component i2c_ctrl
    port (
      clk_200KHz     : in std_logic;
      temp_data      : out std_logic_vector(7 downto 0);
      SDA            : inout std_logic;
      SCL            : out std_logic;
      tMSB_A, tLSB_A : out std_logic_vector(7 downto 0)
    );
  end component;

  component clk_200KHz
    port (
      clk_100MHz : in std_logic;
      clk_200KHz : out std_logic
    );
  end component;

begin

  clk_200KHz_inst : clk_200KHz
  port map
  (
    clk_100MHz => clk,
    clk_200KHz => wire_200KHz
  );

  i2c_master_inst : i2c_ctrl
  port map
  (
    clk_200KHz => wire_200KHz,
    temp_data  => wire_temp_data,
    SDA        => TMP_SDA,
    SCL        => TMP_SCL,
    tMSB_A     => tMSB,
    tLSB_A     => tLSB
  );

  ADT7420_DATA <= wire_temp_data;
  
end Behavioral;
