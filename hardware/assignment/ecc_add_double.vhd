----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: ecc_base
-- Description: Base unit that is able to run all necessary commands.
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- include the IEEE.MATH_REAL to do math with constants
use IEEE.MATH_REAL.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

entity ecc_add_double is
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
end ecc_add_double;

-- describe the behavior of the module in the architecture
architecture behavioral of ecc_add_double is

constant RAM_ADS: integer := 5;

constant ADD_INSTR_START: integer := 0;
constant ADD_INSTR_END: integer := 39;
constant DBL_INSTR_START: integer := 40;
constant DBL_INSTR_END: integer := 70;
constant INSTR_WIDTH: Integer := 17; -- 2 bits operator, 5 bits per operand.
constant INSTR_ADS: Integer := integer(ceil(log2(real(DBL_INSTR_END))));

constant ADD_INSTR: std_logic_vector(1 downto 0) := "00";
constant SUB_INSTR: std_logic_vector(1 downto 0) := "01";
constant MUL_INSTR: std_logic_vector(1 downto 0) := "11";
constant  P_ADS: std_logic_vector(4 downto 0) := "00000";
constant  A_ADS: std_logic_vector(4 downto 0) := "00001";
constant  B_ADS: std_logic_vector(4 downto 0) := "00010";
constant X1_ADS: std_logic_vector(4 downto 0) := "00011";
constant Y1_ADS: std_logic_vector(4 downto 0) := "00100";
constant Z1_ADS: std_logic_vector(4 downto 0) := "00101";
constant X2_ADS: std_logic_vector(4 downto 0) := "00110";
constant Y2_ADS: std_logic_vector(4 downto 0) := "00111";
constant Z2_ADS: std_logic_vector(4 downto 0) := "01000";
constant X3_ADS: std_logic_vector(4 downto 0) := "01001";
constant Y3_ADS: std_logic_vector(4 downto 0) := "01010";
constant Z3_ADS: std_logic_vector(4 downto 0) := "01011";
constant t0_ADS: std_logic_vector(4 downto 0) := "01100";
constant t1_ADS: std_logic_vector(4 downto 0) := "01101";
constant t2_ADS: std_logic_vector(4 downto 0) := "01110";
constant t3_ADS: std_logic_vector(4 downto 0) := "01111";
constant t4_ADS: std_logic_vector(4 downto 0) := "10000";
constant t5_ADS: std_logic_vector(4 downto 0) := "10001";
constant t6_ADS: std_logic_vector(4 downto 0) := "10010";
constant t7_ADS: std_logic_vector(4 downto 0) := "10011";

