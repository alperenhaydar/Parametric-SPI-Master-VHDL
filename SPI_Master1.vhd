----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.03.2026 20:05:04
-- Design Name: 
-- Module Name: SPI_Master1 - Behavioral
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

entity SPI_Master1 is
    generic (
        DATA_WIDTH        : integer := 8;    
        SPI_MODE          : integer := 0;    
        CLKS_PER_HALF_BIT : integer := 4     -- SPI Clock hýzý = i_Clk / (2 * CLKS_PER_HALF_BIT)
    );
    port (
        i_Clk       : in  std_logic;
        i_Rst_L     : in  std_logic;
        -- User Interface
        i_TX_Byte   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        i_TX_DV     : in  std_logic;         
        o_TX_Ready  : out std_logic;         
        o_RX_Byte   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        o_RX_DV     : out std_logic;         
        -- SPI Interface
        o_SPI_Clk   : out std_logic;
        o_SPI_CS    : out std_logic;
        o_SPI_MOSI  : out std_logic;
        i_SPI_MISO  : in  std_logic
    );
end entity SPI_Master1;

architecture RTL of SPI_Master1 is

    type t_SM_State is (IDLE, LOAD, TRANSFER, DONE);
    signal r_SM_Main : t_SM_State;

    -- SPI Mode Config
    signal w_CPOL : std_logic;
    signal w_CPHA : std_logic;

    -- Internal Signals
    signal r_SPI_Clk       : std_logic;
    signal r_SPI_Clk_Count : integer range 0 to CLKS_PER_HALF_BIT;
    signal r_Edges_Count   : integer range 0 to (DATA_WIDTH * 2);
    signal r_TX_Shift      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_RX_Shift      : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    -- Edge Detection
    signal w_Leading_Edge  : std_logic;
    signal w_Trailing_Edge : std_logic;

begin

    -- CPOL/CPHA Belirleme
    w_CPOL <= '1' when (SPI_MODE = 2 or SPI_MODE = 3) else '0';
    w_CPHA <= '1' when (SPI_MODE = 1 or SPI_MODE = 3) else '0';

    process(i_Clk, i_Rst_L)
    begin
        if i_Rst_L = '0' then
            r_SM_Main       <= IDLE;
            o_TX_Ready      <= '0';
            o_RX_DV         <= '0';
            o_RX_Byte       <= (others => '0');
            o_SPI_MOSI      <= '0';
            o_SPI_CS        <= '1';
            r_SPI_Clk       <= w_CPOL; -- Reset anýnda CPOL ile tam eþleþme
            r_SPI_Clk_Count <= 0;
            r_Edges_Count   <= 0;
            r_TX_Shift      <= (others => '0');
            r_RX_Shift      <= (others => '0');
        elsif rising_edge(i_Clk) then
            
            -- Default pulse signals
            o_RX_DV <= '0';

            case r_SM_Main is

                when IDLE =>
                    o_TX_Ready      <= '1';
                    o_SPI_CS        <= '1';
                    o_SPI_MOSI      <= '0'; 
                    r_SPI_Clk       <= w_CPOL; -- Idle anýnda clock CPOL seviyesinde
                    r_SPI_Clk_Count <= 0;
                    r_Edges_Count   <= 0;

                    if i_TX_DV = '1' then
                        r_TX_Shift <= i_TX_Byte;
                        o_TX_Ready <= '0';
                        r_SM_Main  <= LOAD;
                    end if;

                when LOAD =>
                    o_SPI_CS <= '0'; -- CS aktifleþir
                    -- CPHA=0 senaryosu: Ýlk bit clock gelmeden MOSI'de olmalý
                    if w_CPHA = '0' then
                        o_SPI_MOSI <= r_TX_Shift(DATA_WIDTH-1);
                    end if;
                    r_SM_Main <= TRANSFER;

                when TRANSFER =>
                    -- SPI Clock Üretimi
                    if r_SPI_Clk_Count = CLKS_PER_HALF_BIT - 1 then
                        r_SPI_Clk_Count <= 0;
                        r_Edges_Count   <= r_Edges_Count + 1;
                        r_SPI_Clk       <= not r_SPI_Clk; -- Kenar oluþtu (Leading veya Trailing)
                        
                        -- KENAR MANTIÐI VE VERÝ ÝÞLEME
                        -- 1. Kenar Tespiti
                        -- r_Edges_Count tek ise Leading, çift ise Trailing (Genellikle)
                        
                        -- MOSI GÜNCELLEME (SHIFTING)
                        if w_CPHA = '0' then
                            -- CPHA=0: Trailing Edge'de kaydýr (Leading'de örnekleme yapýldýðý için)
                            if (r_SPI_Clk = not w_CPOL) then -- Bu kenar Trailing Edge'dir
                                if r_Edges_Count < (DATA_WIDTH * 2) then
                                    r_TX_Shift <= r_TX_Shift(DATA_WIDTH-2 downto 0) & '0';
                                    o_SPI_MOSI <= r_TX_Shift(DATA_WIDTH-2);
                                end if;
                            end if;
                        else
                            -- CPHA=1: Leading Edge'de kaydýr (Ýlk bit dahil)
                            if (r_SPI_Clk = w_CPOL) then -- Bu kenar Leading Edge'dir
                                o_SPI_MOSI <= r_TX_Shift(DATA_WIDTH-1);
                                r_TX_Shift <= r_TX_Shift(DATA_WIDTH-2 downto 0) & '0';
                            end if;
                        end if;

                        -- MISO ÖRNEKLEME (SAMPLING)
                        if w_CPHA = '0' then
                            -- CPHA=0: Leading Edge'de örnekle
                            if (r_SPI_Clk = w_CPOL) then
                                r_RX_Shift <= r_RX_Shift(DATA_WIDTH-2 downto 0) & i_SPI_MISO;
                            end if;
                        else
                            -- CPHA=1: Trailing Edge'de örnekle
                            if (r_SPI_Clk /= w_CPOL) then
                                r_RX_Shift <= r_RX_Shift(DATA_WIDTH-2 downto 0) & i_SPI_MISO;
                            end if;
                        end if;

                    else
                        r_SPI_Clk_Count <= r_SPI_Clk_Count + 1;
                    end if;

                    -- Transfer Bitiþ Kontrolü
                    if r_Edges_Count = (DATA_WIDTH * 2) then
                        r_SM_Main <= DONE;
                    end if;

                when DONE =>
                    o_SPI_CS   <= '1';
                    o_RX_Byte  <= r_RX_Shift;
                    o_RX_DV    <= '1';
                    r_SM_Main  <= IDLE;

                when others =>
                    r_SM_Main <= IDLE;
            end case;
        end if;
    end process;

    o_SPI_Clk <= r_SPI_Clk;

end architecture RTL;
