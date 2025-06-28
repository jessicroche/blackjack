library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity blackjack is
    port (
        HIT : in  std_logic; 
        STAY : in  std_logic;
        START : in  std_logic;
        CLK : in  std_logic;
        CARD : in  std_logic_vector(3 downto 0);

        REQCARD : out  std_logic;
        PWIN : out std_logic;
        PLOSE : out std_logic;
        TIE : out std_logic;
        hexCard : out std_logic_vector(6 downto 0); --carta pescada
        sumDigit1 : out std_logic_vector(6 downto 0); --soma
        sumDigit2 : out std_logic_vector(6 downto 0) --soma
    );
end blackjack;

architecture Behavioral of blackjack is
    signal playerValue : integer := 0; 
    signal dealerValue : integer := 0;
    signal cardValue : integer range 0 to 13; --range alterado para 0 = carta invalida
    signal hasAce : boolean := false;
    
    type state_type is (
        Player_card1, Player_card1_soma, Player_card2, Player_card2_soma,
        Dealer_card1, Dealer_card1_soma, Dealer_card2, Dealer_card2_soma,
        player_turn, playerHit_soma, playerStay, playerLose,
        dealer_turn, dealerHit_soma, dealerStay, playerWin, playerTie,
        decideWinner, dummy_Player_card1, dummy_Player_card2, dummyDealer_card1, dummyDealer_card2,
        dummy_playerHit, dummy_dealerHit
    );
    signal current_state : state_type; 


function hex_to_7seg(value : integer) return std_logic_vector is
    variable seg : std_logic_vector(6 downto 0);
begin
    case value is
        when 0  => seg := "1000000"; -- 0
        when 1  => seg := "1111001"; -- 1
        when 2  => seg := "0100100"; -- 2
        when 3  => seg := "0110000"; -- 3
        when 4  => seg := "0011001"; -- 4
        when 5  => seg := "0010010"; -- 5
        when 6  => seg := "0000010"; -- 6
        when 7  => seg := "1111000"; -- 7
        when 8  => seg := "0000000"; -- 8
        when 9  => seg := "0010000"; -- 9
        when 10 => seg := "0001000"; -- A
        when 11 => seg := "0000011"; -- b
        when 12 => seg := "1000110"; -- C
        when 13 => seg := "0100001"; -- d
        when 14 => seg := "0000110"; -- E
        when 15 => seg := "0001110"; -- F
        when others => seg := "1111111"; -- apagado
    end case;
    return seg;
end function;