type INSTR_ARRAY is array (0 to DBL_INSTR_END) of std_logic_vector(INSTR_WIDTH-1 downto 0);
constant instructions: INSTR_ARRAY := (
    -- Point addition
    (MUL_INSTR, t0_ADS, X1_ADS, X2_ADS),
    (MUL_INSTR, t1_ADS, Y1_ADS, Y2_ADS),
    (MUL_INSTR, t2_ADS, Z1_ADS, Z2_ADS),

    (ADD_INSTR, t3_ADS, X1_ADS, Y1_ADS),
    (ADD_INSTR, t4_ADS, X2_ADS, Y2_ADS),
    (MUL_INSTR, t3_ADS, t3_ADS, t4_ADS),

    (ADD_INSTR, t4_ADS, t0_ADS, t1_ADS),
    (SUB_INSTR, t3_ADS, t3_ADS, t4_ADS),
    (ADD_INSTR, t4_ADS, X1_ADS, Z1_ADS),

    (ADD_INSTR, t5_ADS, X2_ADS, Z2_ADS),
    (MUL_INSTR, t4_ADS, t4_ADS, t5_ADS),
    (ADD_INSTR, t5_ADS, t0_ADS, t2_ADS),

    (SUB_INSTR, t4_ADS, t4_ADS, t5_ADS),
    (ADD_INSTR, t5_ADS, Y1_ADS, Z1_ADS),
    (ADD_INSTR, X3_ADS, Y2_ADS, Z2_ADS),

    (MUL_INSTR, t5_ADS, t5_ADS, X3_ADS),
    (ADD_INSTR, X3_ADS, t1_ADS, t2_ADS),
    (SUB_INSTR, t5_ADS, t5_ADS, X3_ADS),

    (MUL_INSTR, Z3_ADS,  A_ADS, t4_ADS),
    (MUL_INSTR, X3_ADS,  B_ADS, t2_ADS),
    (ADD_INSTR, Z3_ADS, X3_ADS, Z3_ADS),

    (SUB_INSTR, X3_ADS, t1_ADS, Z3_ADS),
    (ADD_INSTR, Z3_ADS, t1_ADS, Z3_ADS),
    (MUL_INSTR, Y3_ADS, X3_ADS, Z3_ADS),

    (ADD_INSTR, t1_ADS, t0_ADS, t0_ADS),
    (ADD_INSTR, t1_ADS, t1_ADS, t0_ADS),
    (MUL_INSTR, t2_ADS,  A_ADS, t2_ADS),

    (MUL_INSTR, t4_ADS,  B_ADS, t4_ADS),
    (ADD_INSTR, t1_ADS, t1_ADS, t2_ADS),
    (SUB_INSTR, t2_ADS, t0_ADS, t2_ADS),

    (MUL_INSTR, t2_ADS,  A_ADS, t2_ADS),
    (ADD_INSTR, t4_ADS, t4_ADS, t2_ADS),
    (MUL_INSTR, t0_ADS, t1_ADS, t4_ADS),

    (ADD_INSTR, Y3_ADS, Y3_ADS, t0_ADS),
    (MUL_INSTR, t0_ADS, t5_ADS, t4_ADS),
    (MUL_INSTR, X3_ADS, t3_ADS, X3_ADS),

    (SUB_INSTR, X3_ADS, X3_ADS, t0_ADS),
    (MUL_INSTR, t0_ADS, t3_ADS, t1_ADS),
    (MUL_INSTR, Z3_ADS, t5_ADS, Z3_ADS),

    (ADD_INSTR, Z3_ADS, Z3_ADS, t0_ADS),
    
    -- Point doubling
    (MUL_INSTR, t0_ADS, X1_ADS, X1_ADS),
    (MUL_INSTR, t1_ADS, Y1_ADS, Y1_ADS),
    (MUL_INSTR, t2_ADS, Z1_ADS, Z1_ADS),

    (MUL_INSTR, t3_ADS, X1_ADS, Y1_ADS),
    (ADD_INSTR, t3_ADS, t3_ADS, t3_ADS),
    (MUL_INSTR, Z3_ADS, X1_ADS, Z1_ADS),

    (ADD_INSTR, Z3_ADS, Z3_ADS, Z3_ADS),
    (MUL_INSTR, X3_ADS,  A_ADS, Z3_ADS),
    (MUL_INSTR, Y3_ADS,  B_ADS, t2_ADS),

    (ADD_INSTR, Y3_ADS, X3_ADS, Y3_ADS),
    (SUB_INSTR, X3_ADS, t1_ADS, Y3_ADS),
    (ADD_INSTR, Y3_ADS, t1_ADS, Y3_ADS),

    (MUL_INSTR, Y3_ADS, X3_ADS, Y3_ADS),
    (MUL_INSTR, X3_ADS, t3_ADS, X3_ADS),
    (MUL_INSTR, Z3_ADS,  B_ADS, Z3_ADS),

    (MUL_INSTR, t2_ADS,  A_ADS, t2_ADS),
    (SUB_INSTR, t3_ADS, t0_ADS, t2_ADS),
    (MUL_INSTR, t3_ADS,  A_ADS, t3_ADS),

    (ADD_INSTR, t3_ADS, t3_ADS, Z3_ADS),
    (ADD_INSTR, Z3_ADS, t0_ADS, t0_ADS),
    (ADD_INSTR, t0_ADS, Z3_ADS, t0_ADS),

    (ADD_INSTR, t0_ADS, t0_ADS, t2_ADS),
    (MUL_INSTR, t0_ADS, t0_ADS, t3_ADS),
    (ADD_INSTR, Y3_ADS, Y3_ADS, t0_ADS),

    (MUL_INSTR, t2_ADS, Y1_ADS, Z1_ADS),
    (ADD_INSTR, t2_ADS, t2_ADS, t2_ADS),
    (MUL_INSTR, t0_ADS, t2_ADS, t3_ADS),

    (SUB_INSTR, X3_ADS, X3_ADS, t0_ADS),
    (MUL_INSTR, Z3_ADS, t2_ADS, t1_ADS),
    (ADD_INSTR, Z3_ADS, Z3_ADS, Z3_ADS),

    (ADD_INSTR, Z3_ADS, Z3_ADS, Z3_ADS)
);

