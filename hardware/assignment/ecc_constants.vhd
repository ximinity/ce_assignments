library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package ecc_constants is

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
   
end package ecc_constants;
