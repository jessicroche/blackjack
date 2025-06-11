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
        random_number : out std_logic_vector(3 downto 0) 
    );
end cards;

architecture Behavioral of cards is
    type state_type is (idle, rand, read, manual);
    signal current_state : state_type; 
    signal next_state    : state_type;
    signal lfsr : std_logic_vector(15 downto 0) := "1010110010100000";  -- SEED
    signal rnd_int : integer range 1 to 52; 
    signal cartaGerada : std_logic_vector(3 downto 0); 
    signal lfsrenable : std_logic; 
begin

    process(current_state, reqCarta, reqManual, cartaManual,rnd_int)
    begin
        next_state <= current_state; 
        cartaGerada <= (others => '0');
        lfsrenable <= '0'; 
        case current_state is
            when idle =>
                if reqCarta = '1' and reqManual='0' then
                    next_state <= rand;
                    lfsrenable <= '1'; 
                elsif reqCarta='1' and reqManual = '1' then
                    next_state <= manual;
                    lfsrenable <= '0';  
                else
                    next_state <= idle; 
                end if;

            when rand =>
                next_state <= read;
                cartaGerada <= std_logic_vector(to_unsigned(rnd_int, 4)); 

            when read =>
                if reqManual = '0' then 
                    cartaGerada <= std_logic_vector(to_unsigned(rnd_int, 4));
                else 
                    cartaGerada <= cartaManual;
                end if;
                if reqCarta = '0' then
                    next_state <= idle; 
                else
                    next_state <= read;
                end if;

            when manual =>
                cartaGerada <= cartaManual; 
                next_state <= read;

            when others =>
                next_state <= idle; 

        end case;
    end process;

    rnd_int <= (to_integer(unsigned(lfsr)) mod 13)+1; -- Generate a number between 1 and 13
    process(clk, reset)
    begin
        if reset = '1' then
            lfsr <= "1110110010101110";
            current_state <= idle;
        elsif falling_edge(clk) then
            current_state <= next_state;
            if lfsrenable = '1' then
                lfsr <= lfsr(14 downto 0) & 
                (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
            end if;
        end if;
    end process;

    random_number <= cartaGerada;
    
end Behavioral;