-- declare components
component ecc_base is
    generic(
        n: integer := 8;
        log2n: integer := 3;
        ads: integer := 8);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        oper_a: in std_logic_vector(ads-1 downto 0);
        oper_b: in std_logic_vector(ads-1 downto 0);
        oper_o: in std_logic_vector(ads-1 downto 0);
        command: in std_logic_vector(2 downto 0);
        busy: out std_logic;
        done: out std_logic;
        m_enable: in std_logic;
        m_din:in std_logic_vector(n-1 downto 0);
        m_dout:out std_logic_vector(n-1 downto 0);
        m_rw:in std_logic;
        m_address:in std_logic_vector(ads-1 downto 0));
end component;

-- Declare signals and types
type my_state is
    ( s_idle
    , s_load_p
    , s_execute
    , s_write_results
    );
signal state: my_state := s_idle;

signal exec_triggered_i: std_logic := '0';

signal m_instr_end_i: unsigned(INSTR_ADS-1 downto 0);
signal m_instr_offset_i: unsigned(INSTR_ADS-1 downto 0);
signal m_instr_data_i: std_logic_vector(INSTR_WIDTH-1 downto 0);

-- declare and initialize internal signals to drive the inputs of ecc_base
signal base_start_i: std_logic := '0';
signal base_oper_a_i: std_logic_vector(RAM_ADS-1 downto 0) := (others => '0');
signal base_oper_b_i: std_logic_vector(RAM_ADS-1 downto 0) := (others => '0');
signal base_oper_o_i: std_logic_vector(RAM_ADS-1 downto 0) := (others => '0');
signal base_command_i: std_logic_vector(2 downto 0) := "010";
signal base_busy_i: std_logic;
signal base_done_i: std_logic;
signal base_m_enable_i: std_logic := '0';
signal base_m_din_i: std_logic_vector(n-1 downto 0);
signal base_m_dout_i: std_logic_vector(n-1 downto 0);
signal base_m_rw_i: std_logic := '0';
signal base_m_address_i: std_logic_vector(RAM_ADS-1 downto 0);

begin

inst_ecc_base: ecc_base
    generic map(
        n => n,
        log2n => log2n,
        ads => RAM_ADS
    )
    port map(
        start=>base_start_i,
        rst=>rst,
        clk=>clk,
        oper_a=>base_oper_a_i,
        oper_b=>base_oper_b_i,
        oper_o=>base_oper_o_i,
        command=>base_command_i,
        busy=>base_busy_i,
        done=>base_done_i,
        m_enable=>base_m_enable_i,
        m_din=>base_m_din_i,
        m_dout=>base_m_dout_i,
        m_rw=>base_m_rw_i,
        m_address=>base_m_address_i
    );

