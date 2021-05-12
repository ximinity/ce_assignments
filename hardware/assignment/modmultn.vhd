----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Nele Mentens
-- Updated by Pedro Maat Costa Massolino
--  
-- Module Name: modmultn
-- Description: n-bit modular multiplier (through the left-to-right double-and-add algorithm)
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module
-- product = b*a mod p
entity modmultn is
    generic(
        n: integer := 8;
        log2n: integer := 3);
    port(
        a, b, p: in std_logic_vector(n-1 downto 0);
        rst, clk, start: in std_logic;
        product: out std_logic_vector(n-1 downto 0);
        done: out std_logic);
end modmultn;

-- describe the behavior of the module in the architecture
architecture behavioral of modmultn is

-- declare internal signals
signal c, a_reg, double_a_reg, b_reg, p_reg, product_reg, sum_reg: std_logic_vector(n-1 downto 0);
signal ctr: unsigned(log2n-1 downto 0);
signal flush_ctr: unsigned(1 downto 0);
type my_state is (s_idle, s_shift, s_flush, s_done);
signal enable: std_logic;
signal state: my_state;

-- declare the modaddsubn component
component modaddsubn
    generic(
        n: integer := 8);
    port(
        a, b, p: in std_logic_vector(n-1 downto 0);
        as: in std_logic;
        sum: out std_logic_vector(n-1 downto 0));
end component;

begin

-- instantiate the modaddsubn component
-- map the generic parameter in the top design to the generic parameter in the component  
-- map the signals in the top design to the ports of the component
inst_modaddsubn_1: modaddsubn
generic map(n => n)
port map(   a => product_reg,
            b => sum_reg,
            p => p_reg,
            as => '0',
            sum => c);

inst_modaddsubn_2: modaddsubn
generic map(n => n)
port map(   a => a_reg,
            b => a_reg,
            p => p_reg,
            as => '0',
            sum => double_a_reg);
            

-- store the intermediate sum in the register 'product_reg'
-- the register has an asynchronous reset: 'rst'
-- If the current least significant bit of the second operand
-- is '1' we shift add the shifted first operand to the product_reg.
reg_product: process(rst, clk)
begin
    if rst = '1' then
        product_reg <= (others => '0');
        sum_reg <= (others => '0');
    elsif rising_edge(clk) then
        if start = '1' then
            product_reg <= (others => '0');
            sum_reg <= (others => '0');
        elsif enable = '1' then
            if b_reg(0) = '1' then
                sum_reg <= a_reg;
            else
                sum_reg <= (others => '0');
            end if;
            product_reg <= c;
        end if;
    end if;
end process;

-- store the inputs 'a', 'b' and 'p' in the registers 'a_reg', 'b_reg' and 'p_reg', respectively, if start = '1'
-- the registers have an asynchronous reset
-- shift the content of 'b_reg' one position to the right if enable = '1'
-- Also shift the content of 'a_reg' one position to the left if enable = '1'
reg_a_b_p: process(rst, clk)
begin
    if rst = '1' then
        a_reg <= (others => '0');
        b_reg <= (others => '0');
        p_reg <= (others => '0');
    elsif rising_edge(clk) then
        if start = '1' then
            a_reg <= a;
            b_reg <= b;
            p_reg <= p;
        elsif enable = '1' then
            a_reg <= double_a_reg;
            b_reg <= '0' & b_reg(n-1 downto 1);
            p_reg <= p_reg;
        end if;
    end if;
end process;

-- update and store the state of the FSM
-- stop the calculation when we have shifted through all bits
-- essentially when ctr is as large as n-1.
-- However once we are done shifting we still
-- have to wait for the pipeline to be flushed.
-- This takes 2 cycles due to the cascaded modaddsubn
-- modules.
FSM_state: process(rst, clk) is
begin
    if rst = '1' then
        state <= s_idle;
        ctr <= to_unsigned(0, ctr'length);
        flush_ctr <= to_unsigned(0, flush_ctr'length);
    elsif rising_edge(clk) then
        case state is
            when s_idle =>
                ctr <= to_unsigned(0, ctr'length);
                flush_ctr <= to_unsigned(0, flush_ctr'length);
                if start = '1' and ctr /= (n-1) then
                    state <= s_shift;
                end if;
            when s_shift =>
                ctr <= ctr + 1;
                if ctr = (n-1) then
                    state <= s_flush;
                end if;
            when s_flush =>
                flush_ctr <= flush_ctr + 1;
                if flush_ctr = 1 then
                    state <= s_done;
                end if;
            when others =>
                state <= s_idle;
        end case;
    end if;
end process;

FSM_out: process(state)
begin
    case state is
        when s_idle =>
            enable <= '0';
            done <= '0';
        when s_shift =>
            enable <= '1';
            done <= '0';
        when s_flush =>
            enable <= '1';
            done <= '0';
        when others =>
            enable <= '0';
            done <= '1';
            end case;
end process;

product <= product_reg;

end behavioral;
