----------------------------------------------------------------------------------
-- June 26, 2021 
-- 
-- Author: Stefan Schrijvers & Rowan Goemans
--  
-- Module Name: ecc_mult_double
-- Description: ECC scalar multiplication using montgomery power ladder. Wth concurrent
--              point addition and doubling
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

entity ecc_mult_double is
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
end ecc_mult_double;

-- Describe the behavior of the module in the architecture
architecture behavioral of ecc_mult_double is

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
        op_o: in std_logic_vector(1 downto 0);
        op_a: in std_logic_vector(1 downto 0);
        op_b: in std_logic_vector(1 downto 0);
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
    , s_init_x1
    , s_init_y1
    , s_init_z1
    , s_init_x2
    , s_init_y2
    , s_init_z2
    , s_add_double_exec
    , s_sync_adder_doubler_rx0
    , s_sync_adder_doubler_rx1
    , s_sync_adder_doubler_ry0
    , s_sync_adder_doubler_ry1
    , s_sync_adder_doubler_rz0
    , s_sync_adder_doubler_rz1
    , s_sync_adder_doubler_rz2
    , s_sync_doubler_adder_rx0
    , s_sync_doubler_adder_rx1
    , s_sync_doubler_adder_ry0
    , s_sync_doubler_adder_ry1
    , s_sync_doubler_adder_rz0
    , s_sync_doubler_adder_rz1
    , s_sync_doubler_adder_rz2
    , s_result_r0x
    , s_result_r0y
    , s_result_r0z
    , s_write_results
    );
signal state: my_state := s_comp_init;

signal exec_triggered_i: std_logic := '0';

-- Signals to track intermediates.
signal op_o_i_adder: std_logic_vector(1 downto 0);
signal op_a_i_adder: std_logic_vector(1 downto 0);
signal op_b_i_adder: std_logic_vector(1 downto 0);

signal op_o_i_doubler: std_logic_vector(1 downto 0);
signal op_a_i_doubler: std_logic_vector(1 downto 0);
signal op_b_i_doubler: std_logic_vector(1 downto 0);

signal n_i: unsigned(log2n-1 downto 0) := (others => '0');

-- Declare and initialize internal signals to drive the inputs of components
signal point_start_i: std_logic := '0';

signal point_busy_i_adder: std_logic;
signal point_done_i_adder: std_logic;
signal point_busy_i_doubler: std_logic;
signal point_done_i_doubler: std_logic;


signal point_m_enable_i_adder: std_logic := '0';
signal point_m_din_i_adder: std_logic_vector(n-1 downto 0) := (others => '0');
signal point_m_dout_i_adder: std_logic_vector(n-1 downto 0);
signal point_m_rw_i_adder: std_logic := '0';
signal point_m_address_i_adder: std_logic_vector(4 downto 0) := (others => '0');

signal point_m_enable_i_doubler: std_logic := '0';
signal point_m_din_i_doubler: std_logic_vector(n-1 downto 0) := (others => '0');
signal point_m_dout_i_doubler: std_logic_vector(n-1 downto 0);
signal point_m_rw_i_doubler: std_logic := '0';
signal point_m_address_i_doubler: std_logic_vector(4 downto 0) := (others => '0');

begin

-- Instantiate components.
inst_ecc_add_double_adder: ecc_add_double
    generic map(n=>n,
            log2n=>log2n)
    port map(
        start=>point_start_i,
        rst=>rst,
        clk=>clk,
        add_double=>'0',
        busy=>point_busy_i_adder,
        done=>point_done_i_adder,
        op_o=>op_o_i_adder,
        op_a=>op_a_i_adder,
        op_b=>op_b_i_adder,
        m_enable=>point_m_enable_i_adder,
        m_din=>point_m_din_i_adder,
        m_dout=>point_m_dout_i_adder,
        m_rw=>point_m_rw_i_adder,
        m_address=>point_m_address_i_adder
    );

inst_ecc_add_double_doubler: ecc_add_double
    generic map(n=>n,
            log2n=>log2n)
    port map(
        start=>point_start_i,
        rst=>rst,
        clk=>clk,
        add_double=>'1',
        busy=>point_busy_i_doubler,
        done=>point_done_i_doubler,
        op_o=>op_o_i_doubler,
        op_a=>op_a_i_doubler,
        op_b=>op_b_i_doubler,
        m_enable=>point_m_enable_i_doubler,
        m_din=>point_m_din_i_doubler,
        m_dout=>point_m_dout_i_doubler,
        m_rw=>point_m_rw_i_doubler,
        m_address=>point_m_address_i_doubler
    );

FSM_state: process(rst, clk) is
    variable next_n: unsigned(log2n-1 downto 0);
