library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity cards is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic; 
        reqCarta : in  std_logic; 
        reqManual : in  std_logic; 
        cartaManual : in  std_logic_vector(3 downto 0);
        cartaFinal : out std_logic_vector(3 downto 0) 
    );
end cards;

architecture Behavioral of cards is
    type state_type is (idle, geraCarta,leCarta);
    signal current_state : state_type; 
    signal lfsr : std_logic_vector(15 downto 0) := "1010110010100000";  -- SEED
    signal rnd_int : integer range 1 to 52; 
    signal random_number, cartaGerada : std_logic_vector(3 downto 0);
begin

    process(clk, reset)
    begin
        if reset = '0' then
            lfsr <= "1110110010101110"; -- volta pra seed original
            current_state <= idle;
        elsif falling_edge(clk) then
            case current_state is
            when idle =>
                if reqCarta = '1' then
                    current_state <= geraCarta;
                else
                    current_state <= idle; 
                end if;
            when geraCarta => -- add transicao de rand de volta para idle
                if reqManual = '0' then 
                    lfsr <= lfsr(14 downto 0) & 
                    (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
                    rnd_int <= (to_integer(unsigned(lfsr)) mod 13) + 1;
                    random_number <= std_logic_vector(to_unsigned(rnd_int, 4));
                end if;
                    current_state <= leCarta;
                when leCarta =>
                    current_state <= idle;
				when others => null;
            end case;
        end if;
    end process;
    
    process(current_state)
    begin
        case current_state is 
            when idle =>
                cartaFinal <= (others => '0'); --correcao da atribuicao da carta na saida
            when geraCarta =>
                if reqManual = '0' then
                    cartaFinal <= random_number;
                else
                    cartaFinal(0) <= cartaManual(0);
                    cartaFinal(1) <= cartaManual(1);
                    cartaFinal(2) <= cartaManual(2);
                    cartaFinal(3) <= cartaManual(3);                    
                end if;
			when others => null;
        end case;
    end process;

end Behavioral;