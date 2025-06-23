library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity cards is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic; 
        reqCard    : in  std_logic; 
        reqManual   : in  std_logic; 
        cardManual : in  std_logic_vector(3 downto 0);
        cardFinal  : out std_logic_vector(3 downto 0) 
    );
end cards;

architecture Behavioral of cards is
    type state_type is (idle, generateCard, readCard);
    signal current_state : state_type; 
    signal lfsr : std_logic_vector(15 downto 0) := "1010110010100000";  -- SEED
    signal rnd_int : integer range 1 to 52; 
    signal random_number : std_logic_vector(3 downto 0);
begin

    process(clk, reset)
    begin
        if reset = '0' then
            lfsr <= "1110110010101110"; -- volta pra seed original
            current_state <= idle;
        elsif falling_edge(clk) then
            case current_state is
                when idle =>
                    if reqCard = '1' then
                        current_state <= generateCard;
                    else
                        current_state <= idle; 
                    end if;

                when generateCard =>
                    if reqManual = '0' then 
                        lfsr <= lfsr(14 downto 0) & 
                            (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
                        rnd_int <= (to_integer(unsigned(lfsr)) mod 13) + 1;
                        random_number <= std_logic_vector(to_unsigned(rnd_int, 4));
                    end if;
                    current_state <= readCard;

                when readCard =>
                    current_state <= idle;

                when others => null;
            end case;
        end if;
    end process;
    
    process(current_state)
    begin
        case current_state is 
            when idle =>
                cardFinal <= (others => '0'); -- zera

            when readCard =>
                if reqManual = '0' then
                    cardFinal <= random_number;
                else
                    cardFinal(0) <= cardManual(0);
                    cardFinal(1) <= cardManual(1);
                    cardFinal(2) <= cardManual(2);
                    cardFinal(3) <= cardManual(3);
                end if;

            when others => null;
        end case;
    end process;
end Behavioral;
