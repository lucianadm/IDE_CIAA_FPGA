library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity botones_leds_vhdl_tb is end entity;

architecture prueba of botones_leds_vhdl_tb is
    constant PERIODO : time := 20 ns;
    constant CICLOS  : positive := 8;
    signal clk12 : std_logic := '0';
    signal btn   : std_logic_vector(3 downto 0) := (others => '1');
    signal leds  : std_logic_vector(3 downto 0);
begin
    clk12 <= not clk12 after PERIODO / 2;

    dut : entity work.botones_leds_vhdl
        generic map (CICLOS_POR_PASO => CICLOS)
        port map (
            clk12 => clk12,
            BTN1 => btn(0), BTN2 => btn(1), BTN3 => btn(2), BTN4 => btn(3),
            LED0 => leds(0), LED1 => leds(1), LED2 => leds(2), LED3 => leds(3)
        );

    process
        procedure esperar_relojes(constant cantidad : positive) is
        begin
            for i in 1 to cantidad loop wait until rising_edge(clk12); end loop;
            wait for 1 ns;
        end procedure;
        procedure comprobar(constant esperado : std_logic_vector(3 downto 0)) is
        begin
            assert leds = esperado
                report "Patron incorrecto. Esperado " & to_hstring(esperado) & ", recibido " & to_hstring(leds)
                severity error;
            esperar_relojes(CICLOS);
        end procedure;
        procedure seleccionar(constant botones : std_logic_vector(3 downto 0)) is
        begin
            wait until falling_edge(clk12);
            btn <= botones;
            esperar_relojes(4);
        end procedure;
    begin
        esperar_relojes(2);

        seleccionar("1110");
        comprobar("0001"); comprobar("0010"); comprobar("0100"); comprobar("1000");

        seleccionar("1101");
        comprobar("1000"); comprobar("0100"); comprobar("0010"); comprobar("0001");

        seleccionar("1011");
        comprobar("0000"); comprobar("0001"); comprobar("0010"); comprobar("0011");

        seleccionar("0111");
        comprobar("0101"); comprobar("1010"); comprobar("0101"); comprobar("1010");

        seleccionar("1111");
        comprobar("0001"); comprobar("0010"); comprobar("0100"); comprobar("1000");

        report "Todos los modos VHDL fueron comprobados" severity note;
        stop;
        wait;
    end process;
end architecture;
