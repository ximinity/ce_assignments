----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: ecc_add_double
-- Description: .
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

entity ecc_base is
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
end ecc_base;

-- describe the behavior of the module in the architecture
architecture behavioral of ecc_base is
-- declare the ram_double component
component ram_double is
    generic(
        ws: integer := 8;
        ads: integer := 8);
    port(
        enable: in std_logic;
        clk: in std_logic;
        din_a: in std_logic_vector((ws - 1) downto 0);
        address_a: in std_logic_vector((ads - 1) downto 0);
        address_b: in std_logic_vector((ads - 1) downto 0);
        rw: in std_logic;
        dout_a: out std_logic_vector((ws - 1) downto 0);
        dout_b: out std_logic_vector((ws - 1) downto 0));
end component;

-- declare the modmultn component
component modarithn is
    generic(
        n: integer := 8;
        log2n: integer := 3);
    port(
        a: in std_logic_vector(n-1 downto 0);
        b: in std_logic_vector(n-1 downto 0);
        p: in std_logic_vector(n-1 downto 0);
        rst: in std_logic;
        clk: in std_logic;
        start: in std_logic;
        command: in std_logic_vector(1 downto 0);
        product: out std_logic_vector(n-1 downto 0);
        done: out std_logic);
end component;

type my_state is
    ( s_idle
    , s_wait_ram
    , s_load_p
    , s_load_arith
    , s_comp_arith
    , s_write_arith
    );


signal state: my_state := s_idle;
-- declare and initialize internal signals to drive the inputs of ram_double
signal m_enable_i: std_logic := '0';
signal m_din_i: std_logic_vector((n - 1) downto 0) := (others => '0');
signal m_dout_i: std_logic_vector((n - 1) downto 0);
signal m_rw_i: std_logic := '0';

-- Declare signals
signal ads_a: std_logic_vector((ads - 1) downto 0) := (others => '0');
signal a, b, p, product: std_logic_vector((n - 1) downto 0) := (others => '0');
signal reg_oper_o, reg_oper_a, reg_oper_b: std_logic_vector((ads - 1) downto 0) := (others => '0');
signal reg_comm: std_logic_vector(2 downto 0) := (others => '0');
signal rw, rw_i, a_done, a_start, enable, p_enable, free: std_logic := '0';

begin

inst_ram_double: ram_double
    generic map(
        ws => n,
        ads => ads
    )
    port map(
        enable => m_enable_i,
        clk => clk,
        din_a => m_din_i,
        address_a => ads_a,
        address_b => reg_oper_b,
        rw => rw_i,
        dout_a => a,
        dout_b => b
    );

-- declare the modaddsubn component
inst_modarithn: modarithn
    generic map(
        n => n,
        log2n => log2n
    )
    port map(
        rst => rst,
        clk => clk,
        start => a_start,
        a => a,
        b => b,
        p => p,
        command => command(1 downto 0),
        product => product,
        done => a_done
    );

-- Capture inputs on start into registers
reg_proc: process(rst, clk)
begin
    if rst = '1' then
        reg_oper_o <= (others => '0');
        reg_oper_a <= (others => '0');
        reg_oper_b <= (others => '0');
        reg_comm <= (others => '0');
    elsif rising_edge(clk) then
        if start = '1' then
            reg_oper_o <= oper_o;
            reg_oper_a <= oper_a;
            reg_oper_b <= oper_b;
            reg_comm <= command;
        end if;
    end if;
end process;

-- Wire up memory module signals
m_dout <= a;
mem_proc: process(free, rw, m_enable, m_rw, m_din, m_address, enable, product, reg_oper_o, reg_oper_a)
begin
    if free = '1' then
        m_enable_i <= m_enable;
        rw_i <= m_rw;
        m_din_i <= m_din;
        ads_a <= m_address;
    elsif free = '0' then
        m_enable_i <= enable;
        rw_i <= rw;
        m_din_i <= product;
        if rw = '1' then
            ads_a <= reg_oper_o;
        elsif rw = '0' then
            ads_a <= reg_oper_a;
        end if;
    end if;
end process;

-- handle p register assignment
p_proc: process(rst, clk) is
begin
    if rst = '1' then
        p <= (others => '0');
    elsif rising_edge(clk) then
        if p_enable = '1' then
            p <= b;
        else
            p <= p;
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
                if start = '1' then
                    state <= s_wait_ram;
                end if;
            when s_wait_ram =>
                if reg_comm(2) = '0' then
                    state <= s_load_arith;
                else
                    state <= s_load_p;
                end if;
            when s_load_p =>
                state <= s_idle;
            when s_load_arith =>
                state <= s_comp_arith;
            when s_comp_arith =>
                if a_done = '1' then
                    state <= s_write_arith;
                else
                end if;
            when s_write_arith =>
                state <= s_idle;
        end case;
    end if;
end process;

-- Global assignements
busy <= not(free);
FSM_out: process(state)
begin
    case state is
        when s_idle =>
            free <= '1';
            done <= '0';
            rw <= '0';
            enable <= '0';
            a_start <= '0';
            p_enable <= '0';
        when s_wait_ram =>
            free <= '0';
            done <= '0';
            rw <= '0';
            enable <= '1';
            a_start <= '0';
            p_enable <= '0';
        when s_load_p =>
            free <= '0';
            done <= '1';
            rw <= '0';
            enable <= '1';
            a_start <= '0';
            p_enable <= '1';
        when s_load_arith =>
            free <= '0';
            done <= '0';
            rw <= '0';
            enable <= '1';
            a_start <= '1';
            p_enable <= '0';
        when s_comp_arith =>
            free <= '0';
            done <= '0';
            rw <= '0';
            enable <= '0';
            a_start <= '0';
            p_enable <= '0';
        when s_write_arith =>    
            free <= '0';
            done <= '1';
            rw <= '1';
            enable <= '1';
            a_start <= '0';
            p_enable <= '0';
    end case;
end process;
    
end behavioral;
