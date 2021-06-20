----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: ecc_mult
-- Description: ECC scalar multiplication using montgomery power ladder.
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- include the IEEE.MATH_REAL to do math with constants
use IEEE.MATH_REAL.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

entity ecc_mult is
    generic(
        n: integer := 8;
        log2n: integer := 3);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        scalar: in unsigned(n-1 downto 0);
        gx: in std_logic_vector(n-1 downto 0);
        gy: in std_logic_vector(n-1 downto 0);
        gz: in std_logic_vector(n-1 downto 0);
        done: out std_logic;
        busy: out std_logic;
        sgx: out std_logic_vector(n-1 downto 0);
        sgy: out std_logic_vector(n-1 downto 0);
        sgz: out std_logic_vector(n-1 downto 0);
end ecc_mult;

-- Describe the behavior of the module in the architecture
architecture behavioral of ecc_mult is

-- Declare components
component ecc_add_double is
    generic(
        n: integer := 8;
        log2n: integer := 3);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        add_double: in std_logic;
        done: out std_logic;
        busy: out std_logic;
        m_enable: in std_logic;
        m_din:in std_logic_vector(n-1 downto 0);
        m_dout:out std_logic_vector(n-1 downto 0);
        m_rw:in std_logic;
        m_address:in std_logic_vector(4 downto 0));
end component;

-- Declare signals and types
type my_state is
    ( s_idle
    , s_load_point
    , s_execute
    , s_write_results
    );
signal state: my_state := s_idle;

signal exec_triggered_i: std_logic := '0';

-- Signals to track intermediates.
signal scalar_i: unsigned(n-1 downto 0) := (others => '0');
signal r0x_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r0y_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r0z_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r1x_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r1y_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r1z_i: std_logic_vector(n-1 downto 0) := (others => '0');

-- Declare and initialize internal signals to drive the inputs of components
signal point_start_i: std_logic := '0';
signal point_add_double_i: std_logic := '0';
signal point_busy_i: std_logic;
signal point_done_i: std_logic;
signal point_m_enable_i: std_logic := '0';
signal point_m_din_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal point_m_dout_i: std_logic_vector(n-1 downto 0);
signal point_m_rw_i: std_logic := '0';
signal point_m_address_i: std_logic_vector(4 downto 0) := (others => '0');

begin

-- Instantiate components.
inst_ecc_add_double: ecc_add_double
    generic map(n=>n,
            log2n=>log2n)
    port map(
        start=>point_start_i,
        rst=>rst,
        clk=>clk,
        add_double=>point_add_double_i,
        busy=>point_busy_i,
        done=>point_done_i,
        m_enable=>point_m_enable_i,
        m_din=>point_m_din_i,
        m_dout=>point_m_dout_i,
        m_rw=>point_m_rw_i,
        m_address=>point_m_address_i
    );

-- Capture inputs on start into registers
reg_proc: process(rst, clk)
begin
    if rst = '1' then
        scalar_i <= (others => '0');
        r0x_i <= (others => '0');
        r0y_i <= (others => '0');
        r0z_i <= (others => '0');
        r1x_i <= (others => '0');
        r1y_i <= (others => '0');
        r1z_i <= (others => '0');
    elsif rising_edge(clk) then
        if start = '1' then
            scalar_i <= scalar;
            r0x_i <= (others => '0');
            r0y_i <= std_logic_vector(to_unsigned(1, r0y_i'length));
            r0z_i <= (others => '0');
            r1x_i <= gx;
            r1y_i <= gy;
            r1z_i <= gz;
        end if;
    end if;
end process;

FSM_state: process(rst, clk) is
begin
    if rst = '1' then
        state <= s_idle;
    elsif rising_edge(clk) then
        case state is
            when s_idle =>
                report "===== S_IDLE =====";
                if start = '1' then
                    state <= s_execute;
                end if;
            when s_load_point =>
                -- TODO; first addition then double
                -- add: r0{x,y,z} to {X,Y,Z}1 and r1{x,y,z} to {X,Y,Z}2
                -- double r{0,1}{x,y,z} to {X,Y,Z}1 depending on b_i
            when s_execute =>
                report "===== S_EXECUTE =====";
                if exec_triggered_i = '0' then
                    exec_triggered_i <= '1';
                    point_start_i <= '1';
                elsif base_done_i = '0' then
                    point_start_i <= '0';
                    exec_triggered_i <= '1';
                else
                    point_start_i <= '0';
                    exec_triggered_i <= '0';

                    if scalar_i = to_unsigned(0, scalar_i'length) then
                        state <= s_write_results;
                    else
                        scalar_i = scalar_i - 1;
                    end if;
                end if;

                
            when s_write_results =>
                report "===== S_WRITE_RESULTS =====";
                state <= s_idle;
        end case;
    end if;
end process;

FSM_out: process(state)
begin
    case state is
        when s_idle =>
            busy <= '0';
            done <= '0';
        when s_execute =>
            busy <= '1';
            done <= '0';
        when s_write_results =>
            busy <= '1';
            done <= '1';
    end case;
end process;
    
end behavioral;
