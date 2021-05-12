----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: ram_double
-- Description: RAM memory with variable word size and depth.
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module
entity ram_double is
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
end ram_double;
    
-- describe the behavior of the module in the architecture
architecture behavioral of ram_double is