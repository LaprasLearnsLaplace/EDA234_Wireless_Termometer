library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_ctrl is
  generic (
    sys_clk : integer := 100_000_000; -- Main system clock speed (Hz)
    bus_clk : integer := 400_000 -- I2C bus speed (Hz)
  );

  port (
    -- Basic control signals
    clk : in std_logic; -- Main clock input
    rst : in std_logic; -- Reset input (active low)
    en  : in std_logic; -- Start signal

    -- Data and control signals
    rw        : in std_logic; -- '0' = write, '1' = read
    addr      : in std_logic_vector(6 downto 0); -- Device address
    data_wr   : in std_logic_vector(7 downto 0); -- Data to send
    busy      : out std_logic; -- Shows if busy
    data_rd   : out std_logic_vector(7 downto 0); -- Data received
    ack_error : buffer std_logic; -- Error flag

    -- I2C bus pins
    sda : inout std_logic; -- Data line
    scl : inout std_logic -- Clock line
  );
end entity i2c_ctrl;

architecture i2c_ctrl_arch of i2c_ctrl is
  -- Calculate clock divider value
  constant divider : integer := (sys_clk/bus_clk)/4; -- System clocks in 1/4 of SCL

  -- All possible states
  type state is(idle, start, command, slv_ack1, wr, rd, slv_ack2, mstr_ack, stop);
  signal current_state : state;

  -- Clock signals
  signal data_clk      : std_logic;
  signal data_clk_prev : std_logic; -- Used to find clock edges
  signal scl_clk       : std_logic;
  signal scl_en        : std_logic := '0';

  -- Data signals
  signal sda_int  : std_logic := '1'; -- Internal data line
  signal sda_en_n : std_logic;
  signal addr_rw  : std_logic_vector(7 downto 0); -- Address + read/write bit
  signal data_tx  : std_logic_vector(7 downto 0); -- Data to send
  signal data_rx  : std_logic_vector(7 downto 0); -- Data received

  -- Control signals
  signal bit_cnt : integer range 0 to 7 := 7; -- Counts bits sent/received
  signal stretch : std_logic            := '0'; -- For clock stretching

begin
  -- Make clock signals for I2C bus
  process (clk, rst)
    variable count : integer range 0 to divider * 4; -- For timing
  begin
    if (rst = '0') then -- On reset
      stretch <= '0';
      count := 0;
    elsif (clk'event and clk = '1') then
      data_clk_prev <= data_clk; -- Save old clock value

      -- Update counter
      if (count = divider * 4 - 1) then
        count := 0;
      elsif (stretch = '0') then -- If no clock stretching
        count := count + 1;
      end if;

      -- Make clock patterns
      case count is
        when 0 to divider - 1 => -- First quarter
          scl_clk  <= '0';
          data_clk <= '0';
        when divider to divider * 2 - 1 => -- Second quarter
          scl_clk  <= '0';
          data_clk <= '1';
        when divider * 2 to divider * 3 - 1 => -- Third quarter
          scl_clk <= '1';
          if (scl = '0') then -- Check if slave is stretching clock
            stretch <= '1';
          else
            stretch <= '0';
          end if;
          data_clk <= '1';
        when others => -- Fourth quarter
          scl_clk  <= '1';
          data_clk <= '0';
      end case;
    end if;
  end process;

  -- Main state machine
  process (clk, rst)
  begin
    if (rst = '0') then -- On reset
      current_state <= idle;
      busy          <= '1';
      scl_en        <= '0';
      sda_int       <= '1';
      ack_error     <= '0';
      bit_cnt       <= 7;
      data_rd       <= "00000000";

    elsif (clk'event and clk = '1') then
      -- On rising edge of data clock
      if (data_clk = '1' and data_clk_prev = '0') then
        case current_state is
          when idle => -- Waiting for start
            if (en = '1') then
              busy          <= '1';
              addr_rw       <= addr & rw;
              data_tx       <= data_wr;
              current_state <= start;
            else
              busy          <= '0';
              current_state <= idle;
            end if;

          when start => -- Begin transfer
            busy          <= '1';
            sda_int       <= addr_rw(bit_cnt);
            current_state <= command;

          when command => -- Send address and read/write bit
            if (bit_cnt = 0) then
              sda_int       <= '1';
              bit_cnt       <= 7;
              current_state <= slv_ack1;
            else
              bit_cnt       <= bit_cnt - 1;
              sda_int       <= addr_rw(bit_cnt - 1);
              current_state <= command;
            end if;

          when slv_ack1 => -- Wait for slave to accept command
            if (addr_rw(0) = '0') then
              sda_int       <= data_tx(bit_cnt);
              current_state <= wr;
            else
              sda_int       <= '1';
              current_state <= rd;
            end if;

          when wr => -- Write data
            busy <= '1';
            if (bit_cnt = 0) then
              sda_int       <= '1';
              bit_cnt       <= 7;
              current_state <= slv_ack2;
            else
              bit_cnt       <= bit_cnt - 1;
              sda_int       <= data_tx(bit_cnt - 1);
              current_state <= wr;
            end if;

          when rd => -- Read data
            busy <= '1';
            if (bit_cnt = 0) then
              if (en = '1' and addr_rw = addr & rw) then
                sda_int <= '0'; -- Send ACK
              else
                sda_int <= '1'; -- Send NACK
              end if;
              bit_cnt       <= 7;
              data_rd       <= data_rx;
              current_state <= mstr_ack;
            else
              bit_cnt       <= bit_cnt - 1;
              current_state <= rd;
            end if;

          when slv_ack2 => -- Wait for slave ACK (write)
            if (en = '1') then
              busy    <= '0';
              addr_rw <= addr & rw;
              data_tx <= data_wr;
              if (addr_rw = addr & rw) then
                sda_int       <= data_wr(bit_cnt);
                current_state <= wr;
              else
                current_state <= start;
              end if;
            else
              current_state <= stop;
            end if;

          when mstr_ack => -- Master ACK after read
            if (en = '1') then
              busy    <= '0';
              addr_rw <= addr & rw;
              data_tx <= data_wr;
              if (addr_rw = addr & rw) then
                sda_int       <= '1';
                current_state <= rd;
              else
                current_state <= start;
              end if;
            else
              current_state <= stop;
            end if;

          when stop => -- End transfer
            busy          <= '0';
            current_state <= idle;
        end case;

        -- On falling edge of data clock
      elsif (data_clk = '0' and data_clk_prev = '1') then
        case current_state is
          when start =>
            if (scl_en = '0') then
              scl_en    <= '1';
              ack_error <= '0';
            end if;

          when slv_ack1 => -- Check slave ACK
            if (sda /= '0' or ack_error = '1') then
              ack_error <= '1';
            end if;

          when rd => -- Read data bit
            data_rx(bit_cnt) <= sda;

          when slv_ack2 => -- Check slave ACK
            if (sda /= '0' or ack_error = '1') then
              ack_error <= '1';
            end if;

          when stop =>
            scl_en <= '0';

          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  -- Control SDA output
  with current_state select
    sda_en_n <= data_clk_prev when start, -- Make start condition
    not data_clk_prev when stop, -- Make stop condition
    sda_int when others; -- Normal data

  -- Control SCL and SDA pins
  scl <= '0' when (scl_en = '1' and scl_clk = '0') else
    'Z';
  sda <= '0' when sda_en_n = '0' else
    'Z';

end architecture i2c_ctrl_arch;