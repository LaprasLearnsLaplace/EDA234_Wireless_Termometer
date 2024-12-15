library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity top is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    -- --test led
    -- led : out std_logic;
    --ADT7420
    TMP_SDA : inout std_logic;
    TMP_SCL : out std_logic;
    --SEG
    SEG : out std_logic_vector(6 downto 0);
    AN  : out std_logic_vector(7 downto 0);
    --LCD
    lcd_rw, lcd_rs, lcd_e : out std_logic;
    lcd_db                : out std_logic_vector(7 downto 0);
    --KEYBOARD
    keyboard4x4_col : in std_logic_vector(3 downto 0);
    keyboard4x4_row : out std_logic_vector(3 downto 0);
    key_num         : out std_logic_vector(3 downto 0); 
    flag_key        : out std_logic; 
    -- UART --
		RXD		: in  STD_LOGIC;
		TXD		: out STD_LOGIC
  );
end top;

architecture arch_top of top is

  signal display_select : std_logic;
  signal slow_clk       : std_logic;

  --wires
  signal wire_ADT7420_DATA           : std_logic_vector(7 downto 0);
  signal wire_SEG_temp, wire_SEG_key : std_logic_vector(6 downto 0);
  signal wire_AN_temp, wire_AN_key   : std_logic_vector(7 downto 0);
  signal wire_temp_set               : std_logic_vector(7 downto 0);
  signal wire_rxdata                 : STD_LOGIC_VECTOR (7 downto 0);


  component printf
    port (
      clk       : in std_logic;
      probe_in0 : in std_logic_vector(7 downto 0)
    );
  end component;

  component temp_top
    port (
      clk          : in std_logic;
      TMP_SDA      : inout std_logic;
      TMP_SCL      : out std_logic;
      SEG          : out std_logic_vector(6 downto 0);
      AN           : out std_logic_vector(7 downto 0);
      ADT7420_DATA : out std_logic_vector(7 downto 0)
    );
  end component;

  component lcd_controller
    port (
      clk                   : in std_logic;
      reset                 : in std_logic;
      lcd_di                : in std_logic_vector(7 downto 0);
      lcd_rw, lcd_rs, lcd_e : out std_logic;
      lcd_db                : out std_logic_vector(7 downto 0)
    );
  end component;

  component keyboard
    port (
      clk             : in std_logic;
      reset           : in std_logic;
      keyboard4x4_col : in std_logic_vector(3 downto 0); 
      keyboard4x4_row : out std_logic_vector(3 downto 0); 
      key_num         : out std_logic_vector(3 downto 0); 
      flag_key        : out std_logic; 
      Seg             : out std_logic_vector(6 downto 0); 
      AN              : out std_logic_vector(7 downto 0); 
      temp_set        : out std_logic_vector(7 downto 0)
    );
  end component;

  component uart is
    port (clk   : in std_logic;
          reset : in std_logic;
          rx    : in std_logic;

          tx : out std_logic);
  end component;

  component uart_top is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        rx  : in STD_LOGIC;
        tx  : out STD_LOGIC;
        rxdata : out STD_LOGIC_VECTOR(7 downto 0)
    );
  end component;
	

begin

  -- printTX : printf
  -- port map
  -- (
  --   clk       => clk,
  --   probe_in0 => wire_uart_txData
  -- );

  printRX : printf
  port map
  (
    clk       => clk,
    probe_in0 => wire_rxdata
  );

  temp_top_inst : temp_top
  port map
  (
    clk          => clk,
    TMP_SDA      => TMP_SDA,
    TMP_SCL      => TMP_SCL,
    SEG          => wire_SEG_temp,
    AN           => wire_AN_temp,
    ADT7420_DATA => wire_ADT7420_DATA
  );

  lcd_controller_inst : lcd_controller
  port map
  (
    clk    => clk,
    reset  => reset,
    lcd_di => wire_ADT7420_DATA,
    lcd_rw => lcd_rw,
    lcd_rs => lcd_rs,
    lcd_e  => lcd_e,
    lcd_db => lcd_db
  );

  keyboard_inst : keyboard
  port map
  (
    clk             => clk,
    reset           => reset,
    keyboard4x4_col => keyboard4x4_col,
    keyboard4x4_row => keyboard4x4_row,
    key_num         => key_num,
    flag_key        => flag_key,
    Seg             => wire_SEG_key,
    AN              => wire_AN_key,
    temp_set        => wire_temp_set
  );

  uart_top_inst: uart_top
   port map(
      clk => clk,
      rst => reset,
      rx => RXD,
      tx => TXD,
      rxdata => wire_rxdata
  );


  -- divider
  divider : process (clk)
    variable count : integer := 0;
  begin
    if rising_edge(clk) then
      count := count + 1;
      if count = 10999 then
        slow_clk <= not slow_clk;
        count := 0;
      end if;
    end if;
  end process divider;

  display_sel : process (slow_clk)
  begin
    if rising_edge(slow_clk) then
      display_select <= not display_select;
    end if;
  end process display_sel;

  SEG <= wire_SEG_temp when display_select = '0' else
    wire_SEG_key;
  AN <= wire_AN_temp when display_select = '0' else
    wire_AN_key;

end arch_top;
