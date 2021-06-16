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

constant ADD_INSTR_START: integer := 0;
constant ADD_INSTR_END: integer := 40;
constant DBL_INSTR_START: integer := 41;
constant DBL_INSTR_END: integer := 72;
constant INSTR_WIDTH: Integer := 18; -- 3 bits operator, 5 bits per operand.
constant INSTR_ADS: Integer := integer(ceil(log2(real(DBL_INSTR_END))));

constant LDP_INSTR: std_logic_vector(2 downto 0) := "110";
constant ADD_INSTR: std_logic_vector(2 downto 0) := "000";
constant SUB_INSTR: std_logic_vector(2 downto 0) := "001";
constant MUL_INSTR: std_logic_vector(2 downto 0) := "011";
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
    (LDP_INSTR, "00000", "00000", P_ADS),

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
    (LDP_INSTR, "00000", "00000", P_ADS),

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

-- declare the ram_single component for holding instructions
component ram_single is
    generic( 
        ws: integer := INSTR_WIDTH;
        ads: integer := INSTR_ADS);
    port(
        enable: in std_logic;
        clk: in std_logic;
        din: in std_logic_vector((ws - 1) downto 0);
        address: in std_logic_vector((ads - 1) downto 0);
        rw: in std_logic;
        dout: out std_logic_vector((ws - 1) downto 0));
end component;

-- Declare signals and types
type my_state is
    ( s_init
    , s_load
    , s_idle
    , s_execute
    , s_write_results
    );
signal state: my_state := s_init;

signal exec_triggered_i: std_logic := '0';

signal m_instr_end_i: unsigned(INSTR_ADS-1 downto 0);
signal m_instr_offset_i: unsigned(INSTR_ADS-1 downto 0);

-- declare and initialize internal signals to drive the inputs of ecc_base
signal base_start_i: std_logic := '0';
signal base_oper_a_i: std_logic_vector(4 downto 0) := (others => '0');
signal base_oper_b_i: std_logic_vector(4 downto 0) := (others => '0');
signal base_oper_o_i: std_logic_vector(4 downto 0) := (others => '0');
signal base_command_i: std_logic_vector(2 downto 0) := "010";
signal base_busy_i: std_logic;
signal base_done_i: std_logic;
signal base_m_enable_i: std_logic := '0';
signal base_m_din_i: std_logic_vector(n-1 downto 0);
signal base_m_dout_i: std_logic_vector(n-1 downto 0);
signal base_m_rw_i: std_logic := '0';
signal base_m_address_i: std_logic_vector(4 downto 0) := (others => '0');

-- Instruction ram signals.
signal instr_ram_din: std_logic_vector(INSTR_WIDTH - 1 downto 0) := (others => '0');
signal instr_ram_address: std_logic_vector(INSTR_ADS - 1 downto 0) := (others => '0');
signal instr_ram_rw: std_logic := '0';
signal instr_ram_dout: std_logic_vector(INSTR_WIDTH - 1 downto 0);
signal instr_ram_enable: std_logic := '0';

begin

