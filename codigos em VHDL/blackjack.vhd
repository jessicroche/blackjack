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
        hexCard : out std_logic_vector(7 downto 0); --carta pescada
        sumDigit1 : out std_logic_vector(7 downto 0); --soma
        sumDigit2 : out std_logic_vector(7 downto 0) --soma
    );
end blackjack;

architecture Behavioral of blackjack is
    signal playerValue : integer := 0; --alterado para nao ter mais range
    signal dealerValue : integer := 0; --alterado para nao ter mais range
    signal cardValue : integer range 1 to 13;
    signal possuiAce : boolean := false;
    
    type state_type is (
        Pcar1, Pcar1_wait, Pcar2, Pcar2_wait,
        Dcar1, Dcar1_wait, Dcar2, Dcar2_wait,
        Pturn, Phit, Phit_wait, Pstay, Pbust,
        Dturn, Dhit, Dhit_wait, Dstay, Dbust,
        Plose_, Pwin_, Tie_, --adicionados estados para referenciar as saidas
        winner
    );
    signal current_state : state_type; 
    signal next_state    : state_type;


    function hex_to_7seg(value : integer) return std_logic_vector is
    variable seg : std_logic_vector(7 downto 0); 
    begin
        case value is
            when 0  => seg := "11000000"; -- 0
            when 1  => seg := "11111001"; -- 1
            when 2  => seg := "10100100"; -- 2
            when 3  => seg := "10110000"; -- 3
            when 4  => seg := "10011001"; -- 4
            when 5  => seg := "10010010"; -- 5
            when 6  => seg := "10000010"; -- 6
            when 7  => seg := "11111000"; -- 7
            when 8  => seg := "10000000"; -- 8
            when 9  => seg := "10010000"; -- 9
            when 10 => seg := "10001000"; -- A
            when 11 => seg := "10000011"; -- b
            when 12 => seg := "11000110"; -- C
            when 13 => seg := "10100001"; -- d
            when others => seg := "11111111"; -- tudo apagado
        end case;
        return seg;
    end function;


