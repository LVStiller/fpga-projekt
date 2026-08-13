library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simon_core is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        start      : in  std_logic;
        plaintext  : in  std_logic_vector(31 downto 0);
        key        : in  std_logic_vector(63 downto 0);
        ciphertext : out std_logic_vector(31 downto 0);
        busy       : out std_logic;
        done       : out std_logic
    );
end entity simon_core;

architecture rtl of simon_core is

    -- FSM-Zustaende
    type state_t is (IDLE, RUN, DONE_ST);
    signal state : state_t;

    -- Datenregister: die zwei 16-Bit-Haelften
    signal x_reg : unsigned(15 downto 0);
    signal y_reg : unsigned(15 downto 0);

    -- Rundenzaehler: 0 bis 31
    signal round_cnt : unsigned(4 downto 0);

    -- Zirkulaerer Linksshift fuer 16-Bit-Woerter
    function rol16(v : unsigned(15 downto 0); n : natural) return unsigned is
    begin
        return v(15 - n downto 0) & v(15 downto 16 - n);
    end function;

    -- Zirkulaerer Rechtsshift fuer 16-Bit-Woerter
    function ror16(v : unsigned(15 downto 0); n : natural) return unsigned is
    begin
        return v(n - 1 downto 0) & v(15 downto n);
    end function;

    -- Schluesselregister: k0 = aktueller Rundenschluessel
    signal k0, k1, k2, k3 : unsigned(15 downto 0);

    -- z0-Sequenz fuer Simon32/64 (62 Bit, wiederholt sich)
    constant Z0 : std_logic_vector(0 to 61) :=
        "11111010001001010110000111001101111101000100101011000011100110";

begin

    process(clk)
    begin

        if rising_edge(clk) then
            if rst = '1' then
                state     <= IDLE;
                round_cnt <= (others => '0');
                x_reg     <= (others => '0');
                y_reg     <= (others => '0');
            else
                case state is

                    when IDLE =>
                        if start = '1' then
                            x_reg     <= unsigned(plaintext(31 downto 16));
                            y_reg     <= unsigned(plaintext(15 downto 0));
                            k3        <= unsigned(key(63 downto 48));
                            k2        <= unsigned(key(47 downto 32));
                            k1        <= unsigned(key(31 downto 16));
                            k0        <= unsigned(key(15 downto 0));
                            round_cnt <= (others => '0');
                            state     <= RUN;
                        end if;

                    when RUN =>
                        -- Verschluesselungsrunde mit aktuellem Schluessel k0
                        x_reg <= y_reg xor
                            (rol16(x_reg, 1) and rol16(x_reg, 8)) xor
                            rol16(x_reg, 2) xor
                            k0;
                        y_reg <= x_reg;

                        -- Key Expansion: naechsten Schluessel berechnen
                        k0 <= k1;
                        k1 <= k2;
                        k2 <= k3;
                        k3 <= k0 xor x"FFFC"
                            xor (ror16(k3, 3) xor k1)
                            xor ror16(ror16(k3, 3) xor k1, 1)
                            xor ("000000000000000" & Z0(to_integer(round_cnt) mod 62));

                        if round_cnt = 31 then
                            state <= DONE_ST;
                        else
                            round_cnt <= round_cnt + 1;
                        end if;

                    when DONE_ST =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

    -- Ausgaenge (kombinatorisch aus dem Zustand abgeleitet)
    busy       <= '1' when state = RUN else '0';
    done       <= '1' when state = DONE_ST else '0';
    ciphertext <= std_logic_vector(x_reg) & std_logic_vector(y_reg);

end architecture rtl;