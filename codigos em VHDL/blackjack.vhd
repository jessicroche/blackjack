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
        hexCard : out std_logic_vector(3 downto 0);
        sumDecimal : out std_logic_vector(7 downto 0)
    );
end blackjack;

architecture Behavioral of blackjack is
    signal playerValue : integer range 0 to 21 := 0;
    signal dealerValue : integer range 0 to 21 := 0;
    signal cardValue : integer range 1 to 13;
    signal possuiAce : boolean := false;
    signal digit1, digit2 : std_logic_vector(3 downto 0);
    type state_type is (
        Pcar1, Pcar1_wait, Pcar2, Pcar2_wait,
        Dcar1, Dcar1_wait, Dcar2, Dcar2_wait,
        Pturn, Phit, Phit_wait, Pstay, Pbust,
        Dturn, Dhit, Dhit_wait, Dstay, Dbust,
        winner
    );
    signal current_state : state_type; 
    signal next_state    : state_type;
begin 

    process(clk, start)
    begin
        if start = '1' then
            current_state <= Pcar1;
        elsif falling_edge(clk) then
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
                            sumDecimal <= std_logic_vector(to_unsigned(playerValue, 8));
                            hexCard <= CARD;
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
                            sumDecimal <= std_logic_vector(to_unsigned(playerValue, 8));
                            hexCard <= CARD;
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
                            sumDecimal <= std_logic_vector(to_unsigned(playerValue, 8));
                            hexCard <= CARD;
                        when Pstay =>
                            possuiAce <= false;
                            next_state <= Dcar1;
                        

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
                            sumDecimal <= std_logic_vector(to_unsigned(dealerValue, 8));
                            -- nao possui logica de estouro porque o maximo nesse estado eh 11 na soma
                            hexCard <= CARD;
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
                            sumDecimal <= std_logic_vector(to_unsigned(dealerValue, 8));
                            hexCard <= CARD;
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
                            sumDecimal <= std_logic_vector(to_unsigned(dealerValue, 8));
                            hexCard <= CARD;
                            
                            when Dstay =>
                                if playerValue > 21 then
                                    PLOSE <= '1';
                                else
                                    next_state <= winner;
                                end if;


                            -- estados de decisao

                            when Pbust =>
                                PLOSE <= '1'; --estouro do player, vitoria imediata do dealer
                            when Dbust =>
                            --para chegar no dbust, o player precisa ter mandado '1' no stay
                            --sem ter dado bust, entao eh vitoria imediata pro player
                                PWIN <= '1';
                            when winner =>
                                if playerValue > dealerValue then
                                    PLOSE <= '0';
                                    PWIN <= '1';
                                    TIE <= '0';
                                elsif playerValue < dealerValue then
                                    PLOSE <= '1';
                                    PWIN <= '0'; 
                                    TIE <= '0';
                                else
                                    PLOSE <= '0'; 
                                    PWIN <= '0'; 
                                    TIE <= '1';
                                end if;
                        end case;
                        
                    end if;
                end process;

    process(current_state) is begin
        case current_state is
            when Pcar1_wait =>
                sumDecimal <= std_logic_vector(to_unsigned(playerValue, 8));
                digit1 <= std_logic_vector(to_unsigned(playerValue / 10, 4)); -- Dezena
                digit2 <= std_logic_vector(to_unsigned(playerValue mod 10, 4)); -- Unidade
                hexCard <= CARD;
            when Pcar2_wait =>
                sumDecimal <= std_logic_vector(to_unsigned(playerValue, 8));
                digit1 <= std_logic_vector(to_unsigned(playerValue / 10, 4)); -- Dezena
                digit2 <= std_logic_vector(to_unsigned(playerValue mod 10, 4)); -- Unidade
                hexCard <= CARD;
            when Phit_wait =>
                sumDecimal <= std_logic_vector(to_unsigned(playerValue, 8));
                digit1 <= std_logic_vector(to_unsigned(playerValue / 10, 4)); -- Dezena
                digit2 <= std_logic_vector(to_unsigned(playerValue mod 10, 4)); -- Unidade
                hexCard <= CARD;
            when Dcar1_wait =>
                sumDecimal <= std_logic_vector(to_unsigned(dealerValue, 8));
                digit1 <= std_logic_vector(to_unsigned(dealerValue / 10, 4)); -- Dezena
                digit2 <= std_logic_vector(to_unsigned(dealerValue mod 10, 4)); -- Unidade
                hexCard <= CARD;
            when Dcar2_wait =>
                sumDecimal <= std_logic_vector(to_unsigned(dealerValue, 8));
                digit1 <= std_logic_vector(to_unsigned(dealerValue / 10, 4)); -- Dezena
                digit2 <= std_logic_vector(to_unsigned(dealerValue mod 10, 4)); -- Unidade
                hexCard <= CARD;
            when Dhit_wait =>
                sumDecimal <= std_logic_vector(to_unsigned(dealerValue, 8));
                digit1 <= std_logic_vector(to_unsigned(dealerValue / 10, 4)); -- Dezena
                digit2 <= std_logic_vector(to_unsigned(dealerValue mod 10, 4)); -- Unidade
                hexCard <= CARD;
            when Pstay =>
                sumDecimal <= (others => '0');
                digit1 <= (others => '0');
                digit2 <= (others => '0');
                hexCard <= (others => '0');
            when Dstay =>
                
            
            end case;
        end process;
        
end Behavioral;