begin 

    process(clk, start)
    begin
        if start = '1' then
            current_state <= Pcar1;
            playerValue <= 0; -- reset do valor do player
            dealerValue <= 0; -- reset do dealer
            possuiAce <= false;  -- reset ta flag do as

        elsif falling_edge(clk) then
            --atribuicao do valor de CARD para o cardvalue toda descida do clock
            --importante pois as atribuicoes utilizadas sao feitas considerando
            -- o valor inteiro de CARD e nao o STD logic vector
            cardValue <= to_integer(unsigned(CARD)) + 1;
            case current_state is
                        when Pcar1 => 
                            REQCARD <= '1';
                            next_state <= Pcar1_wait;
                        when Pcar1_wait =>
                            REQCARD <= '0';
                            if cardValue = 1 then
                                playerValue <= playerValue + 11;
                                possuiAce <= true;
                            elsif cardValue > 10 then
                                playerValue <= playerValue + 10;
                            else
                                playerValue <= playerValue + cardValue;
                            end if;

                            -- nao possui logica de estouro porque o maximo nesse estado eh 11 na soma
                            next_state <= Pcar2;
                        when Pcar2 =>
                            REQCARD <= '1'; 
                            next_state <= Pcar2_wait;
                        when Pcar2_wait =>
                            REQCARD <= '0'; 
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
                            end if;

                            next_state <= Pturn;
                        when Pturn =>
                            if HIT = '1' then
                                next_state <= Phit;
                            elsif STAY = '1' then
                                next_state <= Pstay;
                            else
                                next_state <= Pturn;                                      
                            end if;
                        when Phit =>
                            REQCARD <= '1'; 
                            next_state <= Phit_wait;
                        when Phit_wait =>
                            REQCARD <= '0'; 
                            if cardValue = 1 then --se for as
                                if ( playerValue + 11 <= 21 ) then
                                    playerValue <= playerValue + 11; --soma o as como 11
                                    possuiAce <= true;
                                    next_state <= Pturn;
                                elsif ( playerValue + cardValue <= 21) then 
                                    playerValue <= playerValue + cardValue;  -- soma o as como 1
                                else
                                    next_state <= Pbust; -- o as como 1 deu bust na soma
                                end if;
                            elsif cardValue > 10 then --se for figura
                                if playerValue + 10 <= 21 then
                                playerValue <= playerValue + 10;
                                next_state <= Pturn;
                                elsif ( playerValue + 10 > 21 and possuiAce ) then --estoura com uma figura, possui as
                                    possuiAce <= false;
                                    next_state <= Pturn;
                                else -- estoura com uma figura, nao possui as
                                    next_state <= Pbust;
                                end if;
                            else -- se for qualquer outra carta
                                if playerValue + cardValue <= 21 then
                                    playerValue <= playerValue + cardValue;
                                    next_state <= Pturn;
                                elsif playerValue + cardValue > 21 and possuiAce then --estoura e tem as
                                    possuiAce <= false;
                                    playerValue <= playerValue - 10 + cardValue;
                                    next_state <= Pturn;
                                else -- estoura e nao tem as
                                    next_state <= Pbust;
                                end if;
                            end if;
                        when Pstay =>
                            possuiAce <= false;
                            next_state <= Dcar1;
                        when Pbust =>
                            next_state <= Plose_; -- add estado de plose na transicao
                            
                        when Dcar1 => 
                            REQCARD <= '1';
                            next_state <= Dcar1_wait;
                        when Dcar1_wait =>
                            REQCARD <= '0';
                            if cardValue = 1 then
                                dealerValue <= dealerValue + 11;
                                possuiAce <= true;
                            elsif cardValue > 10 then
                                dealerValue <= dealerValue + 10;
                            else
                                dealerValue <= dealerValue + cardValue;
                            end if;
                            -- nao possui logica de estouro porque o maximo nesse estado eh 11 na soma

                            next_state <= Dcar2;
                        when Dcar2 =>
                            REQCARD <= '1'; 
                            next_state <= Dcar2_wait;
                        when Dcar2_wait =>
                            REQCARD <= '0'; 
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
                            end if;
                            next_state <= Dturn;


                        when Dturn =>
                            if dealerValue < 17 then
                                next_state <= Dhit;
                            elsif dealerValue >= 17 then
                                next_state <= Dstay;
                            else
                                next_state <= Dturn;                                      
                            end if;
                        when Dhit =>
                            REQCARD <= '1'; 
                            next_state <= Dhit_wait;
                        when Dhit_wait =>
                            REQCARD <= '0'; 
                            if cardValue = 1 then --se for as
                                if ( dealerValue + 11 <= 21 ) then
                                    dealerValue <= dealerValue + 11; --soma o as como 11
                                    possuiAce <= true;
                                    next_state <= Dturn;
                                elsif ( dealerValue + cardValue <= 21) then 
                                    dealerValue <= dealerValue + cardValue;  -- soma o as como 1
                                else
                                    next_state <= Dbust; -- o as como 1 deu bust na soma
                                end if;
                            elsif cardValue > 10 then --se for figura
                                if dealerValue + 10 <= 21 then
                                dealerValue <= dealerValue + 10;
                                next_state <= Dturn;
                                elsif ( dealerValue + 10 > 21 and possuiAce ) then --estoura com uma figura, possui as
                                    possuiAce <= false;
                                    next_state <= Dturn;
                                else -- estoura com uma figura, nao possui as
                                    next_state <= Dbust;
                                end if;
                            else -- se for qualquer outra carta
                                if dealerValue + cardValue <= 21 then
                                    dealerValue <= dealerValue + cardValue;
                                    next_state <= Dturn;
                                elsif dealerValue + cardValue > 21 and possuiAce then --estoura e tem as
                                    possuiAce <= false;
                                    dealerValue <= dealerValue - 10 + cardValue;
                                    next_state <= Dturn;
                                else -- estoura e nao tem as
                                    next_state <= Dbust;
                                end if;
                            end if;
                            
                        when Dstay =>
                        next_state <= winner;
                        when Dbust =>
                        --para chegar no dbust, o player precisa ter mandado '1' no stay
                        --sem ter dado bust, entao eh vitoria imediata pro player
                            next_state <= Pwin_; --add estado de pwin na transicao
                        when winner =>
                        --mudanca do estado winner para transicionar
                        --para os novos estados pwin, plose, tie
                        --importante porque a logica tava misturada e esse
                        --estado estava mexendo diretamente nas saidas da FPGA
                            if playerValue > dealerValue then
                                next_state <= Pwin_; 
                            elsif playerValue < dealerValue then
                                next_state <= Plose_;
                            else
                                next_state <= Tie_;
                            end if;
                        
            end case;
            current_state <= next_state;
            end if;
    end process;

process(current_state) is
begin
    case current_state is
        when Pcar1_wait | Pcar2_wait | Phit_wait =>
        hexCard <= hex_to_7seg(cardValue);
        sumDigit1 <= hex_to_7seg(playerValue/10);
        sumDigit2 <= hex_to_7seg(playerValue mod 10);

        when Dcar1_wait | Dcar2_wait | Dhit_wait =>
        hexCard <= hex_to_7seg(cardValue);
        sumDigit1 <= hex_to_7seg(dealerValue/10);
        sumDigit2 <= hex_to_7seg(dealerValue mod 10);

        when Dbust | Pwin_ =>
            PWIN <= '1';
            PLOSE <= '0'; 
            TIE <= '0'; 
        when Pbust | Plose_ =>
            PWIN <= '0'; 
            PLOSE <= '1'; 
            TIE <= '0'; 
        when tie_ =>
            PWIN <= '0'; 
            PLOSE <= '0'; 
            TIE <= '1';
    end case;
end process;
        
end Behavioral;