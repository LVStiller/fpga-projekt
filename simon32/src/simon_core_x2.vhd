library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Simon32/64 Core, 2-fach entrollte Variante:
-- zwei Runden pro Takt, 16 Takte pro Block.
entity simon_core_x2 is
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
end entity simon_core_x2;

architecture rtl of simon_core_x2 is

    type state_t is (IDLE, RUN, DONE_ST);
    signal state : state_t;

    signal x_reg : unsigned(15 downto 0);
    signal y_reg : unsigned(15 downto 0);

    -- Zaehlt Doppelrunden: 0 bis 15
    signal round_cnt : unsigned(4 downto 0);

    -- Schluesselregister
    signal k0, k1, k2, k3 : unsigned(15 downto 0);

    -- z0-Sequenz fuer Simon32/64
    constant Z0 : std_logic_vector(0 to 61) :=
        "11111010001001010110000111001101111101000100101011000011100110";

    -- Zirkulaerer Linksshift
    function rol16(v : unsigned(15 downto 0); n : natural) return unsigned is
    begin
        return v(15 - n downto 0) & v(15 downto 16 - n);
    end function;

    -- Zirkulaerer Rechtsshift
    function ror16(v : unsigned(15 downto 0); n : natural) return unsigned is
    begin
        return v(n - 1 downto 0) & v(15 downto n);
    end function;

begin

    process(clk)
        variable xa             : unsigned(15 downto 0);
        variable k4, k5, t1, t2 : unsigned(15 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state     <= IDLE;
                round_cnt <= (others => '0');
                x_reg     <= (others => '0');
                y_reg     <= (others => '0');
                k0        <= (others => '0');
                k1        <= (others => '0');
                k2        <= (others => '0');
                k3        <= (others => '0');
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
                        -- Runde A mit k0 (Variable: sofort gueltig)
                        xa := y_reg xor (rol16(x_reg, 1) and rol16(x_reg, 8))
                            xor rol16(x_reg, 2) xor k0;
                        -- Runde B mit k1
                        x_reg <= x_reg xor (rol16(xa, 1) and rol16(xa, 8))
                            xor rol16(xa, 2) xor k1;
                        y_reg <= xa;

                        -- Key Expansion: zwei Schritte pro Takt
                        t1 := ror16(k3, 3) xor k1;
                        k4 := k0 xor x"FFFC" xor t1 xor ror16(t1, 1)
                            xor ("000000000000000" &
                            Z0(to_integer(round_cnt & '0') mod 62));
                        t2 := ror16(k4, 3) xor k2;
                        k5 := k1 xor x"FFFC" xor t2 xor ror16(t2, 1)
                            xor ("000000000000000" &
                            Z0((to_integer(round_cnt & '0') + 1) mod 62));
                        k0 <= k2;
                        k1 <= k3;
                        k2 <= k4;
                        k3 <= k5;

                        if round_cnt = 15 then
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

    busy       <= '1' when state = RUN else '0';
    done       <= '1' when state = DONE_ST else '0';
    ciphertext <= std_logic_vector(x_reg) & std_logic_vector(y_reg);

end architecture rtl;