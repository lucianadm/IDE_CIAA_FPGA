library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity secuencia_leds_vhdl_tb is end entity;

architecture prueba of secuencia_leds_vhdl_tb is
    constant PERIODO : time := 20 ns;
    signal clk12 : std_logic := '0';
    signal leds  : std_logic_vector(3 downto 0);
begin
    clk12 <= not clk12 after PERIODO / 2;
    dut : entity work.secuencia_leds_vhdl
        generic map (CICLOS_POR_PASO => 3)
        port map (clk12 => clk12, LED0 => leds(0), LED1 => leds(1), LED2 => leds(2), LED3 => leds(3));

    process
        procedure comprobar(constant esperado : std_logic_vector(3 downto 0)) is
        begin
            assert leds = esperado report "Patron LED incorrecto" severity error;
            wait for 3 * PERIODO;
        end procedure;
    begin
        wait for 1 ns;
        comprobar("0001"); comprobar("0010"); comprobar("0100");
        comprobar("1000"); comprobar("0100"); comprobar("0010"); comprobar("0001");
        report "Secuencia VHDL comprobada" severity note;
        stop;
        wait;
    end process;
end architecture;
