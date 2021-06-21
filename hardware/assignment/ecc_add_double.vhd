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

library work;
use work.ecc_constants.all;

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
        op_o: in std_logic_vector(1 downto 0);
        op_a: in std_logic_vector(1 downto 0);
        op_b: in std_logic_vector(1 downto 0);
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
constant C3_ADS: std_logic_vector(4 downto 0) := "10010";

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

function TRANSLATE_ADDR(addr: std_logic_vector(4 downto 0);
                        new_o: std_logic_vector(1 downto 0);
                        new_a: std_logic_vector(1 downto 0);
                        new_b: std_logic_vector(1 downto 0))
  return std_logic_vector is
begin
    case addr is
        when X1_ADS => case new_a is
                            when "01" => return X2_ADS;
                            when "10" => return X3_ADS;
                            when others => return addr;
                        end case;
        when Y1_ADS => case new_a is
                            when "01" => return Y2_ADS;
                            when "10" => return Y3_ADS;
                            when others => return addr;
                        end case;
        when Z1_ADS => case new_a is
                            when "01" => return Z2_ADS;
                            when "10" => return Z3_ADS;
                            when others => return addr;
                        end case;
        when X2_ADS => case new_b is
                            when "00" => return X1_ADS;
                            when "10" => return X3_ADS;
                            when others => return addr;
                        end case;
        when Y2_ADS => case new_b is
                            when "00" => return Y1_ADS;
                            when "10" => return Y3_ADS;
                            when others => return addr;
                        end case;
        when Z2_ADS => case new_b is
                            when "00" => return Z1_ADS;
                            when "10" => return Z3_ADS;
                            when others => return addr;
                        end case;
        when X3_ADS => case new_o is
                            when "00" => return X1_ADS;
                            when "01" => return X2_ADS;
                            when others => return addr;
                        end case;
        when Y3_ADS => case new_o is
                            when "00" => return Y1_ADS;
                            when "01" => return Y2_ADS;
                            when others => return addr;
                        end case;
        when Z3_ADS => case new_o is
                            when "00" => return Z1_ADS;
                            when "01" => return Z2_ADS;
                            when others => return addr;
                        end case;
        when others => return addr;
    end case;
end TRANSLATE_ADDR;

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
    ( s_load_constant
    , s_idle
    , s_load_p
    , s_triple_b
    , s_execute
    , s_write_results
    );
signal state: my_state := s_idle;

signal exec_triggered_i: std_logic := '0';

signal m_instr_end_i: unsigned(INSTR_ADS-1 downto 0);
signal m_instr_offset_i: unsigned(INSTR_ADS-1 downto 0);
signal m_instr_data_i: std_logic_vector(INSTR_WIDTH-1 downto 0);

signal b_tripled: std_logic := '0';

signal op_a_i: std_logic_vector(1 downto 0);
signal op_b_i: std_logic_vector(1 downto 0);
signal op_o_i: std_logic_vector(1 downto 0);

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
        op_a_i <= (others => '0');
        op_b_i <= (others => '0');
        op_o_i <= (others => '0');
        base_oper_o_i <= (others => '0');
        base_oper_a_i <= (others => '0');
        base_oper_b_i <= (others => '0');
        base_start_i <= '0';
        m_instr_offset_i <= to_unsigned(0, m_instr_offset_i'length);
        m_instr_end_i <= to_unsigned(0, m_instr_end_i'length);
        m_instr_data_i <= instructions(0);
        state <= s_load_constant;
        b_tripled <= '0';
    elsif rising_edge(clk) then
        case state is
            when s_load_constant =>
                base_command_i <= "110";
                base_oper_o_i <= (others => '0');
                base_oper_a_i <= (others => '0');
                base_oper_b_i <= (others => '0');
                base_start_i <= '0';
                m_instr_data_i <= instructions(0);
                state <= s_idle;
            when s_idle =>
                base_command_i <= "110";
                base_oper_o_i <= (others => '0');
                base_oper_a_i <= (others => '0');
                base_oper_b_i <= (others => '0');
                base_start_i <= '0';
                m_instr_data_i <= instructions(0);
                if m_enable = '1' and m_rw = '1' and m_address = B_ADS then
                    b_tripled <= '0';
                end if;
                if start = '1' then
                    op_a_i <= op_a;
                    op_b_i <= op_b;
                    op_o_i <= op_o;
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
                    if b_tripled = '0' then
                        state <= s_triple_b;
                    else
                        state <= s_execute;
                    end if;
                end if;
            when s_triple_b =>
                base_command_i <= '0' & MUL_INSTR;
                base_oper_o_i <= B_ADS;
                base_oper_a_i <= C3_ADS;
                base_oper_b_i <= B_ADS;
                b_tripled <= '1';
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
                base_oper_o_i <= TRANSLATE_ADDR(m_instr_data_i(14 downto 10), op_o_i, op_a_i, op_b_i);
                base_oper_a_i <= TRANSLATE_ADDR(m_instr_data_i(9 downto 5), op_o_i, op_a_i, op_b_i);
                base_oper_b_i <= TRANSLATE_ADDR(m_instr_data_i(4 downto 0), op_o_i, op_a_i, op_b_i);
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

FSM_out: process(state, base_m_dout_i, m_enable, m_din, m_rw, m_address)
begin
    case state is
        when s_load_constant =>
            done <= '0';
            busy <= '1';
            base_m_din_i <= std_logic_vector(to_unsigned(3, base_m_din_i'length));
            m_dout <= (others => '0');
            base_m_rw_i <= '1';
            base_m_address_i <= C3_ADS;
            base_m_enable_i <= '1';
        when s_idle =>
            done <= '0';
            busy <= '0';
            base_m_din_i <= m_din;
            m_dout <= base_m_dout_i;
            base_m_rw_i <= m_rw;
            base_m_address_i <= m_address;
            base_m_enable_i <= m_enable;
        when s_load_p => 
            done <= '0';
            busy <= '1';
            base_m_din_i <= (others => '0');
            m_dout <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            base_m_enable_i <= '1';
        when s_triple_b =>
            done <= '0';
            busy <= '1';
            base_m_din_i <= (others => '0');
            m_dout <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            base_m_enable_i <= '1';
        when s_execute =>
            done <= '0';
            busy <= '1';
            base_m_din_i <= (others => '0');
            m_dout <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            base_m_enable_i <= '0';
        when s_write_results =>
            done <= '1';
            busy <= '1';
            base_m_din_i <= (others => '0');
            m_dout <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            base_m_enable_i <= '0';
    end case;
end process;
    
end behavioral;
