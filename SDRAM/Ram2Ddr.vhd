-------------------------------------------------------------------------------
--                                                                 
--  COPYRIGHT (C) 2014, Digilent RO. All rights reserved
--                                                                  
-------------------------------------------------------------------------------
-- FILE NAME      : ram2ddr.vhd
-- MODULE NAME    : RAM to DDR2 Interface Converter with internal XADC
--                  instantiation
-- AUTHOR         : Mihaita Nagy
-- AUTHOR'S EMAIL : mihaita.nagy@digilent.ro
-------------------------------------------------------------------------------
-- REVISION HISTORY
-- VERSION  DATE         AUTHOR         DESCRIPTION
-- 1.0      2014-02-04   Mihaita Nagy   Created
-- 1.1      2014-04-04   Mihaita Nagy   Fixed double registering write bug
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity Ram2Ddr is
   port (
      -- Common
      clk_200MHz_i         : in    std_logic; -- 200 MHz system clock
      rst_i                : in    std_logic; -- active high system reset
      device_temp_i        : in    std_logic_vector(11 downto 0);
      
      -- RAM interface
      ram_a                : in    std_logic_vector(26 downto 0);
      ram_dq_i             : in    std_logic_vector(31 downto 0);
      ram_dq_o             : out   std_logic_vector(31 downto 0);
      ram_cen              : in    std_logic;
      ram_oen              : in    std_logic;
      ram_wen              : in    std_logic;
      ram_ub               : in    std_logic;
      ram_lb               : in    std_logic;
      ram_sel              : in    std_logic_vector(3 downto 0);
      
      -- DDR2 interface
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
end Ram2Ddr;

architecture Behavioral of Ram2Ddr is

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
component MIG
port (
   -- Inouts
   ddr2_dq              : inout std_logic_vector(15 downto 0);
   ddr2_dqs_p           : inout std_logic_vector(1 downto 0);
   ddr2_dqs_n           : inout std_logic_vector(1 downto 0);
   -- Outputs
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
   -- Inputs
   sys_clk_i            : in    std_logic;
   sys_rst              : in    std_logic;
   -- user interface signals
   app_addr             : in    std_logic_vector(26 downto 0);
   app_cmd              : in    std_logic_vector(2 downto 0);
   app_en               : in    std_logic;
   app_wdf_data         : in    std_logic_vector(127 downto 0);
   app_wdf_end          : in    std_logic;
   app_wdf_mask         : in    std_logic_vector(15 downto 0);
   app_wdf_wren         : in    std_logic;
   app_rd_data          : out   std_logic_vector(127 downto 0);
   app_rd_data_end      : out   std_logic;
   app_rd_data_valid    : out   std_logic;
   app_rdy              : out   std_logic;
   app_wdf_rdy          : out   std_logic;
   app_sr_req           : in    std_logic;
   app_sr_active        : out   std_logic;
   app_ref_req          : in    std_logic;
   app_ref_ack          : out   std_logic;
   app_zq_req           : in    std_logic;
   app_zq_ack           : out   std_logic;
   ui_clk               : out   std_logic;
   ui_clk_sync_rst      : out   std_logic;
   device_temp_i        : in    std_logic_vector(11 downto 0);
   init_calib_complete  : out   std_logic);
end component;

------------------------------------------------------------------------
-- Local Type Declarations
------------------------------------------------------------------------
-- FSM
type state_type is (stIdle, stPreset, stSendData, stSetCmdRd, stSetCmdWr,
                    stWaitCen);

------------------------------------------------------------------------
-- Constant Declarations
------------------------------------------------------------------------
-- ddr commands
constant CMD_WRITE         : std_logic_vector(2 downto 0) := "000";
constant CMD_READ          : std_logic_vector(2 downto 0) := "001";

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
-- state machine
signal cState, nState      : state_type; 

-- global signals
signal mem_ui_clk          : std_logic;
signal mem_ui_rst          : std_logic;
signal rst                 : std_logic;
signal rstn                : std_logic;
signal sreg                : std_logic_vector(1 downto 0);

-- ram internal signals with additional pipeline registers
signal ram_a_int           : std_logic_vector(26 downto 0);
signal ram_a_int2          : std_logic_vector(26 downto 0); -- Added pipeline register
signal ram_dq_i_int        : std_logic_vector(31 downto 0);
signal ram_dq_i_int2       : std_logic_vector(31 downto 0); -- Added pipeline register
signal ram_dq_i_int3       : std_logic_vector(31 downto 0); -- Added pipeline register
signal ram_cen_int         : std_logic;
signal ram_cen_int2        : std_logic; -- Added pipeline register
signal ram_oen_int         : std_logic;
signal ram_oen_int2        : std_logic; -- Added pipeline register
signal ram_wen_int         : std_logic;
signal ram_wen_int2        : std_logic; -- Added pipeline register
signal ram_ub_int          : std_logic;
signal ram_lb_int          : std_logic;
signal ram_sel_int         : std_logic_vector(3 downto 0);
signal ram_sel_int2        : std_logic_vector(3 downto 0); -- Added pipeline register

-- ddr user interface signals
signal mem_addr            : std_logic_vector(26 downto 0);
signal mem_cmd             : std_logic_vector(2 downto 0);
signal mem_en              : std_logic;
signal mem_rdy             : std_logic;
signal mem_wdf_rdy         : std_logic;
signal mem_wdf_data        : std_logic_vector(127 downto 0);
signal mem_wdf_data_reg    : std_logic_vector(127 downto 0); -- Added pipeline register
signal mem_wdf_end         : std_logic;
signal mem_wdf_mask        : std_logic_vector(15 downto 0);
signal mem_wdf_wren        : std_logic;
signal mem_rd_data         : std_logic_vector(127 downto 0);
signal mem_rd_data_reg     : std_logic_vector(127 downto 0); -- Added pipeline register
signal mem_rd_data_end     : std_logic;
signal mem_rd_data_valid   : std_logic;
signal calib_complete      : std_logic;

-- Output data pipeline registers
signal ram_dq_o_reg        : std_logic_vector(31 downto 0);

begin

------------------------------------------------------------------------
-- Registering the active-low reset for the MIG component
------------------------------------------------------------------------
   RSTSYNC: process(clk_200MHz_i)
   begin
      if rising_edge(clk_200MHz_i) then
         sreg <= sreg(0) & rst_i;
         rstn <= not sreg(1);
      end if;
   end process RSTSYNC;
   
------------------------------------------------------------------------
-- DDR controller instance
------------------------------------------------------------------------
   Inst_DDR: MIG
   port map (
      ddr2_dq              => ddr2_dq,
      ddr2_dqs_p           => ddr2_dqs_p,
      ddr2_dqs_n           => ddr2_dqs_n,
      ddr2_addr            => ddr2_addr,
      ddr2_ba              => ddr2_ba,
      ddr2_ras_n           => ddr2_ras_n,
      ddr2_cas_n           => ddr2_cas_n,
      ddr2_we_n            => ddr2_we_n,
      ddr2_ck_p            => ddr2_ck_p,
      ddr2_ck_n           => ddr2_ck_n,
      ddr2_cke             => ddr2_cke,
      ddr2_cs_n            => ddr2_cs_n,
      ddr2_dm              => ddr2_dm,
      ddr2_odt             => ddr2_odt,
      -- Inputs
      sys_clk_i            => clk_200MHz_i,
      sys_rst              => rstn,
      -- user interface signals
      app_addr             => mem_addr,
      app_cmd              => mem_cmd,
      app_en               => mem_en,
      app_wdf_data         => mem_wdf_data,
      app_wdf_end          => mem_wdf_end,
      app_wdf_mask         => mem_wdf_mask,
      app_wdf_wren         => mem_wdf_wren,
      app_rd_data          => mem_rd_data,
      app_rd_data_end      => mem_rd_data_end,
      app_rd_data_valid    => mem_rd_data_valid,
      app_rdy              => mem_rdy,
      app_wdf_rdy          => mem_wdf_rdy,
      app_sr_req           => '0',
      app_sr_active        => open,
      app_ref_req          => '0',
      app_ref_ack          => open,
      app_zq_req           => '0',
      app_zq_ack           => open,
      ui_clk               => mem_ui_clk,
      ui_clk_sync_rst      => mem_ui_rst,
      device_temp_i        => device_temp_i,
      init_calib_complete  => calib_complete);

------------------------------------------------------------------------
-- Multi-stage Input Registration Process
------------------------------------------------------------------------
   REG_IN: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         -- First stage
         ram_a_int <= ram_a;
         ram_dq_i_int <= ram_dq_i;
         ram_cen_int <= ram_cen;
         ram_oen_int <= ram_oen;
         ram_wen_int <= ram_wen;
         ram_ub_int <= ram_ub;
         ram_lb_int <= ram_lb;
         ram_sel_int <= ram_sel;
         
         -- Second stage
         ram_a_int2 <= ram_a_int;
         ram_dq_i_int2 <= ram_dq_i_int;
         ram_dq_i_int3 <= ram_dq_i_int2;
         ram_cen_int2 <= ram_cen_int;
         ram_oen_int2 <= ram_oen_int;
         ram_wen_int2 <= ram_wen_int;
         ram_sel_int2 <= ram_sel_int;
      end if;
   end process REG_IN;
   
------------------------------------------------------------------------
-- State Machine 
------------------------------------------------------------------------
-- Register states
   SYNC_PROCESS: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         if mem_ui_rst = '1' then
            cState <= stIdle;
         else
            cState <= nState;
         end if;
      end if;
   end process SYNC_PROCESS;

-- Next state logic with registered inputs
   NEXT_STATE_DECODE: process(cState, calib_complete, ram_cen_int2, 
   mem_rdy, mem_wdf_rdy, ram_wen_int2, ram_oen_int2)
   begin
      nState <= cState;
      case(cState) is
         when stIdle =>
            if ram_cen_int2 = '0' and 
               calib_complete = '1' then
               nState <= stPreset;
            end if;
         when stPreset =>
            if ram_wen_int2 = '0' then
               nState <= stSendData;
            elsif ram_oen_int2 = '0' then
               nState <= stSetCmdRd;
            end if;
         when stSendData =>
            if mem_wdf_rdy = '1' then
               nState <= stSetCmdWr;
            end if;
         when stSetCmdRd =>
            if mem_rdy = '1' then
               nState <= stWaitCen;
            end if;
         when stSetCmdWr =>
            if mem_rdy = '1' then
                nState <= stWaitCen;
             end if;
          when stWaitCen =>
             if ram_cen_int2 = '1' then
                nState <= stIdle;
             end if;
          when others => 
             nState <= stIdle;            
       end case;      
    end process;
 
 ------------------------------------------------------------------------
 -- Generating the FIFO control and command signals according to the 
 -- current state of the FSM with registered outputs
 ------------------------------------------------------------------------
    MEM_WR_CTL: process(mem_ui_clk)
    begin
       if rising_edge(mem_ui_clk) then
          if cState = stSendData then
             mem_wdf_wren <= '1';
             mem_wdf_end <= '1';
          else
             mem_wdf_wren <= '0';
             mem_wdf_end <= '0';
          end if;
       end if;
    end process MEM_WR_CTL;
    
    MEM_CTL: process(mem_ui_clk)
    begin
       if rising_edge(mem_ui_clk) then
          if cState = stSetCmdRd then
             mem_en <= '1';
             mem_cmd <= CMD_READ;
          elsif cState = stSetCmdWr then
             mem_en <= '1'; 
             mem_cmd <= CMD_WRITE;
          else
             mem_en <= '0';
             mem_cmd <= (others => '0');
          end if;
       end if;
    end process MEM_CTL;
    
 ------------------------------------------------------------------------
 -- Decoding the least significant 3 bits of the address and creating
 -- accordingly the 'mem_wdf_mask' with registered outputs
 ------------------------------------------------------------------------
    WR_DATA_MSK: process(mem_ui_clk)
    begin
       if rising_edge(mem_ui_clk) then
          if cState = stPreset then
             case(ram_a_int2(2 downto 0)) is
                when "000" =>
                      -- 32-bit
                      mem_wdf_mask <= "111111111111"&ram_sel_int2;
                when "010" => 
                      -- 32-bit
                      mem_wdf_mask <= "11111111"&ram_sel_int2&"1111";
                when "100" =>
                      -- 16-bit
                      mem_wdf_mask <= "1111"&ram_sel_int2&"11111111";
                when "110" =>
                       -- 16-bit
                      mem_wdf_mask <= ram_sel_int2&"111111111111";
                when others => 
                      mem_wdf_mask <= (others => '1');
             end case;
          end if;
       end if;
    end process WR_DATA_MSK;
    
 ------------------------------------------------------------------------
 -- Registering write data and read/write address with pipeline stages
 ------------------------------------------------------------------------
    WR_DATA_ADDR: process(mem_ui_clk)
    begin
       if rising_edge(mem_ui_clk) then
          -- Pipeline stage for write data
          if cState = stPreset then
             mem_wdf_data_reg <= ram_dq_i_int3 & ram_dq_i_int3 & 
                                ram_dq_i_int3 & ram_dq_i_int3;
          end if;
          -- Final output stage
          mem_wdf_data <= mem_wdf_data_reg;
       end if;
    end process WR_DATA_ADDR;
 
    WR_ADDR: process(mem_ui_clk)
    begin
       if rising_edge(mem_ui_clk) then
          if cState = stPreset then
             mem_addr <= ram_a_int2(26 downto 3) & "000";
          end if;
       end if;
    end process WR_ADDR;
 
 ------------------------------------------------------------------------
 -- Read data process with pipeline stages
 ------------------------------------------------------------------------
    RD_DATA: process(mem_ui_clk)
    begin
       if rising_edge(mem_ui_clk) then
          -- First pipeline stage - register incoming data
          if mem_rd_data_valid = '1' and mem_rd_data_end = '1' then
             mem_rd_data_reg <= mem_rd_data;
          end if;
          
          -- Second pipeline stage - output selection
          if cState = stWaitCen and mem_rd_data_valid = '1' and 
             mem_rd_data_end = '1' then
             case(ram_a_int2(2 downto 0)) is
                when "000" => 
                   ram_dq_o_reg <= mem_rd_data_reg(31 downto 0);
                when "010" => 
                   ram_dq_o_reg <= mem_rd_data_reg(63 downto 32);
                when "100" => 
                   ram_dq_o_reg <= mem_rd_data_reg(95 downto 64);
                when "110" => 
                   ram_dq_o_reg <= mem_rd_data_reg(127 downto 96);
                when others => 
                   ram_dq_o_reg <= (others => '0');
             end case;
          end if;
          
          -- Final output stage
          ram_dq_o <= ram_dq_o_reg;
       end if;
    end process RD_DATA;
 
 end Behavioral;