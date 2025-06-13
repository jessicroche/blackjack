library ieee;
use ieee.std_logic_1164.all;

entity implementacao is
    port (
        clk         : in  std_logic;
        start       : in  std_logic;
        hit         : in  std_logic;
        stay        : in  std_logic;
        reqManual   : in  std_logic;
        cartaManual : in  std_logic_vector(3 downto 0);
        Pwin        : out std_logic;
        Plose       : out std_logic;
        TIE         : out std_logic;
        hex_card    : out std_logic_vector(7 downto 0);
        sum1_dec    : out std_logic_vector(7 downto 0);
        sum2_dec    : out std_logic_vector(7 downto 0)
    );
end implementacao;

architecture Behavioral of implementacao is

    signal cards_req   : std_logic;
    signal hexCard_int : std_logic_vector(3 downto 0);
    signal sum1_int    : std_logic_vector(7 downto 0);
    signal sum2_int    : std_logic_vector(7 downto 0);
begin
    cards_inst : entity work.cards
        port map (
            clk         => clk,
            reset       => start,
            reqCarta    => cards_req,
            reqManual   => reqManual,
            cartaManual => cartaManual,
            random_number => hexCard_int
        );

    blackjack_inst : entity work.blackjack
        port map (
            HIT        => hit,
            STAY       => stay,
            START      => start,
            CLK        => clk,
            CARD       => hexCard_int,
            REQCARD    => cards_req,
            PWIN       => Pwin,
            PLOSE      => Plose,
            TIE        => TIE,
            hexCard    => hex_card,
            sumDigit1  => sum1_int,
            sumDigit2  => sum2_int
        );

    hex_card  <= hexCard_int;
    sum1_dec  <= sum1_int;
    sum2_dec  <= sum2_int;
end Behavioral;