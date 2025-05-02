---------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    component ripple_adder is -- declare the component
        port (
            A : in STD_LOGIC_VECTOR(3 downto 0);
            B : in STD_LOGIC_VECTOR(3 downto 0);
            Cin  : in STD_LOGIC;
            S    : out STD_LOGIC_VECTOR(3 downto 0);
            Cout : out std_logic
        );
    end component ripple_adder; 
    
    -- Declare signal  
    signal w_sum     : STD_LOGIC_VECTOR(7 downto 0);
    signal w_low_carry  : STD_LOGIC;
    signal w_high_carry : STD_LOGIC;
    signal resultOUT    : std_logic_vector(7 downto 0);
    signal w_B_ALU   : std_logic_vector(7 downto 0);    
begin

    w_B_ALU <= i_B when (i_OP(0) = '0') else
                  not i_B;


U1 : ripple_adder -- Lower Bits
    port map(
        A    => i_A(3 downto 0),  -- Connect Lower input to A
        B    => w_B_ALU(3 downto 0),  -- Connect Lower input to B
        Cin  => i_OP(0),              -- carry into 
        S => w_sum(3 downto 0),          -- Output to low sum
        Cout => w_low_carry         -- Output to carry
    );
    
U2 : ripple_adder -- upper bits
port map(
        A    => i_A(7 downto 4),  -- Connect Upper input to A
        B    => w_B_ALU(7 downto 4),  -- Connect Upper input to B
        Cin  => w_low_carry,        -- Continue operation from lower half.
        S    => w_sum(7 downto 4),         -- Output to high sum
        Cout => w_high_carry        -- Retain if we had a carryout...oV
    );
    
    
    --Mux implementation  --Implement page 248. MUX
    resultOUT <= w_sum when i_OP = "000" else
                w_sum when i_OP = "001" else
                i_A and i_B when i_OP = "010" else
                i_A or i_B  when i_OP = "011" else 
                w_sum;
                
    o_result <= resultOUT ;           
-- flags
    --oVerflow:
    o_flags(0) <= not (i_op(0) xor i_A(7) xor i_B(7)) and
                  (i_A(7) xor w_sum(7)) and
                  (not i_op(1));
    --Carry:
    o_flags(1) <= w_high_carry and (not i_op(1));
    
    --Negative:
    o_flags(3) <= resultOUT(7);
    
    --Zero:
    o_flags(2) <= '1' when (resultOUT = x"00") else
                  '0';
end Behavioral;