begin 

    process(clk, start)
    begin
        if start = '0' then
        playerValue  <= 0;
        dealerValue  <= 0;
        hasAce    <= false;
        cardValue    <= 0;
        current_state <= Player_card1;

        elsif falling_edge(clk) then

            case current_state is
                when Player_card1 => 
                    playerValue  <= 0;
                    dealerValue  <= 0;
                    hasAce    <= false;
                    cardValue <= 0;
                    current_state <= dummy_Player_card1;
                
                when dummy_Player_card1 => 
                    if to_integer(unsigned(CARD)) = 0 then
                        current_state <= dummy_Player_card1;
                    else
                        cardValue <= to_integer(unsigned(CARD));
                        current_state <= Player_card1_soma;
                    end if;

                when Player_card1_soma => 
                    if cardValue = 1 then
                        playerValue <= playerValue + 11;
                        hasAce <= true;
                    elsif cardValue > 10 then
                        playerValue <= playerValue + 10;
                    else
                        playerValue <= playerValue + cardValue;
                    end if;

                    -- nao possui logica de estouro porque o maximo nesse estado eh 11 na soma
                    current_state <= Player_card2;
                when Player_card2 => 
                    cardValue <= 0;
                    current_state <= dummy_Player_card2;

                when dummy_Player_card2 => 
                    if to_integer(unsigned(CARD)) = 0 then
                        current_state <= dummy_Player_card2;
                    else
                        cardValue <= to_integer(unsigned(CARD));
                        current_state <= Player_card2_soma;
                    end if;

                when Player_card2_soma => 
                    if cardValue = 1 then
                        if ( playerValue + 11 <= 21 ) then
                            playerValue <= playerValue + 11;
                            hasAce <= true;
                        elsif ( playerValue + 11 > 21) then 
                        --tratada a unica possibilidade de estouro nesse estado, soma 22 com 2 ases
                            playerValue <= playerValue + cardValue;  -- soma o as como 1
                        end if;
                    elsif cardValue > 10 then 
                        playerValue <= playerValue + 10;
						  else
								playerValue <= playerValue + cardValue;
                    end if;
							
                    current_state <= player_turn;
                when player_turn => 
							cardValue <= 0;
                    if HIT = '1' and STAY = '0' then
                        current_state <= dummy_playerHit;
                    elsif STAY = '1' and HIT = '0' then
                        current_state <= playerStay;
                    else
                        current_state <= player_turn;                                      
                    end if;

                when dummy_playerHit => 
                    if to_integer(unsigned(CARD)) = 0 then
                        current_state <= dummy_playerHit;
                    else
                        cardValue <= to_integer(unsigned(CARD));
                        current_state <= playerHit_soma;
                    end if;

                when playerHit_soma => 
                    if cardValue = 1 then --se for as
                        if ( playerValue + 11 <= 21 ) then
                            playerValue <= playerValue + 11; --soma o as como 11
                            hasAce <= true;
                            current_state <= player_turn;
                        elsif ( playerValue + cardValue <= 21) then 
                            playerValue <= playerValue + cardValue;  -- soma o as como 1
									 current_state <= player_turn;
                        else
                            if(hasAce) then
                                playerValue <= playerValue - 10;
                                current_state <= player_turn;
                            else
                                current_state <= playerLose; -- o as como 1 deu bust na soma
                            end if;
                        end if;
                    elsif cardValue > 10 then --se for figura
                        if playerValue + 10 <= 21 then
                        playerValue <= playerValue + 10;
                        current_state <= player_turn;
                        elsif ( playerValue + 10 > 21 and hasAce ) then --estoura com uma figura, possui as
                            hasAce <= false;
                            current_state <= player_turn;
                        else -- estoura com uma figura, nao possui as
                            current_state <= playerLose;
                        end if;
                    else -- se for qualquer outra carta
                        if playerValue + cardValue <= 21 then
                            playerValue <= playerValue + cardValue;
                            current_state <= player_turn;
                        elsif playerValue + cardValue > 21 and hasAce then --estoura e tem as
                            hasAce <= false;
                            playerValue <= playerValue - 10 + cardValue;
                            current_state <= player_turn;
                        else -- estoura e nao tem as
                            current_state <= playerLose;
                        end if;
                    end if;
                when playerStay => 
                    hasAce <= false;
                    current_state <= Dealer_card1;
                    
                when Dealer_card1 => 
                    cardValue <= 0;
                    current_state <= dummyDealer_card1;

                when dummyDealer_card1 => 
                    if to_integer(unsigned(CARD)) = 0 then
                        current_state <= dummyDealer_card1;
                    else
                        cardValue <= to_integer(unsigned(CARD));
                        current_state <= Dealer_card1_soma;
                    end if;

                when Dealer_card1_soma => 
                    if cardValue = 1 then
                        dealerValue <= dealerValue + 11;
                        hasAce <= true;
                    elsif cardValue > 10 then
                        dealerValue <= dealerValue + 10;
                    else
                        dealerValue <= dealerValue + cardValue;
                    end if;
                    -- nao possui logica de estouro porque o maximo nesse estado eh 11 na soma

                    current_state <= Dealer_card2;
                when Dealer_card2 => 
                    cardValue <= 0;
                    current_state <= dummyDealer_card2;

                when dummyDealer_card2 =>
                    if to_integer(unsigned(CARD)) = 0 then
                        current_state <= dummyDealer_card2;
                    else
                        cardValue <= to_integer(unsigned(CARD));
                        current_state <= Dealer_card2_soma;
                    end if;

                when Dealer_card2_soma => 
                    if cardValue = 1 then
                        if ( dealerValue + 11 <= 21 ) then
                            dealerValue <= dealerValue + 11;
                            hasAce <= true;
                        elsif ( dealerValue + 11 > 21) then 
                        --tratada a unica possibilidade de estouro nesse estado, soma 22 com 2 ases
                            dealerValue <= dealerValue + cardValue;  -- soma o as como 1
                        end if;
                    elsif cardValue > 10 then 
                        dealerValue <= dealerValue + 10;
					     else 
								dealerValue <= dealerValue + cardValue;
                    end if;
                    current_state <= dealer_turn;


                when dealer_turn => 
					 cardValue <= 0;
                    if dealerValue < 17 then
                        current_state <= dummy_dealerHit;
                    elsif dealerValue >= 17 then
                        current_state <= dealerStay;
                    else
                        current_state <= dealer_turn;                             
                    end if;

                when dummy_dealerHit =>
                    if to_integer(unsigned(CARD)) = 0 then
                        current_state <= dummy_dealerHit;
                    else
                        cardValue <= to_integer(unsigned(CARD));
                        current_state <= dealerHit_soma;
                    end if;

                
                when dealerHit_soma => 
                    if cardValue = 1 then --se for as
                        if ( dealerValue + 11 <= 21 ) then
                            dealerValue <= dealerValue + 11; --soma o as como 11
                            hasAce <= true;
                            current_state <= dealer_turn;
                        elsif ( dealerValue + cardValue <= 21) then 
                            dealerValue <= dealerValue + cardValue;  -- soma o as como 1
									 current_state <= dealer_turn;
                        else
							if(hasAce) then
								dealerValue <= dealerValue - 10;
								current_state <= dealer_turn;
							else
								current_state <= playerLose; -- o as como 1 deu bust na soma
							end if;
                        end if;
                    elsif cardValue > 10 then --se for figura
                        if dealerValue + 10 <= 21 then
                        dealerValue <= dealerValue + 10;
                        current_state <= dealer_turn;
                        elsif ( dealerValue + 10 > 21 and hasAce ) then --estoura com uma figura, possui as
                            hasAce <= false;
                            current_state <= dealer_turn;
                        else -- estoura com uma figura, nao possui as
                            current_state <= playerWin;
                        end if;
                    else -- se for qualquer outra carta
                        if dealerValue + cardValue <= 21 then
                            dealerValue <= dealerValue + cardValue;
                            current_state <= dealer_turn;
                        elsif dealerValue + cardValue > 21 and hasAce then --estoura e tem as
                            hasAce <= false;
                            dealerValue <= dealerValue - 10 + cardValue;
                            current_state <= dealer_turn;
                        else -- estoura e nao tem as
                            current_state <= playerWin;
                        end if;
                    end if;
                    
                when dealerStay =>
                    current_state <= decideWinner;

                when decideWinner => 
                    if playerValue > dealerValue then
                        current_state <= playerWin; 
                    elsif playerValue < dealerValue then
                        current_state <= playerLose;
                    else
                        current_state <= playerTie;
                    end if;
						  
					when playerWin | playerLose | playerTie =>
						current_state <= Player_card1; --reset
                when others => null;
            end case;
        end if;
    end process;

