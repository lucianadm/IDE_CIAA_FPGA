library ieee;
use ieee.std_logic_1164.all;

entity secuencia_leds_vhdl is
    generic (CICLOS_POR_PASO : positive := 3_000_000);
    port (
        clk12 : in  std_logic;
        LED0  : out std_logic;
        LED1  : out std_logic;
        LED2  : out std_logic;
        LED3  : out std_logic
    );
end entity;

architecture rtl of secuencia_leds_vhdl is
    signal contador : natural range 0 to CICLOS_POR_PASO - 1 := 0;
    signal paso     : natural range 0 to 5 := 0;
    signal patron   : std_logic_vector(3 downto 0);
begin
    process (clk12)
    begin
        if rising_edge(clk12) then
            if contador = CICLOS_POR_PASO - 1 then
                contador <= 0;
                if paso = 5 then paso <= 0; else paso <= paso + 1; end if;
            else
                contador <= contador + 1;
            end if;
        end if;
    end process;

    with paso select patron <=
        "0001" when 0, "0010" when 1, "0100" when 2,
        "1000" when 3, "0100" when 4, "0010" when others;
    LED0 <= patron(0); LED1 <= patron(1); LED2 <= patron(2); LED3 <= patron(3);
end architecture;
