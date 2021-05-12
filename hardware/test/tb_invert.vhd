library ieee;
use ieee.std_logic_1164.all;

entity tb_invert is
end tb_invert;

architecture arch of tb_invert is
  signal a, b: std_logic;
  component invert is
    port(
      a: in std_logic;
      b: out std_logic
    );
  end component;

begin
  inst_invert: invert
    port map(a=>a, b=>b);

p: process
begin
  a <= '0';
  wait for 10 ns;
  a <= '1';
  wait for 10 ns;
  wait;
end process;

end arch;
