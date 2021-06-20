----------------------------------------------------------------------------------
-- June 6, 2021 
-- 
-- Author: Stefan Schrijvers & Rowan Goemans
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

-- include memory constants for point model
library work;
use work.ecc_constants.ALL;

entity ecc_mult is
    generic(
        n: integer := 8;
        log2n: integer := 3);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;

        -- Standard configuration (prime, constants a and b).
        prime: in std_logic_vector(n-1 downto 0);
        a: in std_logic_vector(n-1 downto 0);
        b: in std_logic_vector(n-1 downto 0);

        -- ECC multiplication parameters scalar and point on the curve.
        scalar: in std_logic_vector(n-1 downto 0);
        gx: in std_logic_vector(n-1 downto 0);
        gy: in std_logic_vector(n-1 downto 0);
        gz: in std_logic_vector(n-1 downto 0);

        -- Output point
        sgx: out std_logic_vector(n-1 downto 0);
        sgy: out std_logic_vector(n-1 downto 0);
        sgz: out std_logic_vector(n-1 downto 0);

        -- Status output signals.
        done: out std_logic;
        busy: out std_logic);
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
    ( s_comp_init
    , s_idle
    , s_init_prime
    , s_init_a
    , s_init_b
    , s_add_load_x1
    , s_add_load_y1
    , s_add_load_z1
    , s_add_load_x2
    , s_add_load_y2
    , s_add_load_z2
    , s_add_exec
    , s_add_store_x3
    , s_add_store_y3
    , s_add_store_z3
    , s_double_load_x1
    , s_double_load_y1
    , s_double_load_z1
    , s_double_exec
    , s_double_store_x3
    , s_double_store_y3
    , s_double_store_z3
    , s_write_results
    );
signal state: my_state := s_comp_init;

signal exec_triggered_i: std_logic := '0';

-- Signals to track intermediates.
signal prime_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal a_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal b_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal scalar_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r0x_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r0y_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r0z_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r1x_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r1y_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal r1z_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal n_i: unsigned(log2n-1 downto 0) := (others => '0');

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

