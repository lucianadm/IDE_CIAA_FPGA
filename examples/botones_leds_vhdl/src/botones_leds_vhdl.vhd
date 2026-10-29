library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity botones_leds_vhdl is
    generic (CICLOS_POR_PASO : positive := 3_000_000);
    port (
        clk12 : in  std_logic;
        BTN1  : in  std_logic;
        BTN2  : in  std_logic;
        BTN3  : in  std_logic;
        BTN4  : in  std_logic;
        LED0  : out std_logic;
        LED1  : out std_logic;
        LED2  : out std_logic;
        LED3  : out std_logic
    );
end entity;

architecture rtl of botones_leds_vhdl is
    signal botones_meta : std_logic_vector(3 downto 0) := (others => '1');
    signal botones_sync : std_logic_vector(3 downto 0) := (others => '1');
    signal modo         : natural range 0 to 4;
    signal modo_anterior: natural range 0 to 4 := 0;
    signal contador     : natural range 0 to CICLOS_POR_PASO - 1 := 0;
    signal paso         : natural range 0 to 15 := 0;
    signal patron       : std_logic_vector(3 downto 0);
begin
    process (clk12)
    begin
        if rising_edge(clk12) then
            botones_meta <= BTN4 & BTN3 & BTN2 & BTN1;
            botones_sync <= botones_meta;

            if modo /= modo_anterior then
                modo_anterior <= modo;
                contador <= 0;
                paso <= 0;
            elsif contador = CICLOS_POR_PASO - 1 then
                contador <= 0;
                if paso = 15 then paso <= 0; else paso <= paso + 1; end if;
            else
                contador <= contador + 1;
            end if;
        end if;
    end process;

    modo <= 4 when botones_sync(3) = '0' else
            3 when botones_sync(2) = '0' else
            2 when botones_sync(1) = '0' else
            1 when botones_sync(0) = '0' else 0;

    process (modo, paso)
    begin
        case modo is
            when 1 =>
                case paso mod 4 is
                    when 0 => patron <= "0001";
                    when 1 => patron <= "0010";
                    when 2 => patron <= "0100";
                    when others => patron <= "1000";
                end case;
            when 2 =>
                case paso mod 4 is
                    when 0 => patron <= "1000";
                    when 1 => patron <= "0100";
                    when 2 => patron <= "0010";
                    when others => patron <= "0001";
                end case;
            when 3 => patron <= std_logic_vector(to_unsigned(paso, 4));
            when 4 =>
                if (paso mod 2) = 0 then patron <= "0101"; else patron <= "1010"; end if;
            when others =>
                case paso mod 6 is
                    when 0 => patron <= "0001";
                    when 1 => patron <= "0010";
                    when 2 => patron <= "0100";
                    when 3 => patron <= "1000";
                    when 4 => patron <= "0100";
                    when others => patron <= "0010";
                end case;
        end case;
    end process;

    LED0 <= patron(0);
    LED1 <= patron(1);
    LED2 <= patron(2);
    LED3 <= patron(3);
end architecture;