FSM_state: process(rst, clk) is
begin
    if rst = '1' then
        base_command_i <= "110";
        base_oper_o_i <= (others => '0');
        base_oper_a_i <= (others => '0');
        base_oper_b_i <= (others => '0');
        base_start_i <= '0';
        m_instr_offset_i <= to_unsigned(0, m_instr_offset_i'length);
        m_instr_end_i <= to_unsigned(0, m_instr_end_i'length);
        m_instr_data_i <= instructions(0);
        state <= s_idle;
    elsif rising_edge(clk) then
        case state is
            when s_idle =>
                base_command_i <= "110";
                base_oper_o_i <= (others => '0');
                base_oper_a_i <= (others => '0');
                base_oper_b_i <= (others => '0');
                base_start_i <= '0';
                m_instr_data_i <= instructions(0);
                if start = '1' then
                    if add_double = '1' then
                        m_instr_offset_i <= to_unsigned(DBL_INSTR_START, m_instr_end_i'length);
                        m_instr_end_i <= to_unsigned(DBL_INSTR_END, m_instr_end_i'length);
                    else
                        m_instr_offset_i <= to_unsigned(ADD_INSTR_START, m_instr_end_i'length);
                        m_instr_end_i <= to_unsigned(ADD_INSTR_END, m_instr_end_i'length);
                    end if;
                    state <= s_load_p;
                end if;
            when s_load_p =>
                base_command_i <= "110";
                base_oper_o_i <= (others => '0');
                base_oper_a_i <= (others => '0');
                base_oper_b_i <= P_ADS;
                base_start_i <= '0';
                m_instr_data_i <= instructions(to_integer(m_instr_offset_i));
                if exec_triggered_i = '0' then
                    exec_triggered_i <= '1';
                    base_start_i <= '1';
                elsif base_done_i = '0' then
                    base_start_i <= '0';
                    exec_triggered_i <= '1';
                else
                    base_start_i <= '0';
                    exec_triggered_i <= '0';
                    state <= s_execute;
                end if;
            when s_execute =>
                if exec_triggered_i = '0' then
                    exec_triggered_i <= '1';
                    base_start_i <= '1';
                elsif base_done_i = '0' then
                    base_start_i <= '0';
                    exec_triggered_i <= '1';
                else
                    base_start_i <= '0';
                    exec_triggered_i <= '0';
                    if m_instr_offset_i = m_instr_end_i then
                        state <= s_write_results;
                    else
                        m_instr_data_i <= instructions(to_integer(m_instr_offset_i + 1));
                        m_instr_offset_i <= m_instr_offset_i + 1;
                    end if;
                end if;

                base_command_i <= '0' & m_instr_data_i(16 downto 15);
                base_oper_o_i <= m_instr_data_i(14 downto 10);
                base_oper_a_i <= m_instr_data_i(9 downto 5);
                base_oper_b_i <= m_instr_data_i(4 downto 0);
            when s_write_results =>
                m_instr_data_i <= instructions(0);
                m_instr_offset_i <= to_unsigned(0, m_instr_offset_i'length);
                base_command_i <= "110";
                base_oper_o_i <= (others => '0');
                base_oper_a_i <= (others => '0');
                base_oper_b_i <= (others => '0');
                base_start_i <= '0';
                state <= s_idle;
        end case;
    end if;
end process;

FSM_out: process(state, m_enable, m_din, m_rw, m_address)
begin
    case state is
        when s_idle =>
            report "In state s_idle";
            done <= '0';
            busy <= '0';
            base_m_din_i <= m_din;
            base_m_rw_i <= m_rw;
            base_m_address_i <= m_address;
            base_m_enable_i <= m_enable;
        when s_load_p => 
            report "In state s_load_p";
            done <= '0';
            busy <= '1';
            base_m_din_i <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            base_m_enable_i <= '1';
        when s_execute =>
            report "In state s_execute";
            done <= '0';
            busy <= '1';
            base_m_din_i <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            base_m_enable_i <= '0';
        when s_write_results =>
            report "In state s_write_results";
            done <= '1';
            busy <= '1';
            base_m_din_i <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            base_m_enable_i <= '0';
    end case;
end process;
    
end behavioral;
