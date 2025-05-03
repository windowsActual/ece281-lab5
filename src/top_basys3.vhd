--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

--# Establish top basys3, this code was given to me.
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;
      

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	--#Signals
	signal w_A : std_logic_vector(7 downto 0);
	signal w_B : std_logic_vector(7 downto 0);
	
	signal w_o_cycle : std_logic_vector(3 downto 0);
	signal w_o_clk : std_logic;
	
	signal w_o_flags : std_logic_vector(3 downto 0);
	signal w_o_result : std_logic_vector(7 downto 0);
	
	signal w_o_sign : std_logic;
	signal w_o_hund : std_logic_vector(3 downto 0);
	signal w_o_tens : std_logic_vector(3 downto 0);
	signal w_o_ones : std_logic_vector(3 downto 0);
	signal w_o_sel  : std_logic_vector(3 downto 0);
	
	signal w_o_data : std_logic_vector(3 downto 0);
	signal w_o_seg  : std_logic_vector(6 downto 0);
	
	signal w_mux_to_twos_comp : std_logic_vector(7 downto 0);
	
	
    --#Declare the sevenseg_decoder
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    --#Declare the TDM4
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
               i_reset		: in  STD_LOGIC; -- asynchronous
               i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
        );
    end component TDM4;
    
    --#Declare my clock divider
	component clock_divider is
        generic ( constant k_DIV : natural := 4	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    
    --#Declare my twos compliment decoder
    component twos_comp is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    end component twos_comp;

    --#Declare the ALU
    component ALU is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               i_op : in STD_LOGIC_VECTOR (2 downto 0);
               o_result : out STD_LOGIC_VECTOR (7 downto 0);
               o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component ALU;
    
    --Declare the controller_FSM
    component controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    


begin
	-- PORT MAPS ----------------------------------------
	
	fsm : controller_fsm
	   port map(
	       i_reset => btnU,
	       i_adv   => btnC,
	       o_cycle => w_o_cycle
	   );

    clock : clock_divider
        generic map ( k_DIV => 200000) -- 4 Hz clock from 100 MHz -- I Need to verify this value
        port map(
            i_clk   => clk,
            i_reset => '0',
            o_clk   => w_o_clk
       );
       
    daALU : ALU
        port map(
            i_A     => w_A(7 downto 0),
            i_B     => w_B(7 downto 0),
            i_op    => sw(2 downto 0),
            o_result=> w_o_result,
            o_flags=> w_o_flags
       );
       
    twocomp : twos_comp
        port map(
            i_bin   => w_mux_to_twos_comp,
            o_sign  => w_o_sign,
            o_hund  => w_o_hund,
            o_tens  => w_o_tens,
            o_ones  => w_o_ones
       );
       
    TDM : TDM4
        port map(
            i_reset => '0',
            i_clk   => w_o_clk,
            i_D3    => "0000",
            i_D2    => w_o_hund,
            i_D1    => w_o_tens,
            i_D0    => w_o_ones,
            o_data  => w_o_data,
            o_sel   => w_o_sel
        );
    
    sevensegdec : sevenseg_decoder
        port map(
            i_hex   => w_o_data,
            o_seg_n => w_o_seg
        );
 
	-- CONCURRENT STATEMENTS ----------------------------
	
	
	--The Display MUX:
	w_mux_to_twos_comp <= w_A when (w_o_cycle = x"2") else
	                      w_B when (w_o_cycle = x"4") else 
	                      w_o_result when (w_o_cycle = x"8");    
	                        
    --The Negative Situation and Blank situation:
    
    --The blank situation    
    --When cycle is state 0, anodes blank.
    an(3 downto 0) <= "1111" when (w_o_cycle = x"1") else
                       w_o_sel;

    --The negative sitation
    -- Displaying the negative sign only occurs when:
        -- In state3, when the negative flag is up, and TDM4 selects D3 
    
    seg(6 downto 0) <= w_o_seg(6 downto 0) when (w_o_cycle = not x"1") else
                       "0111111" when ((w_o_cycle = x"8") and (w_o_flags(3) = '1') and (w_o_sel = "0111")) else
                       w_o_seg(6 downto 0);


    
    -- Leds:
    led(15 downto 12) <= w_o_flags(3 downto 0);
    
    led(3 downto 0) <= "0001" when w_o_cycle = x"1" else
                       "0010" when w_o_cycle = x"2" else
                       "0100" when w_o_cycle = x"4" else
                       "1000" when w_o_cycle = x"8" else
                       "0000";

	-- PROCESSES --------------------------------------------------------------------
	REG_A : process (w_o_cycle)
	begin
		if rising_edge(w_o_cycle(1)) then
		  w_A <= sw(7 downto 0);
        end if;
    end process REG_A;
    
    REG_B : process (w_o_cycle)
    begin 
        if rising_edge(w_o_cycle(2)) then
           w_B <= sw(7 downto 0);
        end if;
    end process REG_B;

      
end top_basys3_arch;