inst_ecc_base: ecc_base
    generic map(
        n => n,
        log2n => log2n,
        ads => 5
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

inst_instr_ram: ram_single
    generic map(
        ws => INSTR_WIDTH,
        ads => INSTR_ADS
    )
    port map(
        enable=>instr_ram_enable,
        clk=>clk,
        din=>instr_ram_din,
        address=>instr_ram_address,
        rw=>instr_ram_rw,
        dout=>instr_ram_dout
    );

FSM_state: process(rst, clk) is
begin
    if rst = '1' then
        instr_ram_address <= (others => '0');
        base_command_i <= "110";
        base_oper_o_i <= (others => '0');
        base_oper_a_i <= (others => '0');
        base_oper_b_i <= (others => '0');
        base_start_i <= '0';
        m_instr_offset_i <= to_unsigned(0, m_instr_offset_i'length);
        m_instr_end_i <= to_unsigned(0, m_instr_end_i'length);
        state <= s_init;
    elsif rising_edge(clk) then
        case state is
            when s_init =>
                instr_ram_address <= (others => '0');
                base_command_i <= "110";
                base_oper_o_i <= (others => '0');
                base_oper_a_i <= (others => '0');
                base_oper_b_i <= (others => '0');
                base_start_i <= '0';
                m_instr_offset_i <= to_unsigned(0, m_instr_offset_i'length);
                m_instr_end_i <= to_unsigned(DBL_INSTR_END, m_instr_end_i'length);
                state <= s_load;
            when s_load =>
                instr_ram_address <= (others => '0');
                base_command_i <= "110";
                base_oper_o_i <= (others => '0');
                base_oper_a_i <= (others => '0');
                base_oper_b_i <= (others => '0');
                base_start_i <= '0';
                m_instr_offset_i <= m_instr_offset_i + 1;
                if m_instr_offset_i = m_instr_end_i then
                    state <= s_idle;
                end if;
                instr_ram_din <= instructions(to_integer(m_instr_offset_i));
            when s_idle =>
                base_command_i <= "110";
                base_oper_o_i <= (others => '0');
                base_oper_a_i <= (others => '0');
                base_oper_b_i <= (others => '0');
                base_start_i <= '0';
                if start = '1' then
                    if add_double = '1' then
                        m_instr_offset_i <= to_unsigned(DBL_INSTR_START, m_instr_end_i'length);
                        instr_ram_address <= std_logic_vector(to_unsigned(DBL_INSTR_START, instr_ram_address'length));
                        m_instr_end_i <= to_unsigned(DBL_INSTR_END, m_instr_end_i'length);
                    else
                        m_instr_offset_i <= to_unsigned(ADD_INSTR_START, m_instr_end_i'length);
                        instr_ram_address <= std_logic_vector(to_unsigned(ADD_INSTR_START, instr_ram_address'length));
                        m_instr_end_i <= to_unsigned(ADD_INSTR_END, m_instr_end_i'length);
                    end if;
                    state <= s_execute;
                end if;
            when s_execute =>
                if exec_triggered_i = '0' then
                    report "Triggering start for ALU";
                    exec_triggered_i <= '1';
                    base_start_i <= '1';
                elsif base_done_i = '0' then
                    report "Waiting till done.";
                    base_start_i <= '0';
                else
                    report "Finished ALU instruction";
                    base_start_i <= '0';
                    exec_triggered_i <= '0';
                    if m_instr_offset_i = m_instr_end_i then
                        report "Done IP is = end: " & to_string(m_instr_offset_i) & ", end: " & to_string(m_instr_end_i);
                        state <= s_write_results;
                    else
                        report "Incrementing IP: " & to_string(m_instr_offset_i);
                        instr_ram_address <= std_logic_vector(m_instr_offset_i + 1);
                        m_instr_offset_i <= m_instr_offset_i + 1;
                    end if;
                end if;

                report "instr_ram_addr: " & to_string(instr_ram_address);
                report "instr_ram_dout: " & to_string(instr_ram_dout);
                base_command_i <= instr_ram_dout(17 downto 15);
                report "base_command_i: " & to_string(base_command_i);
                base_oper_o_i <= instr_ram_dout(14 downto 10);
                report "base_oper_o_i: " & to_string(base_oper_o_i);
                base_oper_a_i <= instr_ram_dout(9 downto 5);
                report "base_oper_a_i: " & to_string(base_oper_a_i);
                base_oper_b_i <= instr_ram_dout(4 downto 0);
                report "base_oper_b_i: " & to_string(base_oper_b_i);
            when s_write_results =>
                instr_ram_address <= (others => '0');
                base_command_i <= "110";
                base_oper_o_i <= (others => '0');
                base_oper_a_i <= (others => '0');
                base_oper_b_i <= (others => '0');
                base_start_i <= '0';
                state <= s_idle;
        end case;
    end if;
end process;

FSM_out: process(state)
begin
    case state is
        when s_init =>
            report "In state s_init";
            instr_ram_rw <= '0';
            instr_ram_enable <= '0';
            base_m_enable_i <= '0';
            base_m_din_i <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            done <= '0';
            busy <= '1';
        when s_load =>
            report "In state s_load";
            instr_ram_rw <= '1';
            instr_ram_enable <= '1';
            base_m_enable_i <= '0';
            base_m_din_i <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            done <= '0';
            busy <= '1';
        when s_idle =>
            report "In state s_idle";
            instr_ram_rw <= '0';
            instr_ram_enable <= '1';
            base_m_enable_i <= '0';
            base_m_din_i <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            done <= '0';
            busy <= '0';
        when s_execute =>
            report "In state s_execute";
            instr_ram_rw <= '0';
            instr_ram_enable <= '1';
            base_m_enable_i <= '0';
            base_m_din_i <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            done <= '0';
            busy <= '1';
        when s_write_results =>
            report "In state s_write_results";
            instr_ram_rw <= '0';
            instr_ram_enable <= '0';
            base_m_enable_i <= '0';
            base_m_din_i <= (others => '0');
            base_m_rw_i <= '0';
            base_m_address_i <= (others => '0');
            done <= '1';
            busy <= '1';
    end case;
end process;
    
end behavioral;
