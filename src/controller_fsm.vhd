----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

signal f_Q : std_logic_vector (3 downto 0):="0001";
signal f_Q_next : std_logic_vector (3 downto 0);

begin

-- Concurrent statements
-- Nothing to declare

-- Next State Logic

    F_Q_next(0) <= (i_adv and f_Q(3)) or i_reset;
    F_Q_next(1) <= (i_adv and f_Q(0));
    F_Q_next(2) <= (i_adv and f_Q(1));
    F_Q_next(3) <= (i_adv and f_Q(2));
    
-- Output logic MUX:
    o_cycle <= "0001" when f_Q = x"1" else 
               "0010" when f_Q = x"2" else
               "0100" when f_Q = x"4" else
               "1000" when f_Q = x"8" else
               "0001";

end FSM;