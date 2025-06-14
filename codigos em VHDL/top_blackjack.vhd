library ieee;
use ieee.std_logic_1164.all;

entity top_blackjack is
    port (

	    --KEY(0) = CLOCK
	    --KEY(1) = START / RESET 
		KEY : in std_logic_vector(3 downto 0);

		--SW 9 A 6 = CARTA MANUAL
		--SW 5 = REQMANUAL
		--SW 0 = HIT
		--SW 1 = STAY
		SW : in std_logic_vector(9 downto 0);

        --LEDR 2 WIN
        --LEDR 1 TIE
        --LEDR 0 LOSE		
		LEDR : out std_logic_vector(9 downto 0);
        
		--hex3 = carta pescada em hexadecimal
		--hex1 = segundo digito da soma
		--hex0 = primeiro bit da soma
		HEX3 : out std_logic_vector(6 downto 0);
		HEX1 : out std_logic_vector(6 downto 0);
		HEX0 : out std_logic_vector(6 downto 0) 
    );
end top_blackjack;

architecture Behavioral of top_blackjack is

    signal cards_req   : std_logic;
    signal hexCard_int : std_logic_vector(3 downto 0);
	 
begin
    cards_inst : entity work.cards
        port map (
            clk         => KEY(0),
            reset       => KEY(1),
            reqCarta    => cards_req,
            reqManual   => SW(5),
            cartaManual => SW(9 downto 6),
            cartaFinal => hexCard_int
        );

    blackjack_inst : entity work.blackjack
        port map (
            HIT        => SW(0),
            STAY       => SW(1),
            START      => KEY(1),
            CLK        => KEY(0),
            CARD       => hexCard_int,
            REQCARD    => cards_req,
            PWIN       => LEDR(2),
            PLOSE      => LEDR(0),
            TIE        => LEDR(1),
            hexCard    => HEX3,
            sumDigit1  => HEX1,
            sumDigit2  => HEX0
        );
end Behavioral;