library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simon_top is
    generic (
        CLKS_PER_BIT : natural := 868
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        uart_rx  : in  std_logic;
        uart_tx  : out std_logic;
        led_busy : out std_logic;
        led_done : out std_logic
    );
end entity simon_top;

architecture rtl of simon_top is

    -- UART-Signale
    signal rx_data  : std_logic_vector(7 downto 0);
    signal rx_valid : std_logic;
    signal tx_data  : std_logic_vector(7 downto 0);
    signal tx_send  : std_logic;
    signal tx_busy  : std_logic;

    -- Simon-Core-Signale
    signal core_start : std_logic;
    signal core_ct    : std_logic_vector(31 downto 0);
    signal core_busy  : std_logic;
    signal core_done  : std_logic;

    -- Empfangspuffer: 12 Bytes = 96 Bit (Schluessel + Klartext)
    signal buf      : std_logic_vector(95 downto 0);
    signal byte_cnt : unsigned(3 downto 0);

    -- Sendepuffer fuer die 4 Ciphertext-Bytes
    signal ct_reg   : std_logic_vector(31 downto 0);

    type state_t is (RECV, ENCRYPT, SEND_BYTE, WAIT_TX);
    signal state : state_t;

    -- Synchronizer gegen Metastabilitaet am asynchronen RX-Eingang
    signal rx_sync1, rx_sync2 : std_logic := '1';

begin

    sync_proc : process(clk)
    begin
        if rising_edge(clk) then
            rx_sync1 <= uart_rx;
            rx_sync2 <= rx_sync1;
        end if;
    end process;

    rx_inst : entity work.uart_rx
        generic map ( CLKS_PER_BIT => CLKS_PER_BIT )
        port map (
            clk => clk, rst => rst,
            rx => rx_sync2,
            data_out => rx_data, valid => rx_valid
        );

    tx_inst : entity work.uart_tx
        generic map ( CLKS_PER_BIT => CLKS_PER_BIT )
        port map (
            clk => clk, rst => rst,
            send => tx_send, data_in => tx_data,
            tx => uart_tx, busy => tx_busy
        );

    core_inst : entity work.simon_core
        port map (
            clk => clk, rst => rst,
            start => core_start,
            plaintext  => buf(31 downto 0),
            key        => buf(95 downto 32),
            ciphertext => core_ct,
            busy => core_busy, done => core_done
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state      <= RECV;
                byte_cnt   <= (others => '0');
                core_start <= '0';
                tx_send    <= '0';
            else
                core_start <= '0';   -- Defaults: Pulse nur 1 Takt
                tx_send    <= '0';

                case state is

                    when RECV =>
                        if rx_valid = '1' then
                            -- neues Byte unten reinschieben
                            buf <= buf(87 downto 0) & rx_data;
                            if byte_cnt = 11 then
                                byte_cnt   <= (others => '0');
                                core_start <= '1';
                                state      <= ENCRYPT;
                            else
                                byte_cnt <= byte_cnt + 1;
                            end if;
                        end if;

                    when ENCRYPT =>
                        if core_done = '1' then
                            ct_reg   <= core_ct;
                            byte_cnt <= (others => '0');
                            state    <= SEND_BYTE;
                        end if;

                    when SEND_BYTE =>
                        if tx_busy = '0' then
                            -- oberstes Byte zuerst (MSB first)
                            tx_data <= ct_reg(31 downto 24);
                            tx_send <= '1';
                            -- Puffer nach links schieben
                            ct_reg  <= ct_reg(23 downto 0) & x"00";
                            state   <= WAIT_TX;
                        end if;

                    when WAIT_TX =>
                        -- warten bis Sender das Byte angenommen hat
                        if tx_busy = '1' then
                            if byte_cnt = 3 then
                                byte_cnt <= (others => '0');
                                state    <= RECV;
                            else
                                byte_cnt <= byte_cnt + 1;
                                state    <= SEND_BYTE;
                            end if;
                        end if;

                end case;
            end if;
        end if;
    end process;

    led_busy <= core_busy;
    led_done <= '1' when state = SEND_BYTE or state = WAIT_TX else '0';

end architecture rtl;