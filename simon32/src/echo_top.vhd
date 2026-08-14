----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.08.2026 20:55:00
-- Design Name: 
-- Module Name: echo_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity echo_top is
    port (
        clk : in std_logic;
        rst : in std_logic;
        uart_rx : in std_logic;
        uart_tx : out std_logic;
        led_busy : out std_logic;
        led_done : out std_logic
    
    
     );
end echo_top;

architecture Behavioral of echo_top is

begin
    uart_tx <= uart_rx;
    led_busy <= not uart_rx;
    led_done <= '0';


end Behavioral;
