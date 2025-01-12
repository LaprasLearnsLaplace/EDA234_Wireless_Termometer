library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DDR2 is
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
end DDR2;

architecture Behavioral of DDR2 is

    -- Component declarations
    component clk_wiz
        port (
            clk_in1     : in STD_LOGIC;
            clk_out1    : out STD_LOGIC;
            clk_out2    : out STD_LOGIC;
            locked      : out STD_LOGIC
        );
    end component;
    
    component mem_ctrl
        port (
            clk_100MHz      : in STD_LOGIC;
            rst             : in STD_LOGIC;
            playing         : in STD_LOGIC;
            recording       : in STD_LOGIC;
            delete_clear    : out STD_LOGIC;
            RamCEn         : out STD_LOGIC;
            RamOEn         : out STD_LOGIC;
            RamWEn         : out STD_LOGIC;
            write_zero     : out STD_LOGIC;
            get_data       : out STD_LOGIC;
            data_ready     : out STD_LOGIC;
            mix_data       : out STD_LOGIC
        );
    end component;
    
    component Ram2Ddr
        port (
            clk_200MHz_i    : in STD_LOGIC;
            rst_i           : in STD_LOGIC;
            device_temp_i   : in STD_LOGIC_VECTOR(11 downto 0);
            ram_a           : in STD_LOGIC_VECTOR(26 downto 0);
            ram_dq_i        : in STD_LOGIC_VECTOR(31 downto 0);
            ram_dq_o        : out STD_LOGIC_VECTOR(31 downto 0);
            ram_cen         : in STD_LOGIC;
            ram_oen         : in STD_LOGIC;
            ram_wen         : in STD_LOGIC;
            ram_ub          : in STD_LOGIC;
            ram_lb          : in STD_LOGIC;
            ram_sel         : in STD_LOGIC_VECTOR(3 downto 0);
            ddr2_addr       : out STD_LOGIC_VECTOR(12 downto 0);
            ddr2_ba         : out STD_LOGIC_VECTOR(2 downto 0);
            ddr2_ras_n      : out STD_LOGIC;
            ddr2_cas_n      : out STD_LOGIC;
            ddr2_we_n       : out STD_LOGIC;
            ddr2_ck_p       : out STD_LOGIC_VECTOR(0 downto 0);
            ddr2_ck_n       : out STD_LOGIC_VECTOR(0 downto 0);
            ddr2_cke        : out STD_LOGIC_VECTOR(0 downto 0);
            ddr2_cs_n       : out STD_LOGIC_VECTOR(0 downto 0);
            ddr2_dm         : out STD_LOGIC_VECTOR(1 downto 0);
            ddr2_odt        : out STD_LOGIC_VECTOR(0 downto 0);
            ddr2_dq         : inout STD_LOGIC_VECTOR(15 downto 0);
            ddr2_dqs_p      : inout STD_LOGIC_VECTOR(1 downto 0);
            ddr2_dqs_n      : inout STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    -- Signal declarations
    signal clk_out_100MHZ  : STD_LOGIC;
    signal clk_out2_200MHZ : STD_LOGIC;

    signal max_block      : unsigned(22 downto 0) := (others => '0');
    signal timercnt       : unsigned(26 downto 0) := (others => '0');
    signal timerval       : unsigned(11 downto 0) := (others => '0');
    signal set_max        : STD_LOGIC;
    signal reset_max      : STD_LOGIC;
    signal p              : STD_LOGIC;
    signal r              : STD_LOGIC;

    signal del_mem        : STD_LOGIC;
    signal delete         : STD_LOGIC;
    signal delete_bank    : STD_LOGIC_VECTOR(2 downto 0);
    signal mem_bank       : STD_LOGIC_VECTOR(2 downto 0);
    signal write_zero     : STD_LOGIC;
    signal current_block  : STD_LOGIC_VECTOR(22 downto 0);
    signal buttons_db     : STD_LOGIC_VECTOR(3 downto 0);
    signal active         : STD_LOGIC_VECTOR(7 downto 0);
    signal current_bank   : STD_LOGIC_VECTOR(2 downto 0);
    signal mem_a          : STD_LOGIC_VECTOR(26 downto 0);
    signal mem_dq_i       : STD_LOGIC_VECTOR(31 downto 0);
    signal mem_dq_o       : STD_LOGIC_VECTOR(31 downto 0);
    signal mem_cen        : STD_LOGIC;
    signal mem_oen        : STD_LOGIC;
    signal mem_wen        : STD_LOGIC;
    signal mem_ub         : STD_LOGIC;
    signal mem_lb         : STD_LOGIC;
    signal mem_sel        : STD_LOGIC_VECTOR(3 downto 0);
    signal chipTemp       : STD_LOGIC_VECTOR(15 downto 0);
    signal data_flag      : STD_LOGIC;
    signal data_ready     : STD_LOGIC;
    signal mix_data       : STD_LOGIC;
    signal block44KHz     : STD_LOGIC_VECTOR(22 downto 0);
    signal mem_dq_o_b     : STD_LOGIC_VECTOR(31 downto 0);
    signal InData         : STD_LOGIC_VECTOR(31 downto 0);

    -- Constant declarations
    constant tenhz : integer := 10000000;

begin    
    
    -- Memory address assignment
    mem_a <= '0' & "00000000000010000000000000"; -- Address is 1024
    
    -- Memory control signals
    mem_ub <= '0';
    mem_lb <= '0';
    mem_sel <= "0000";
    


    clk_1: clk_wiz
    port map (
        clk_in1     => CLK100MHZ,
        clk_out1    => clk_out_100MHZ,
        clk_out2    => clk_out2_200MHZ
    );

    p <= BTNL;
    r <= BTNR;

    Ram: Ram2Ddr
    port map (
        clk_200MHz_i    => clk_out2_200MHZ,
        rst_i           => reset,
        device_temp_i   => chipTemp(11 downto 0),
        ram_a           => mem_a,
        ram_dq_i        => mem_dq_i,
        ram_dq_o        => mem_dq_o,
        ram_cen         => mem_cen,
        ram_oen         => mem_oen,
        ram_wen         => mem_wen,
        ram_ub          => mem_ub,
        ram_lb          => mem_lb,
        ram_sel         => mem_sel,
        ddr2_addr       => ddr2_addr,
        ddr2_ba         => ddr2_ba,
        ddr2_ras_n      => ddr2_ras_n,
        ddr2_cas_n      => ddr2_cas_n,
        ddr2_we_n       => ddr2_we_n,
        ddr2_ck_p       => ddr2_ck_p,
        ddr2_ck_n       => ddr2_ck_n,
        ddr2_cke        => ddr2_cke,
        ddr2_cs_n       => ddr2_cs_n,
        ddr2_dm         => ddr2_dm,
        ddr2_odt        => ddr2_odt,
        ddr2_dq         => ddr2_dq,
        ddr2_dqs_p      => ddr2_dqs_p,
        ddr2_dqs_n      => ddr2_dqs_n
    );

    -- Memory controller instantiation
    mem_controller: mem_ctrl
    port map (
        clk_100MHz   => clk_out_100MHZ,
        rst          => reset,
        playing      => p,
        recording    => r,
        delete_clear => del_mem,
        RamCEn       => mem_cen,
        RamOEn       => mem_oen,
        RamWEn       => mem_wen,
        write_zero   => write_zero,
        get_data     => data_flag,
        data_ready   => data_ready,
        mix_data     => mix_data
    );

    process(clk_out_100MHZ)
    begin
        if rising_edge(clk_out_100MHZ) then
            if data_ready = '1' then
                mem_dq_o_b <= mem_dq_o;
            end if;
        end if;
    end process;


    datain_proc : process(clk_out_100MHZ)
    begin
        if rising_edge(clk_out_100MHZ) then
            if data_flag = '1' then
                InData <= datain(15 downto 8) & x"0000" & datain(7 downto 0);
            end if;
        end if;
    end process;

    -- Write zero mux
    mem_dq_i <= InData when write_zero = '0' else x"7FFFFFFF";
    -- Output assignments
    LED <= mem_dq_o_b(31 downto 24) & mem_dq_o_b(7 downto 0);
    LED16_R <= r;
    LED17_G <= p;


end Behavioral;