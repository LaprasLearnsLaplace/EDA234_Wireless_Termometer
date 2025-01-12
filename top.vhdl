library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity top is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    mrst  : in std_logic;
    
    -- tada~
    temp_sw : in std_logic;
    mem_sw : in std_logic;
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
    -- key_num         : out std_logic_vector(3 downto 0); 
    -- flag_key        : out std_logic; 
    -- UART TEST--
		RXD		: in  STD_LOGIC;
		TXD		: out STD_LOGIC;
    -- UART BLUETOOTH
    rx : in STD_LOGIC;  
    tx : out STD_LOGIC;
    --DDR2
    BTNL        : in STD_LOGIC;
    BTNR        : in STD_LOGIC;
    LED         : out STD_LOGIC_VECTOR(15 downto 0);
    LED16_R     : out STD_LOGIC;
    LED17_G     : out STD_LOGIC;
    ddr2_addr            : out   std_logic_vector(12 downto 0);
    ddr2_ba              : out   std_logic_vector(2 downto 0);
    ddr2_ras_n           : out   std_logic;
    ddr2_cas_n           : out   std_logic;
    ddr2_we_n            : out   std_logic;
    ddr2_ck_p            : out   std_logic_vector(0 downto 0);
    ddr2_ck_n            : out   std_logic_vector(0 downto 0);
    ddr2_cke             : out   std_logic_vector(0 downto 0);
    ddr2_cs_n            : out   std_logic_vector(0 downto 0);
    ddr2_dm              : out   std_logic_vector(1 downto 0);
    ddr2_odt             : out   std_logic_vector(0 downto 0);
    ddr2_dq              : inout std_logic_vector(15 downto 0);
    ddr2_dqs_p           : inout std_logic_vector(1 downto 0);
    ddr2_dqs_n           : inout std_logic_vector(1 downto 0);
    -- speaker
    speaker_out : out std_logic
  );
end top;

