library ieee;
use ieee.std_logic_1164.all;

entity implementacao is
    port (
        clk     : in  std_logic; -- Clock signal
        start   : in  std_logic; -- Reset signal      
        hit    : in  std_logic; -- Hit signal
        stay    : in  std_logic; -- Stay signal
        reqCarta : in  std_logic; -- Request for a card
        reqManual : in  std_logic; -- Request for manual card input
        cartaManual : in  std_logic_vector(3 downto 0); -- Manual card input
        Pwin : out std_logic; -- Player win signal
        Plose : out std_logic; -- Player lose signal
        TIE : out std_logic; -- Tie signal
        hexCard : out std_logic_vector(3 downto 0); -- Card output
        sumDecimal : out std_logic_vector(7 downto 0) -- Sum output
     );
end implementacao;

architecture Behavioral of implementacao is
    signal cards_req : std_logic; -- Card request signal
    signal card_reset : std_logic; -- Card reset signal
    begin
        cards_inst : entity work.cards
            port map (
                clk => clk,
                reset => start,
                reqCarta => cards_req,
                reqManual => reqManual,
                cartaManual => cartaManual,
                random_number => hexCard
            );
        blackjack_inst : entity work.blackjack
            port map (
                HIT => hit,
                STAY => stay,
                START => start,
                CLK => clk,
                CARD => hexCard,
                REQCARD => cards_req,
                PWIN => Pwin,
                PLOSE => Plose,
                TIE => TIE,
                hexCard => hexCard,
                sumDecimal => sumDecimal
            );
end Behavioral;