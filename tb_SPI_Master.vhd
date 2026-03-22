----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.03.2026 15:28:09
-- Design Name: 
-- Module Name: tb_SPI_Master - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_SPI_Master is
end entity;

architecture behavior of tb_SPI_Master is
    constant DATA_WIDTH : integer := 8;
    signal i_Clk        : std_logic := '0';
    signal i_Rst_L      : std_logic := '0';
    signal i_TX_Byte    : std_logic_vector(7 downto 0) := (others => '0');
    signal i_TX_DV      : std_logic := '0';
    signal o_TX_Ready   : std_logic;
    signal o_RX_Byte    : std_logic_vector(7 downto 0);
    signal o_RX_DV      : std_logic;
    signal o_SPI_Clk    : std_logic;
    signal o_SPI_CS     : std_logic;
    signal o_SPI_MOSI   : std_logic;
    signal i_SPI_MISO   : std_logic := '0';

    constant TX_DATA    : std_logic_vector(7 downto 0) := x"AA"; -- 10101010
    constant RX_DATA    : std_logic_vector(7 downto 0) := x"CC"; -- 11001100
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Clock Generation
    i_Clk <= not i_Clk after CLK_PERIOD/2;

    -- DUT (Genericleri tam tanýmla!)
    DUT: entity work.SPI_Master1
        generic map (
            DATA_WIDTH => 8,
            SPI_MODE => 0, -- Mode 0 testi
            CLKS_PER_HALF_BIT => 4
        )
        port map (
            i_Clk => i_Clk, i_Rst_L => i_Rst_L, i_TX_Byte => i_TX_Byte,
            i_TX_DV => i_TX_DV, o_TX_Ready => o_TX_Ready, o_RX_Byte => o_RX_Byte,
            o_RX_DV => o_RX_DV, o_SPI_Clk => o_SPI_Clk, o_SPI_CS => o_SPI_CS,
            o_SPI_MOSI => o_SPI_MOSI, i_SPI_MISO => i_SPI_MISO
        );

    -- MISO Simülasyonu (Loop içinde olmalý)
    process
        variable bit_idx : integer := 7;
    begin
        loop
            wait until falling_edge(o_SPI_CS);
            bit_idx := 7;
            i_SPI_MISO <= RX_DATA(bit_idx); -- MSB
            while o_SPI_CS = '0' loop
                wait until falling_edge(o_SPI_Clk);
                if bit_idx > 0 then
                    bit_idx := bit_idx - 1;
                    i_SPI_MISO <= RX_DATA(bit_idx);
                end if;
            end loop;
        end loop;
    end process;

    -- Test Sequence
    process
    begin
        -- 1. Reset
        i_Rst_L <= '0';
        wait for 100 ns;
        i_Rst_L <= '1';
        wait for 100 ns;

        -- 2. Ready Bekle ve Gönder
        wait until falling_edge(i_Clk) and o_TX_Ready = '1';
        i_TX_Byte <= TX_DATA;
        i_TX_DV   <= '1';
        wait for CLK_PERIOD;
        i_TX_DV   <= '0';

        -- 3. Sonucu Bekle
        wait until o_RX_DV = '1';
       
        
        wait for 200 ns;
        assert (o_RX_Byte = RX_DATA) report "HATA: Veri yanlis!" severity failure;
        report "BASARILI: Veri dogru.";
        
        wait;
    end process;

end architecture;