architecture arch_top of top is

  signal display_select : std_logic;
  signal slow_clk       : std_logic;

  --wires
  signal wire_TEMP_DATA   : std_logic_vector(7 downto 0);
  signal wire_ADT7420_DATA, wire_DS18S20_DATA   : std_logic_vector(7 downto 0);
  signal wire_alarm, wire_ADT7420_alarm, wire_DS18S20_alarm : std_logic;
  signal wire_SEG_temp, wire_SEG_key : std_logic_vector(6 downto 0);
  signal wire_AN_temp, wire_AN_key   : std_logic_vector(7 downto 0);
  signal wire_temp_set               : std_logic_vector(7 downto 0);
  signal wire_rxdata                 : STD_LOGIC_VECTOR(7 downto 0);
  signal wire_max_min_temp    : std_logic_vector(15 downto 0);
  signal wire_LCD_DATA, wire_DDR_OUT    : std_logic_vector(15 downto 0);
  signal select_ds18s20, temp_sw_prev : STD_LOGIC := '0'; 
  signal reset_n     : std_logic;  


  component printf
    port (
      clk       : in std_logic;
      probe_in0 : in std_logic_vector(7 downto 0)
    );
  end component;

  component uart_rx is
    Port ( 
        clk : in STD_LOGIC;
        rx  : in STD_LOGIC;
        rx_data_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
  end component;

  component temp_top
    port (
      clk          : in std_logic;
      TMP_SDA      : inout std_logic;
      TMP_SCL      : out std_logic;
      ADT7420_DATA : out std_logic_vector(7 downto 0)
    );
  end component;

  component find_max_min is
    Port ( 
        clk          : in std_logic;
        reset        : in std_logic;
        temp_sw      : in std_logic;
        data_in      : in std_logic_vector(7 downto 0);
        max_min_temp : out std_logic_vector(15 downto 0)
    );
  end component;

  component lcd_controller
    port (
      clk                   : in std_logic;
      reset                 : in std_logic;
      lcd_di                : in std_logic_vector(15 downto 0);
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
      -- key_num         : out std_logic_vector(3 downto 0); 
      -- flag_key        : out std_logic; 
      Seg             : out std_logic_vector(6 downto 0); 
      AN              : out std_logic_vector(7 downto 0); 
      temp_set        : out std_logic_vector(7 downto 0)
    );
  end component;

  -- component uart_top is
  --   Port ( 
  --       clk : in STD_LOGIC;
  --       rst : in STD_LOGIC;
  --       rx  : in STD_LOGIC;
  --       tx  : out STD_LOGIC;
  --       rxdata : out STD_LOGIC_VECTOR(7 downto 0)
  --   );
  -- end component;
	
  component speaker_alarm is
    Port (
        clk         : in  std_logic;  -- 100MHz clock input
        reset       : in  std_logic;  -- Active-low asynchronous reset
        enable      : in  std_logic;  -- Enable signal
        speaker_out : out std_logic   -- Speaker output signal
    );
  end component;

  component DDR2 is
    Port (
        -- Clock and reset
        CLK100MHZ   : in STD_LOGIC;
        reset       : in STD_LOGIC;

        datain      : in STD_LOGIC_VECTOR(15 downto 0);
        -- Button inputs
        BTNL        : in STD_LOGIC;
        BTNR        : in STD_LOGIC;
        
        -- LED outputs
        LED         : out STD_LOGIC_VECTOR(15 downto 0);
        LED16_R     : out STD_LOGIC;
        LED17_G     : out STD_LOGIC;

        -- DDR2 memory signals
        ddr2_addr            : out   std_logic_vector(12 downto 0);
        ddr2_ba              : out   std_logic_vector(2 downto 0);
        ddr2_ras_n           : out   std_logic;
        ddr2_cas_n           : out   std_logic;
        ddr2_we_n            : out   std_logic;
        ddr2_ck_p            : out   std_logic_vector(0 downto 0);
        ddr2_ck_n            : out   std_logic_vector(0 downto 0);
        ddr2_cke             : out   std_logic_vector(0 downto 0);
        ddr2_cs_n            : out   std_logic_vector(0 downto 0);
        ddr2_dm              : out   std_logic_vector(1 downto 0);
        ddr2_odt             : out   std_logic_vector(0 downto 0);
        ddr2_dq              : inout std_logic_vector(15 downto 0);
        ddr2_dqs_p           : inout std_logic_vector(1 downto 0);
        ddr2_dqs_n           : inout std_logic_vector(1 downto 0)
    );
  end component;

  component temp_comparator is
    Port ( 
        clk : in STD_LOGIC;                                    
        rst : in STD_LOGIC;                                   
        temp_set : in STD_LOGIC_VECTOR(7 downto 0);          
        ADT7420_DATA : in STD_LOGIC_VECTOR(7 downto 0);      
        DS18S20_DATA : in STD_LOGIC_VECTOR(7 downto 0);                                   
        ADT7420_alarm : out STD_LOGIC;                      
        DS18S20_alarm : out STD_LOGIC                         
    );
  end component;

  component seg7
    port (
      clk        : in std_logic;
      data       : in std_logic_vector(7 downto 0);
      SEG        : out std_logic_vector(6 downto 0);
      AN         : out std_logic_vector(7 downto 0)
    );
  end component;

begin



  reset_n <= not reset;
  -- print12 : printf
  -- port map
  -- (
  --   clk       => clk,
  --   probe_in0 => (others => wire_ADT7420_alarm)
  -- );

  uart_rx_inst : uart_rx
    port map (
        clk => clk,
        rx => rx,
        rx_data_out => wire_DS18S20_DATA
  );

  seg7_inst : seg7
  port map
  (
    clk        => clk,
    data       => wire_TEMP_DATA,
    SEG        => wire_SEG_temp,
    AN         => wire_AN_temp
  );

  speaker_alarm_inst: speaker_alarm
  port map(
      clk => clk,
      reset => reset,
      enable => wire_alarm,
      speaker_out => speaker_out
  );

  ADT7420_temp_top_inst : temp_top
  port map
  (
    clk          => clk,
    TMP_SDA      => TMP_SDA,
    TMP_SCL      => TMP_SCL,
    ADT7420_DATA => wire_ADT7420_DATA
  );

  find_inst: find_max_min
   port map(
      clk => clk,
      reset => mrst,
      temp_sw => temp_sw,
      data_in => wire_TEMP_DATA,
      max_min_temp => wire_max_min_temp
  );


  temp_comparator_inst: temp_comparator
   port map(
      clk => clk,
      rst => reset,
      temp_set => wire_temp_set,
      ADT7420_DATA => wire_ADT7420_DATA,
      DS18S20_DATA => wire_DS18S20_DATA,
      ADT7420_alarm => wire_ADT7420_alarm,
      DS18S20_alarm => wire_DS18S20_alarm
  );


  lcd_controller_inst : lcd_controller
  port map
  (
    clk    => clk,
    reset  => reset,
    lcd_di => wire_LCD_DATA,
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
    -- key_num         => key_num,
    -- flag_key        => flag_key,
    Seg             => wire_SEG_key,
    AN              => wire_AN_key,
    temp_set        => wire_temp_set
  );

  -- uart_top_inst: uart_top
  --  port map(
  --     clk => clk,
  --     rst => reset,
  --     rx => RXD,
  --     tx => TXD,
  --     rxdata => wire_rxdata
  -- );

  DDR2_inst: DDR2
   port map(
      CLK100MHZ => clk,
      reset => reset,
      datain => wire_max_min_temp,
      BTNL => BTNL,
      BTNR => BTNR,
      LED => wire_DDR_OUT,
      LED16_R => LED16_R,
      LED17_G => LED17_G,
      ddr2_addr => ddr2_addr,
      ddr2_ba => ddr2_ba,
      ddr2_ras_n => ddr2_ras_n,
      ddr2_cas_n => ddr2_cas_n,
      ddr2_we_n => ddr2_we_n,
      ddr2_ck_p => ddr2_ck_p,
      ddr2_ck_n => ddr2_ck_n,
      ddr2_cke => ddr2_cke,
      ddr2_cs_n => ddr2_cs_n,
      ddr2_dm => ddr2_dm,
      ddr2_odt => ddr2_odt,
      ddr2_dq => ddr2_dq,
      ddr2_dqs_p => ddr2_dqs_p,
      ddr2_dqs_n => ddr2_dqs_n
  );
  LED <= wire_DDR_OUT;
  
  temp_sw_proc : process(clk, reset)
  begin
    if rising_edge(clk) then
      if reset = '1' then
          select_ds18s20 <= '0';
          temp_sw_prev <= '0';
          wire_TEMP_DATA <= wire_ADT7420_DATA;
      else
          temp_sw_prev <= temp_sw;
          if temp_sw = '1' and temp_sw_prev = '0' then
              select_ds18s20 <= not select_ds18s20;
          end if;
          if select_ds18s20 = '1' then
              wire_TEMP_DATA <= wire_DS18S20_DATA;
              wire_alarm <= wire_DS18S20_alarm;
          else
              wire_TEMP_DATA <= wire_ADT7420_DATA;
              wire_alarm <= wire_ADT7420_alarm;
          end if;
      end if;
    end if;
  end process;

  mem_sw_proc : process(clk)
  begin
    if rising_edge(clk) then
        if mem_sw = '1'  then
            wire_LCD_DATA <= wire_DDR_OUT;
        else
            wire_LCD_DATA <= wire_max_min_temp;
        end if;
    end if;
  end process;

  -- divider
  divider : process (clk)
    variable count : integer := 0;
  begin
    if rising_edge(clk) then
      count := count + 1;
      if count = 14999 then
        slow_clk <= not slow_clk;
        count := 0;
      end if;
    end if;
  end process divider;

  display_sel : process (clk)
  begin
    if rising_edge(clk) then
      if slow_clk = '1' then
        display_select <= not display_select;
      end if;
    end if;
  end process display_sel;

  SEG <= wire_SEG_temp when display_select = '0' else
    wire_SEG_key;
  AN <= wire_AN_temp when display_select = '0' else
    wire_AN_key;

end arch_top;