FSM_state: process(rst, clk) is
begin
    if rst = '1' then
        state <= s_comp_init;
        prime_i <= (others => '0');
        a_i <= (others => '0');
        b_i <= (others => '0');
        scalar_i <= (others => '0');
        r0x_i <= (others => '0');
        r0y_i <= std_logic_vector(to_unsigned(1, r0y_i'length));
        r0z_i <= (others => '0');
        r1x_i <= (others => '0');
        r1y_i <= (others => '0');
        r1z_i <= (others => '0');
    elsif rising_edge(clk) then
        case state is
            when s_comp_init =>
                report "===== S_COMP_INIT =====";
                if point_busy_i = '0' then
                    state <= s_idle;
                end if;
            when s_idle =>
                report "===== S_IDLE =====";
                if start = '1' then
                    prime_i <= prime;
                    a_i <= a;
                    b_i <= b;
                    scalar_i <= scalar;
                    r1x_i <= gx;
                    r1y_i <= gy;
                    r1z_i <= gz;
                    n_i <= to_unsigned(n-1, n_i'length);
                    state <= s_init_prime;
                end if;
            when s_init_prime =>
                report "===== s_init_prime =====";
                point_m_din_i <= prime_i;
                point_m_rw_i <= '1';
                point_m_address_i <= P_ADS;
                state <= s_init_a;
            when s_init_a =>
                report "===== s_init_a =====";
                point_m_din_i <= a_i;
                point_m_rw_i <= '1';
                point_m_address_i <= A_ADS;
                state <= s_init_b;
            when s_init_b =>
                report "===== s_init_b =====";
                point_m_din_i <= b_i;
                point_m_rw_i <= '1';
                point_m_address_i <= B_ADS;
                state <= s_add_load_x1;
            when s_add_load_x1 =>
                report "===== s_add_load_x1 =====";
                point_m_din_i <= r0x_i;
                point_m_rw_i <= '1';
                point_m_address_i <= X1_ADS;
                state <= s_add_load_y1;
            when s_add_load_y1 =>
                report "===== s_add_load_y1 =====";
                point_m_din_i <= r0y_i;
                point_m_rw_i <= '1';
                point_m_address_i <= Y1_ADS;
                state <= s_add_load_z1;
            when s_add_load_z1 =>
                report "===== s_add_load_z1 =====";
                point_m_din_i <= r0z_i;
                point_m_rw_i <= '1';
                point_m_address_i <= Z1_ADS;
                state <= s_add_load_x2;
            when s_add_load_x2 =>
                report "===== s_add_load_x2 =====";
                point_m_din_i <= r1x_i;
                point_m_rw_i <= '1';
                point_m_address_i <= X2_ADS;
                state <= s_add_load_y2;
            when s_add_load_y2 =>
                report "===== s_add_load_y2 =====";
                point_m_din_i <= r1y_i;
                point_m_rw_i <= '1';
                point_m_address_i <= Y2_ADS;
                state <= s_add_load_z2;
            when s_add_load_z2 =>
                report "===== s_add_load_z2 =====";
                point_m_din_i <= r1z_i;
                point_m_rw_i <= '1';
                point_m_address_i <= Z2_ADS;
                state <= s_add_exec;
            when s_add_exec =>
                report "===== s_add_exec =====";
                if exec_triggered_i = '0' then
                    exec_triggered_i <= '1';
                    point_start_i <= '1';
                    point_add_double_i <= '0';
                elsif point_done_i = '0' then
                    point_start_i <= '0';
                    exec_triggered_i <= '1';
                else
                    point_start_i <= '0';
                    exec_triggered_i <= '0';
                    state <= s_add_store_x3;
                    point_m_rw_i <= '0';
                    point_m_address_i <= X3_ADS;
                end if;
            when s_add_store_x3 =>
                report "===== s_add_store_x3 ====";
                report "point_m_dout_i: " & to_string(point_m_dout_i);
                if scalar_i(to_integer(n_i)) = '1' then
                    r0x_i <= point_m_dout_i;
                else
                    r1x_i <= point_m_dout_i;
                end if;
                point_m_rw_i <= '0';
                point_m_address_i <= Y3_ADS;
                state <= s_add_store_y3;
            when s_add_store_y3 =>
                report "===== s_add_store_y3 ====";
                if scalar_i(to_integer(n_i)) = '1' then
                    r0y_i <= point_m_dout_i;
                else
                    r1y_i <= point_m_dout_i;
                end if;
                point_m_rw_i <= '0';
                point_m_address_i <= Z3_ADS;
                state <= s_add_store_z3;
            when s_add_store_z3 =>
                report "===== s_add_store_z3 ====";
                if scalar_i(to_integer(n_i)) = '1' then
                    r0z_i <= point_m_dout_i;
                else
                    r1z_i <= point_m_dout_i;
                end if;
                state <= s_double_load_x1;
            when s_double_load_x1 =>
                report "===== s_double_load_x1 ==";
                if scalar_i(to_integer(n_i)) = '1' then
                    point_m_din_i <= r1x_i;
                else
                    point_m_din_i <= r0x_i;
                end if;
                point_m_rw_i <= '1';
                point_m_address_i <= X1_ADS;
                state <= s_double_load_y1;
            when s_double_load_y1 =>
                report "===== s_double_load_y1 ==";
                if scalar_i(to_integer(n_i)) = '1' then
                    point_m_din_i <= r1y_i;
                else
                    point_m_din_i <= r0y_i;
                end if;
                point_m_rw_i <= '1';
                point_m_address_i <= Y1_ADS;
                state <= s_double_load_z1;
            when s_double_load_z1 =>
                report "===== s_double_load_z1 ==";
                if scalar_i(to_integer(n_i)) = '1' then
                    point_m_din_i <= r1z_i;
                else
                    point_m_din_i <= r0z_i;
                end if;
                point_m_rw_i <= '1';
                point_m_address_i <= Z1_ADS;
                state <= s_double_exec;
            when s_double_exec =>
                report "===== s_double_exec =====";
                if exec_triggered_i = '0' then
                    exec_triggered_i <= '1';
                    point_start_i <= '1';
                    point_add_double_i <= '1';
                elsif point_done_i = '0' then
                    point_start_i <= '0';
                    exec_triggered_i <= '1';
                else
                    point_start_i <= '0';
                    exec_triggered_i <= '0';

                    state <= s_double_store_x3;
                    point_m_rw_i <= '0';
                    point_m_address_i <= X3_ADS;
                end if;
            when s_double_store_x3 =>
                report "===== s_double_store_x3 =====";
                if scalar_i(to_integer(n_i)) = '1' then
                    r1x_i <= point_m_dout_i;
                else
                    r0x_i <= point_m_dout_i;
                end if;
                point_m_rw_i <= '0';
                point_m_address_i <= Y3_ADS;
                state <= s_double_store_y3;
            when s_double_store_y3 =>
                report "===== s_double_store_y3 =====";
                if scalar_i(to_integer(n_i)) = '1' then
                    r1y_i <= point_m_dout_i;
                else
                    r0y_i <= point_m_dout_i;
                end if;
                point_m_rw_i <= '0';
                point_m_address_i <= Z3_ADS;
                state <= s_double_store_z3;
            when s_double_store_z3 =>
                report "===== s_double_store_z3 =====";
                if scalar_i(to_integer(n_i)) = '1' then
                    r1z_i <= point_m_dout_i;
                else
                    r0z_i <= point_m_dout_i;
                end if;
                if n_i = to_unsigned(0, n_i'length) then
                    state <= s_write_results;
                else
                    n_i <= n_i - to_unsigned(1, n_i'length);
                    state <= s_add_load_x1;
                end if;
            when s_write_results =>
                report "===== S_WRITE_RESULTS =====";
                state <= s_idle;
                report "result x: " & to_string(r0x_i);
                report "result y: " & to_string(r0y_i);
                report "result z: " & to_string(r0z_i);
                sgx <= r0x_i;
                sgy <= r0y_i;
                sgz <= r0z_i;
        end case;
    end if;
end process;

FSM_enable: process(clk)
begin
    if rising_edge(clk) then
        case state is
            when s_comp_init =>
                point_m_enable_i <= '0';
            when s_idle =>
                point_m_enable_i <= '1';
            when s_init_prime | s_init_a | s_init_b 
                | s_add_load_x1 | s_add_load_y1 | s_add_load_z1
                | s_add_load_x2 | s_add_load_y2 | s_add_load_z2
                | s_double_load_x1 | s_double_load_y1 | s_double_load_z1 =>
                point_m_enable_i <= '1';
            when s_add_store_x3 | s_add_store_y3 | s_add_store_z3
                | s_double_store_x3 | s_double_store_y3 | s_double_store_z3 =>
                point_m_enable_i <= '1';
            when s_add_exec | s_double_exec =>
                point_m_enable_i <= '0';
            when s_write_results =>
                point_m_enable_i <= '0';
        end case;
    end if;
end process;

FSM_out: process(clk, state)
begin
    case state is
        when s_comp_init =>
            busy <= '1';
            done <= '0';
        when s_idle =>
            busy <= '0';
            done <= '0';
        when s_init_prime | s_init_a | s_init_b 
            | s_add_load_x1 | s_add_load_y1 | s_add_load_z1
            | s_add_load_x2 | s_add_load_y2 | s_add_load_z2
            | s_double_load_x1 | s_double_load_y1 | s_double_load_z1 =>
            busy <= '1';
            done <= '0';
        when s_add_store_x3 | s_add_store_y3 | s_add_store_z3
            | s_double_store_x3 | s_double_store_y3 | s_double_store_z3 =>
            busy <= '1';
            done <= '0';
        when s_add_exec | s_double_exec =>
            busy <= '1';
            done <= '0';
        when s_write_results =>
            busy <= '1';
            done <= '1';
    end case;
end process;
    
end behavioral;
