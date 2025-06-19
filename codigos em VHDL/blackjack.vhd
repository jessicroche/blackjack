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
    signal playerValue : integer := 0; --alterado para nao ter mais range
    signal dealerValue : integer := 0; --alterado para nao ter mais range
    signal cardValue : integer range 0 to 13; --range alterado para 0 = carta invalida
	signal randomCard : integer range 0 to 13; --range alterado para 0 = carta invalida
    signal possuiAce : boolean := false;
    
    type state_type is (
        Pcar1, Pcar1_soma, Pcar2, Pcar2_soma,
        Dcar1, Dcar1_soma, Dcar2, Dcar2_soma,
        Pturn, Phit, Phit_soma, Pstay, Pbust,
        Dturn, Dhit, Dhit_soma, Dstay, Dbust,
        Plose_s, Pwin_s, Tie_s, --adicionados estados para referenciar as saidas
        winner, dummyP1, dummyP2, dummyD1, dummyD2,
        dummyPh, dummyDh
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
            when others => seg := "1111111"; -- tudo apagado
        end case;
        return seg;
    end function;


begin 

    process(clk, start)
    begin
        if start = '0' then
        playerValue  <= 0;
        dealerValue  <= 0;
        possuiAce    <= false;
        cardValue    <= 0;
        randomCard   <= 0;
        current_state <= Pcar1;

        elsif falling_edge(clk) then
            --atribuicao do valor de CARD para o cardvalue toda descida do clock
            --importante pois as atribuicoes utilizadas sao feitas considerando
            -- o valor inteiro de CARD e nao o STD logic vector
				randomCard <= to_integer(unsigned(CARD)) + 1;
            case current_state is
                when Pcar1 => 
                    playerValue  <= 0;
                    dealerValue  <= 0;
                    possuiAce    <= false;
                    randomCard   <= 0;
                    cardValue <= 0;
                    current_state <= dummyP1;
                
                when dummyP1 =>
                    cardValue <= randomCard;
                    if cardValue = 0 then
                        current_state <= dummyP1;
                    else
                        current_state <= Pcar1_soma;
                    end if;

                when Pcar1_soma =>
                    if cardValue = 1 then
                        playerValue <= playerValue + 11;
                        possuiAce <= true;
                    elsif cardValue > 10 then
                        playerValue <= playerValue + 10;
                    else
                        playerValue <= playerValue + cardValue;
                    end if;

                    -- nao possui logica de estouro porque o maximo nesse estado eh 11 na soma
                    current_state <= Pcar2;
                when Pcar2 =>
                    cardValue <= 0;
                    current_state <= dummyP2;

                when dummyP2 =>
                    cardValue <= randomCard;
                    if cardValue = 0 then
                        current_state <= dummyP2;
                    else
                        current_state <= Pcar2_soma;
                    end if;

                when Pcar2_soma =>
                    if cardValue = 1 then
                        if ( playerValue + 11 <= 21 ) then
                            playerValue <= playerValue + 11;
                            possuiAce <= true;
                        elsif ( playerValue + 11 > 21) then 
                        --tratada a unica possibilidade de estouro nesse estado, soma 22 com 2 ases
                            playerValue <= playerValue + cardValue;  -- soma o as como 1
                        end if;
                    elsif cardValue > 10 then 
                        playerValue <= playerValue + 10;
						  else
								playerValue <= playerValue + cardValue;
                    end if;

                    current_state <= Pturn;
                when Pturn =>
                    if HIT = '1' then
                        current_state <= Phit;
                    elsif STAY = '1' then
                        current_state <= Pstay;
                    else
                        current_state <= Pturn;                                      
                    end if;
                when Phit =>
                    cardValue <= 0;
                    current_state <= dummyPh;

                when dummyPh =>
                    cardValue <= randomCard;
                    if cardValue = 0 then
                        current_state <= dummyP2;
                    else
                        current_state <= Phit_soma;
                    end if;



                when Phit_soma =>
                    if cardValue = 1 then --se for as
                        if ( playerValue + 11 <= 21 ) then
                            playerValue <= playerValue + 11; --soma o as como 11
                            possuiAce <= true;
                            current_state <= Pturn;
                        elsif ( playerValue + cardValue <= 21) then 
                            playerValue <= playerValue + cardValue;  -- soma o as como 1
                        else
                            current_state <= Pbust; -- o as como 1 deu bust na soma
                        end if;
                    elsif cardValue > 10 then --se for figura
                        if playerValue + 10 <= 21 then
                        playerValue <= playerValue + 10;
                        current_state <= Pturn;
                        elsif ( playerValue + 10 > 21 and possuiAce ) then --estoura com uma figura, possui as
                            possuiAce <= false;
                            current_state <= Pturn;
                        else -- estoura com uma figura, nao possui as
                            current_state <= Pbust;
                        end if;
                    else -- se for qualquer outra carta
                        if playerValue + cardValue <= 21 then
                            playerValue <= playerValue + cardValue;
                            current_state <= Pturn;
                        elsif playerValue + cardValue > 21 and possuiAce then --estoura e tem as
                            possuiAce <= false;
                            playerValue <= playerValue - 10 + cardValue;
                            current_state <= Pturn;
                        else -- estoura e nao tem as
                            current_state <= Pbust;
                        end if;
                    end if;
                when Pstay =>
                    possuiAce <= false;
                    current_state <= Dcar1;
                when Pbust =>
                    current_state <= Plose_s; -- add estado de plose na transicao
                    
                when Dcar1 => 
                    cardValue <= 0;
                    current_state <= Dcar1_soma;

                when dummyD1 =>
                    cardValue <= randomCard;
                    if cardValue = 0 then
                        current_state <= dummyD1;
                    else
                        current_state <= Dcar1_soma;
                    end if;

                when Dcar1_soma =>
                    if cardValue = 1 then
                        dealerValue <= dealerValue + 11;
                        possuiAce <= true;
                    elsif cardValue > 10 then
                        dealerValue <= dealerValue + 10;
                    else
                        dealerValue <= dealerValue + cardValue;
                    end if;
                    -- nao possui logica de estouro porque o maximo nesse estado eh 11 na soma

                    current_state <= Dcar2;
                when Dcar2 =>
                    cardValue <= 0;
                    current_state <= Dcar2_soma;

                when dummyD2 =>
                    cardValue <= randomCard;
                    if cardValue = 0 then
                        current_state <= dummyD2;
                    else
                        current_state <= Dcar2_soma;
                    end if;

                when Dcar2_soma =>
                    if cardValue = 1 then
                        if ( dealerValue + 11 <= 21 ) then
                            dealerValue <= dealerValue + 11;
                            possuiAce <= true;
                        elsif ( dealerValue + 11 > 21) then 
                        --tratada a unica possibilidade de estouro nesse estado, soma 22 com 2 ases
                            dealerValue <= dealerValue + cardValue;  -- soma o as como 1
                        end if;
                    elsif cardValue > 10 then 
                        dealerValue <= dealerValue + 10;
					     else 
								dealerValue <= dealerValue + cardValue;
                    end if;
                    current_state <= Dturn;


                when Dturn =>
                    if dealerValue < 17 then
                        current_state <= Dhit;
                    elsif dealerValue >= 17 then
                        current_state <= Dstay;
                    else
                        current_state <= Dturn;                                      
                    end if;
                when Dhit =>
                    cardValue <= 0;
                    current_state <= Dhit_soma;

                when dummyDh =>
                    cardValue <= randomCard;
                    if cardValue = 0 then
                        current_state <= dummyDh;
                    else
                        current_state <= Dhit_soma;
                    end if;

                
                when Dhit_soma =>
                    if cardValue = 1 then --se for as
                        if ( dealerValue + 11 <= 21 ) then
                            dealerValue <= dealerValue + 11; --soma o as como 11
                            possuiAce <= true;
                            current_state <= Dturn;
                        elsif ( dealerValue + cardValue <= 21) then 
                            dealerValue <= dealerValue + cardValue;  -- soma o as como 1
                        else
                            current_state <= Dbust; -- o as como 1 deu bust na soma
                        end if;
                    elsif cardValue > 10 then --se for figura
                        if dealerValue + 10 <= 21 then
                        dealerValue <= dealerValue + 10;
                        current_state <= Dturn;
                        elsif ( dealerValue + 10 > 21 and possuiAce ) then --estoura com uma figura, possui as
                            possuiAce <= false;
                            current_state <= Dturn;
                        else -- estoura com uma figura, nao possui as
                            current_state <= Dbust;
                        end if;
                    else -- se for qualquer outra carta
                        if dealerValue + cardValue <= 21 then
                            dealerValue <= dealerValue + cardValue;
                            current_state <= Dturn;
                        elsif dealerValue + cardValue > 21 and possuiAce then --estoura e tem as
                            possuiAce <= false;
                            dealerValue <= dealerValue - 10 + cardValue;
                            current_state <= Dturn;
                        else -- estoura e nao tem as
                            current_state <= Dbust;
                        end if;
                    end if;
                    
                when Dstay =>
                    current_state <= winner;
                when Dbust =>
                --para chegar no dbust, o player precisa ter mandado '1' no stay
                --sem ter dado bust, entao eh vitoria imediata pro player
                    current_state <= Pwin_s; --add estado de pwin na transicao
                when winner =>
                --mudanca do estado winner para transicionar
                --para os novos estados pwin, plose, tie
                --importante porque a logica tava misturada e esse
                --estado estava mexendo diretamente nas saidas da FPGA
                    if playerValue > dealerValue then
                        current_state <= Pwin_s; 
                    elsif playerValue < dealerValue then
                        current_state <= Plose_s;
                    else
                        current_state <= Tie_s;
                    end if;
						when Pwin_s | Plose_s | tie_s =>
							current_state <= Pcar1;
                when others => null;
            end case;
        end if;
    end process;

process(current_state) is
begin
	PWIN <= '0';
	PLOSE <= '0';
	TIE <= '0';
	hexCard <= "1000000";
	sumDigit1 <= "1000000";
	sumDigit2 <= "1000000";
    case current_state is

        when Pcar1 | Dcar1 =>
            PWIN <= '0'; 
            PLOSE <= '0';
            TIE <= '0'; 
            REQCARD <= '1';
            --agora zera os displays no comeco da rodada
            hexCard   <= "1000000";
            sumDigit1 <= "1000000";
            sumDigit2 <= "1000000";

        when Dcar2 | Pcar2 | Dhit | Phit =>
            REQCARD <= '1'; --so da trigger na maquina de gerar cartas

        when Pcar1_soma | Pcar2_soma | Phit_soma => --add turn aqui
            REQCARD <= '0';
            hexCard <= hex_to_7seg(cardValue);
            sumDigit1 <= hex_to_7seg(playerValue/10);
            sumDigit2 <= hex_to_7seg(playerValue mod 10);

        when Dcar1_soma | Dcar2_soma | Dhit_soma => --add turn aqui
            REQCARD <= '0';
            hexCard <= hex_to_7seg(cardValue);
            sumDigit1 <= hex_to_7seg(dealerValue/10);
            sumDigit2 <= hex_to_7seg(dealerValue mod 10);

        when Dbust | Pwin_s =>
            PWIN <= '1';
            PLOSE <= '0'; 
            TIE <= '0'; 
        when Pbust | Plose_s =>
            PWIN <= '0'; 
            PLOSE <= '1'; 
            TIE <= '0'; 
        when tie_s =>
            PWIN <= '0'; 
            PLOSE <= '0'; 
            TIE <= '1';
			when others => null;
    end case;
end process;
        
end Behavioral;