process(current_state) is
begin
    PWIN <= '0';
    PLOSE <= '0';
    TIE <= '0';
    REQCARD <= '0'; 
    hexCard <= hex_to_7seg(0); 
    sumDigit1 <= hex_to_7seg(0); 
    sumDigit2 <= hex_to_7seg(0);
    case current_state is
            
        when Player_card1 | Player_card2 | Dealer_card1 | Dealer_card2 | dummy_dealerHit | dummy_playerHit =>
            REQCARD <= '1';
            if current_state = Player_card2 or current_state = dummy_playerHit then
                hexCard <= hex_to_7seg(cardValue);
                sumDigit1 <= hex_to_7seg(playerValue/10);
                sumDigit2 <= hex_to_7seg(playerValue mod 10);
            elsif current_state = Dealer_card2 or current_state = dummy_dealerHit then
                hexCard <= hex_to_7seg(cardValue);
                sumDigit1 <= hex_to_7seg(dealerValue/10);
                sumDigit2 <= hex_to_7seg(dealerValue mod 10);
            end if;

            when dummy_Player_card1 | dummy_Player_card2 | dummyDealer_card1 | dummyDealer_card2 | player_turn | dealer_turn =>
                REQCARD <= '0';
                hexCard <= hex_to_7seg(0); -- Zera a carta temporariamente enquanto espera a nova.
                if current_state = dummy_Player_card2 or current_state = dummy_playerHit or current_state = player_turn then
                    sumDigit1 <= hex_to_7seg(playerValue/10);
                    sumDigit2 <= hex_to_7seg(playerValue mod 10);
                elsif current_state = dummyDealer_card2 or current_state = dummy_dealerHit or current_state = dealer_turn then
                    sumDigit1 <= hex_to_7seg(dealerValue/10);
                    sumDigit2 <= hex_to_7seg(dealerValue mod 10);
                end if;

        when Player_card1_soma | Player_card2_soma | playerHit_soma |
            Dealer_card1_soma | Dealer_card2_soma | dealerHit_soma  =>
            REQCARD <= '0';
            if current_state = Player_card1_soma or current_state = Player_card2_soma or current_state = playerHit_soma then
                REQCARD <= '0';
                hexCard <= hex_to_7seg(cardValue);
                sumDigit1 <= hex_to_7seg(playerValue/10);
                sumDigit2 <= hex_to_7seg(playerValue mod 10);
            elsif current_state = Dealer_card1_soma or current_state = Dealer_card2_soma or current_state = dealerHit_soma then
                REQCARD <= '0';
                hexCard <= hex_to_7seg(cardValue);
                sumDigit1 <= hex_to_7seg(dealerValue/10);
                sumDigit2 <= hex_to_7seg(dealerValue mod 10);
            end if;
		when playerStay | dealerStay =>
			REQCARD <= '0';
        when playerWin =>
			REQCARD <= '0';
            PWIN <= '1';
            PLOSE <= '0'; 
            TIE <= '0'; 
        when playerLose =>
			REQCARD <= '0';
            PWIN <= '0'; 
            PLOSE <= '1'; 
            TIE <= '0'; 
        when playerTie =>
			REQCARD <= '0';
            PWIN <= '0'; 
            PLOSE <= '0'; 
            TIE <= '1';
			when others => null;
    end case;
end process;
        
end Behavioral;