begin
    if rst = '1' then
        state <= s_comp_init;
        op_o_i_adder <= "10";
        op_a_i_adder <= "00";
        op_b_i_adder <= "01";
        op_o_i_doubler <= "10";
        op_a_i_doubler <= "00";
        op_b_i_doubler <= "01";
    elsif rising_edge(clk) then
        case state is
            when s_comp_init =>
                if point_busy_i_adder = '0' and point_busy_i_doubler = '0' then
                    state <= s_idle;
                end if;
            when s_idle =>
                if start = '1' then
                    n_i <= to_unsigned(n-1, n_i'length);
                    state <= s_init_prime;
                end if;
            when s_init_prime =>
                state <= s_init_a;
            when s_init_a =>
                state <= s_init_b;
            when s_init_b =>
                state <= s_init_x1;
            when s_init_x1 =>
                state <= s_init_y1;
            when s_init_y1 =>
                state <= s_init_z1;
            when s_init_z1 =>
                state <= s_init_x2;
            when s_init_x2 =>
                state <= s_init_y2;
            when s_init_y2 =>
                state <= s_init_z2;
            when s_init_z2 =>
                state <= s_add_double_exec;
                if scalar(to_integer(n_i)) = '1' then
                    op_o_i_adder <= "00";
                    op_a_i_adder <= "00";
                    op_b_i_adder <= "01";
                    op_o_i_doubler <= "01";
                    op_a_i_doubler <= "01";
                    op_b_i_doubler <= "00";
                else
                    op_o_i_adder <= "01";
                    op_a_i_adder <= "00";
                    op_b_i_adder <= "01";
                    op_o_i_doubler <= "00";
                    op_a_i_doubler <= "00";
                    op_b_i_doubler <= "01";
                end if;
            when s_add_double_exec =>
                if exec_triggered_i = '0' then
                    exec_triggered_i <= '1';
                    point_start_i <= '1';
                elsif point_done_i_adder = '0' then
                    point_start_i <= '0';
                    exec_triggered_i <= '1';
                else
                    point_start_i <= '0';
                    exec_triggered_i <= '0';

                    state <= s_sync_adder_doubler_rx0;
                end if;
            when s_sync_adder_doubler_rx0 =>
                state <= s_sync_adder_doubler_rx1;
            when s_sync_adder_doubler_rx1 =>
                state <= s_sync_adder_doubler_ry0;
            when s_sync_adder_doubler_ry0 =>
                state <= s_sync_adder_doubler_ry1;
            when s_sync_adder_doubler_ry1 =>
                state <= s_sync_adder_doubler_rz0;
            when s_sync_adder_doubler_rz0 =>
                state <= s_sync_adder_doubler_rz1;
            when s_sync_adder_doubler_rz1 =>
                state <= s_sync_adder_doubler_rz2;
            when s_sync_adder_doubler_rz2 =>
                state <= s_sync_doubler_adder_rx0;
            when s_sync_doubler_adder_rx0 =>
                state <= s_sync_doubler_adder_rx1;
            when s_sync_doubler_adder_rx1 =>
                state <= s_sync_doubler_adder_ry0;
            when s_sync_doubler_adder_ry0 =>
                state <= s_sync_doubler_adder_ry1;
            when s_sync_doubler_adder_ry1 =>
                state <= s_sync_doubler_adder_rz0;
            when s_sync_doubler_adder_rz0 =>
                state <= s_sync_doubler_adder_rz1;
            when s_sync_doubler_adder_rz1 =>
                state <= s_sync_doubler_adder_rz2;
            when s_sync_doubler_adder_rz2 =>
                next_n := n_i - to_unsigned(1, n_i'length);
                if n_i = to_unsigned(0, n_i'length) then
                    state <= s_result_r0x;
                elsif scalar(to_integer(next_n)) = '1' then
                    op_o_i_adder <= "00";
                    op_a_i_adder <= "00";
                    op_b_i_adder <= "01";
                    op_o_i_doubler <= "01";
                    op_a_i_doubler <= "01";
                    op_b_i_doubler <= "00";
                    n_i <= next_n;
                    state <= s_add_double_exec;
                else
                    op_o_i_adder <= "01";
                    op_a_i_adder <= "00";
                    op_b_i_adder <= "01";
                    op_o_i_doubler <= "00";
                    op_a_i_doubler <= "00";
                    op_b_i_doubler <= "01";
                    n_i <= next_n;
                    state <= s_add_double_exec;
                end if;
            when s_result_r0x =>
                state <= s_result_r0y;
            when s_result_r0y =>
                sgx <= point_m_dout_i_adder;
                state <= s_result_r0z;
            when s_result_r0z =>
                sgy <= point_m_dout_i_adder;
                state <= s_write_results;
            when s_write_results =>
                sgz <= point_m_dout_i_adder;
                state <= s_idle;
        end case;
    end if;
end process;

FSM_mem: process(state, prime, a, b, gx, gy, gz)
begin
    case state is
        when s_comp_init =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_address_i_adder <= (others => '0');
            point_m_enable_i_adder <= '0';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_address_i_doubler <= (others => '0');
            point_m_enable_i_doubler <= '0';
        when s_idle =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_address_i_adder <= (others => '0');
            point_m_enable_i_adder <= '0';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_address_i_doubler <= (others => '0');
            point_m_enable_i_doubler <= '0';
        when s_init_prime =>
            point_m_din_i_adder <= prime;
            point_m_rw_i_adder <= '1';
            point_m_address_i_adder <= P_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= prime;
            point_m_rw_i_doubler <= '1';
            point_m_address_i_doubler <= P_ADS;
            point_m_enable_i_doubler <= '1';
        when s_init_a =>
            point_m_din_i_adder <= a;
            point_m_rw_i_adder <= '1';
            point_m_address_i_adder <= A_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= a;
            point_m_rw_i_doubler <= '1';
            point_m_address_i_doubler <= A_ADS;
            point_m_enable_i_doubler <= '1';
        when s_init_b =>
            point_m_din_i_adder <= b;
            point_m_rw_i_adder <= '1';
            point_m_address_i_adder <= B_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= b;
            point_m_rw_i_doubler <= '1';
            point_m_address_i_doubler <= B_ADS;
            point_m_enable_i_doubler <= '1';
        when s_init_x1 =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '1';
            point_m_address_i_adder <= X1_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '1';
            point_m_address_i_doubler <= X1_ADS;
            point_m_enable_i_doubler <= '1';
        when s_init_y1 =>
            point_m_din_i_adder <= std_logic_vector(to_unsigned(1, point_m_din_i_adder'length));
            point_m_rw_i_adder <= '1';
            point_m_address_i_adder <= Y1_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= std_logic_vector(to_unsigned(1, point_m_din_i_doubler'length));
            point_m_rw_i_doubler <= '1';
            point_m_address_i_doubler <= Y1_ADS;
            point_m_enable_i_doubler <= '1';
        when s_init_z1 =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '1';
            point_m_address_i_adder <= Z1_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '1';
            point_m_address_i_doubler <= Z1_ADS;
            point_m_enable_i_doubler <= '1';
        when s_init_x2 =>
            point_m_din_i_adder <= gx;
            point_m_rw_i_adder <= '1';
            point_m_address_i_adder <= X2_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= gx;
            point_m_rw_i_doubler <= '1';
            point_m_address_i_doubler <= X2_ADS;
            point_m_enable_i_doubler <= '1';
        when s_init_y2 =>
            point_m_din_i_adder <= gy;
            point_m_rw_i_adder <= '1';
            point_m_address_i_adder <= Y2_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= gy;
            point_m_rw_i_doubler <= '1';
            point_m_address_i_doubler <= Y2_ADS;
            point_m_enable_i_doubler <= '1';
        when s_init_z2 =>
            point_m_din_i_adder <= gz;
            point_m_rw_i_adder <= '1';
            point_m_address_i_adder <= Z2_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= gz;
            point_m_rw_i_doubler <= '1';
            point_m_address_i_doubler <= Z2_ADS;
            point_m_enable_i_doubler <= '1';
        when s_add_double_exec =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_address_i_adder <= (others => '0');
            point_m_enable_i_adder <= '0';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_address_i_doubler <= (others => '0');
            point_m_enable_i_doubler <= '0';
        when s_sync_adder_doubler_rx0 | s_sync_adder_doubler_rx1 =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_enable_i_doubler <= '0';
            if op_o_i_adder = "00" then
                point_m_address_i_adder <= X1_ADS;
                point_m_address_i_doubler <= X1_ADS;
            else
                point_m_address_i_adder <= X2_ADS;
                point_m_address_i_doubler <= X2_ADS;
            end if;
        when s_sync_adder_doubler_ry0 | s_sync_adder_doubler_ry1 =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= point_m_dout_i_adder;
            point_m_rw_i_doubler <= '1';
            point_m_enable_i_doubler <= '1';
            if op_o_i_adder = "00" then
                point_m_address_i_adder <= Y1_ADS;
                point_m_address_i_doubler <= X1_ADS;
            else
                point_m_address_i_adder <= Y2_ADS;
                point_m_address_i_doubler <= X2_ADS;
            end if;
        when s_sync_adder_doubler_rz0 | s_sync_adder_doubler_rz1 =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= point_m_dout_i_adder;
            point_m_rw_i_doubler <= '1';
            point_m_enable_i_doubler <= '1';
            if op_o_i_adder = "00" then
                point_m_address_i_adder <= Z1_ADS;
                point_m_address_i_doubler <= Y1_ADS;
            else
                point_m_address_i_adder <= Z2_ADS;
                point_m_address_i_doubler <= Y2_ADS;
            end if;
        when s_sync_adder_doubler_rz2 =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_enable_i_adder <= '0';
            point_m_din_i_doubler <= point_m_dout_i_adder;
            point_m_rw_i_doubler <= '1';
            point_m_enable_i_doubler <= '1';
            if op_o_i_adder = "00" then
                point_m_address_i_adder <= Z1_ADS;
                point_m_address_i_doubler <= Z1_ADS;
            else
                point_m_address_i_adder <= Z2_ADS;
                point_m_address_i_doubler <= Z2_ADS;
            end if;
        when s_sync_doubler_adder_rx0 | s_sync_doubler_adder_rx1 =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_enable_i_adder <= '0';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_enable_i_doubler <= '1';
            if op_o_i_doubler = "00" then
                point_m_address_i_adder <= X1_ADS;
                point_m_address_i_doubler <= X1_ADS;
            else
                point_m_address_i_adder <= X2_ADS;
                point_m_address_i_doubler <= X2_ADS;
            end if;
        when s_sync_doubler_adder_ry0 | s_sync_doubler_adder_ry1 =>
            point_m_din_i_adder <= point_m_dout_i_doubler;
            point_m_rw_i_adder <= '1';
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_enable_i_doubler <= '1';
            if op_o_i_doubler = "00" then
                point_m_address_i_adder <= X1_ADS;
                point_m_address_i_doubler <= Y1_ADS;
            else
                point_m_address_i_adder <= X2_ADS;
                point_m_address_i_doubler <= Y2_ADS;
            end if;
        when s_sync_doubler_adder_rz0 | s_sync_doubler_adder_rz1 =>
            point_m_din_i_adder <= point_m_dout_i_doubler;
            point_m_rw_i_adder <= '1';
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_enable_i_doubler <= '1';
            if op_o_i_doubler = "00" then
                point_m_address_i_adder <= Y1_ADS;
                point_m_address_i_doubler <= Z1_ADS;
            else
                point_m_address_i_adder <= Y2_ADS;
                point_m_address_i_doubler <= Z2_ADS;
            end if;
        when s_sync_doubler_adder_rz2 =>
            point_m_din_i_adder <= point_m_dout_i_doubler;
            point_m_rw_i_adder <= '1';
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_enable_i_doubler <= '0';
            if op_o_i_doubler = "00" then
                point_m_address_i_adder <= Z1_ADS;
                point_m_address_i_doubler <= Z1_ADS;
            else
                point_m_address_i_adder <= Z2_ADS;
                point_m_address_i_doubler <= Z2_ADS;
            end if;
        when s_result_r0x =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_address_i_adder <= X1_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_address_i_doubler <= X1_ADS;
            point_m_enable_i_doubler <= '1';
        when s_result_r0y =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_address_i_adder <= Y1_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_address_i_doubler <= Y1_ADS;
            point_m_enable_i_doubler <= '1';
        when s_result_r0z =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_address_i_adder <= Z1_ADS;
            point_m_enable_i_adder <= '1';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_address_i_doubler <= Z1_ADS;
            point_m_enable_i_doubler <= '1';
        when s_write_results =>
            point_m_din_i_adder <= (others => '0');
            point_m_rw_i_adder <= '0';
            point_m_address_i_adder <= (others => '0');
            point_m_enable_i_adder <= '0';
            point_m_din_i_doubler <= (others => '0');
            point_m_rw_i_doubler <= '0';
            point_m_address_i_doubler <= (others => '0');
            point_m_enable_i_doubler <= '0';
    end case;
end process;

FSM_out: process(state)
begin
    case state is
        when s_comp_init =>
            busy <= '1';
            done <= '0';
        when s_idle =>
            busy <= '0';
            done <= '0';
        when s_init_prime | s_init_a | s_init_b 
             | s_init_x1 | s_init_y1 | s_init_z1
             | s_init_x2 | s_init_y2 | s_init_z2
             | s_add_double_exec
             | s_sync_adder_doubler_rx0 | s_sync_adder_doubler_ry0
	     | s_sync_adder_doubler_rz0 | s_sync_doubler_adder_rx0
	     | s_sync_doubler_adder_ry0 | s_sync_doubler_adder_rz0
             | s_sync_adder_doubler_rx1 | s_sync_adder_doubler_ry1
             | s_sync_adder_doubler_rz1 | s_sync_adder_doubler_rz2
             | s_sync_doubler_adder_rx1 | s_sync_doubler_adder_ry1
             | s_sync_doubler_adder_rz1 | s_sync_doubler_adder_rz2
             | s_result_r0x | s_result_r0y | s_result_r0z =>
            busy <= '1';
            done <= '0';
        when s_write_results =>
            busy <= '1';
            done <= '1';
    end case;
end process;
    
end behavioral;
