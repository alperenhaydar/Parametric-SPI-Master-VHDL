----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Alperen
-- 
-- Create Date: 28.03.2026 17:51:03
-- Design Name: 
-- Module Name: tb_SPI_Master2 - Behavioral
-- Project Name: Parametric SPI Master
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

entity tb_SPI_Master2 is
end entity;

architecture sim of tb_SPI_Master2 is

    signal s_Clk      : std_logic := '0';
    signal s_Rst_L    : std_logic := '0';

    signal s_TX_Byte  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_TX_DV    : std_logic := '0';
    signal s_TX_Ready : std_logic;
    signal s_RX_Byte  : std_logic_vector(7 downto 0);
    signal s_RX_DV    : std_logic;

    signal s_SPI_Clk  : std_logic;
    signal s_SPI_CS   : std_logic;
    signal s_SPI_MOSI : std_logic;
    signal s_SPI_MISO : std_logic;

begin

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    DUT : entity work.SPI_Master2
        generic map (
            DATA_WIDTH        => 8,
            SPI_MODE          => 0,
            CLKS_PER_HALF_BIT => 8
        )
        port map (
            i_Clk      => s_Clk,
            i_Rst_L    => s_Rst_L,
            i_TX_Byte  => s_TX_Byte,
            i_TX_DV    => s_TX_DV,
            o_TX_Ready => s_TX_Ready,
            o_RX_Byte  => s_RX_Byte,
            o_RX_DV    => s_RX_DV,
            o_SPI_Clk  => s_SPI_Clk,
            o_SPI_CS   => s_SPI_CS,
            o_SPI_MOSI => s_SPI_MOSI,
            i_SPI_MISO => s_SPI_MISO
        );

    --------------------------------------------------------------------
    -- CLOCK (50 MHz)
    --------------------------------------------------------------------
    p_clk : process
    begin
        while true loop
            s_Clk <= '0';
            wait for 10 ns;
            s_Clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- LOOPBACK
    --------------------------------------------------------------------
    s_SPI_MISO <= s_SPI_MOSI;

    --------------------------------------------------------------------
    -- STIMULUS
    --------------------------------------------------------------------
    p_stimulus : process
    begin
        s_TX_DV   <= '0';
        s_TX_Byte <= (others => '0');

        -- RESET
        s_Rst_L <= '0';
        wait for 200 ns;
        s_Rst_L <= '1';
        wait for 200 ns;

        ----------------------------------------------------------------
        -- 1. TRANSFER
        ----------------------------------------------------------------
        wait until rising_edge(s_Clk);
        while s_TX_Ready /= '1' loop
            wait until rising_edge(s_Clk);
        end loop;

        s_TX_Byte <= x"A5";
        s_TX_DV   <= '1';
        wait until rising_edge(s_Clk);
        s_TX_DV   <= '0';

        wait until rising_edge(s_Clk);
        while s_RX_DV /= '1' loop
            wait until rising_edge(s_Clk);
        end loop;

        assert s_RX_Byte = x"A5"
            report "Loopback 1 FAIL"
            severity error;

        wait for 500 ns;

        ----------------------------------------------------------------
        -- 2. TRANSFER
        ----------------------------------------------------------------
        wait until rising_edge(s_Clk);
        while s_TX_Ready /= '1' loop
            wait until rising_edge(s_Clk);
        end loop;

        s_TX_Byte <= x"5A";
        s_TX_DV   <= '1';
        wait until rising_edge(s_Clk);
        s_TX_DV   <= '0';

        wait until rising_edge(s_Clk);
        while s_RX_DV /= '1' loop
            wait until rising_edge(s_Clk);
        end loop;

        assert s_RX_Byte = x"5A"
            report "Loopback 2 FAIL"
            severity error;

        ----------------------------------------------------------------
        -- DONE
        ----------------------------------------------------------------
        report "LOOPBACK TEST PASSED" severity note;

        wait;
    end process;

end architecture;