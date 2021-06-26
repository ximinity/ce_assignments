----------------------------------------------------------------------------------
-- June 6, 2021 
-- 
-- Author: Stefan Schrijvers & Rowan Goemans
--  
-- Module Name: tb_ecc_mult 
-- Description: testbench for the ecc_mult module
----------------------------------------------------------------------------------

-- include the IEEE library and the STD_LOGIC_1164 package for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module: a testbench does not have any inputs or outputs
entity tb_ecc_mult_double is
    generic(
        n: integer := 8;
        log2n: integer := 3);
end tb_ecc_mult_double;

architecture behavioral of tb_ecc_mult_double is

-- declare and initialize internal signals to drive the inputs of ecc_mult
constant ecc_prime: std_logic_vector(n-1 downto 0) := X"7F";
constant ecc_a: std_logic_vector(n-1 downto 0) := X"7C";
constant ecc_b: std_logic_vector(n-1 downto 0) := X"05";

constant ecc_s: std_logic_vector(n-1 downto 0) := X"AA";

constant ecc_g_x: std_logic_vector(n-1 downto 0) := X"31";
constant ecc_g_y: std_logic_vector(n-1 downto 0) := X"0a";
constant ecc_g_z: std_logic_vector(n-1 downto 0) := X"0f";

constant ecc_sg_x: std_logic_vector(n-1 downto 0) := X"3E";
constant ecc_sg_y: std_logic_vector(n-1 downto 0) := X"46";
constant ecc_sg_z: std_logic_vector(n-1 downto 0) := X"1E";

signal start_i: std_logic := '0';
signal rst_i: std_logic := '1';
signal clk_i: std_logic := '0';
signal busy_i: std_logic;
signal done_i: std_logic;

signal sgx_i: std_logic_vector(n-1 downto 0);
signal sgy_i: std_logic_vector(n-1 downto 0);
signal sgz_i: std_logic_vector(n-1 downto 0);

-- declare a signal to check if values match.
signal error_comp: std_logic := '0';

-- define the clock period
constant clk_period: time := 10 ns;

-- define signal to terminate simulation
signal testbench_finish: boolean := false;

-- declare the ecc_base component
component ecc_mult_double
    generic(n: integer := 8;
            log2n: integer := 3);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        prime: in std_logic_vector(n-1 downto 0);
        a: in std_logic_vector(n-1 downto 0);
        b: in std_logic_vector(n-1 downto 0);
        scalar: in std_logic_vector(n-1 downto 0);
        gx: in std_logic_vector(n-1 downto 0);
        gy: in std_logic_vector(n-1 downto 0);
        gz: in std_logic_vector(n-1 downto 0);
        sgx: out std_logic_vector(n-1 downto 0);
        sgy: out std_logic_vector(n-1 downto 0);
        sgz: out std_logic_vector(n-1 downto 0);
        done: out std_logic;
        busy: out std_logic);
end component;

begin

-- instantiate the ecc_base component
-- map the generic parameter in the testbench to the generic parameter in the component  
-- map the signals in the testbench to the ports of the component
inst_ecc_mult: ecc_mult_double
    generic map(n=>n,
            log2n=>log2n)
    port map(
        start=>start_i,
        rst=>rst_i,
        clk=>clk_i,
        prime=>ecc_prime,
        a=>ecc_a,
        b=>ecc_b,
        scalar=>ecc_s,
        gx=>ecc_g_x,
        gy=>ecc_g_y,
        gz=>ecc_g_z,
        sgx=>sgx_i,
        sgy=>sgy_i,
        sgz=>sgz_i,
        done=>done_i,
        busy=>busy_i
    );

-- generate the clock with a duty cycle of 50%
gen_clk: process
begin
     while(testbench_finish = false) loop
        clk_i <= '0';
        wait for clk_period/2;
        clk_i <= '1';
        wait for clk_period/2;
     end loop;
     wait;
end process;

-- stimulus process (without sensitivity list, but with wait statements)
stim: process
variable i: integer;
begin
    wait for clk_period;
    
    rst_i <= '0';
    
    report "waiting till busy = 0";
    if busy_i = '1' then
        wait until busy_i = '0';
    end if;
    report "done waiting till busy = 0";
    wait for clk_period;

    -- Perform scalar multiplication
    start_i <= '1';
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    -- Retrieve value
    wait for clk_period;
    error_comp <= '0';
    wait for clk_period;
    report "Expected: " & to_string(ecc_sg_x) & ", got: " & to_string(sgx_i); 
    if(ecc_sg_x /= sgx_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    wait for clk_period;
    report "error: " & to_string(error_comp);
    error_comp <= '0';
    wait for clk_period;
    report "Expected: " & to_string(ecc_sg_y) & ", got: " & to_string(sgy_i); 
    if(ecc_sg_y /= sgy_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    wait for clk_period;
    report "error: " & to_string(error_comp);
    error_comp <= '0';
    wait for clk_period;
    report "Expected: " & to_string(ecc_sg_z) & ", got: " & to_string(sgz_i); 
    if(ecc_sg_z /= sgz_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    wait for clk_period;
    report "error: " & to_string(error_comp);
    error_comp <= '0';
    wait for clk_period;
    testbench_finish <= true;
    wait;
end process;

end behavioral;
