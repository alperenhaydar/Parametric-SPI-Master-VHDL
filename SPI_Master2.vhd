----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Alperen
-- 
-- Create Date: 28.03.2026 17:39:45
-- Design Name: 
-- Module Name: SPI_Master2 - 
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

entity SPI_Master2 is
    generic (
        DATA_WIDTH        : positive := 8;
        SPI_MODE          : integer  := 0;  -- 0,1,2,3
        CLKS_PER_HALF_BIT : positive := 8
    );
    port (
        i_Clk      : in  std_logic;
        i_Rst_L    : in  std_logic;

        -- User Interface
        i_TX_Byte  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        i_TX_DV    : in  std_logic;
        o_TX_Ready : out std_logic;
        o_RX_Byte  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        o_RX_DV    : out std_logic;

        -- SPI Interface
        o_SPI_Clk  : out std_logic;
        o_SPI_CS   : out std_logic;
        o_SPI_MOSI : out std_logic;
        i_SPI_MISO : in  std_logic
    );
end entity SPI_Master2;

architecture RTL of SPI_Master2 is

    type t_state is (IDLE, TRANSFER, CLEANUP);
    signal r_State : t_state := IDLE;

    function f_get_cpol(mode : integer) return std_logic is
    begin
        if (mode = 2) or (mode = 3) then
            return '1';
        else
            return '0';
        end if;
    end function;

    function f_get_cpha(mode : integer) return std_logic is
    begin
        if (mode = 1) or (mode = 3) then
            return '1';
        else
            return '0';
        end if;
    end function;

    constant c_CPOL : std_logic := f_get_cpol(SPI_MODE);
    constant c_CPHA : std_logic := f_get_cpha(SPI_MODE);

    signal r_SPI_Clk   : std_logic := c_CPOL;
    signal r_Clk_Count : integer range 0 to CLKS_PER_HALF_BIT-1 := 0;

    signal r_TX_Shift  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal r_RX_Shift  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal r_Bit_Index : integer range 0 to DATA_WIDTH-1 := 0;

    signal r_SPI_CS    : std_logic := '1';
    signal r_SPI_MOSI  : std_logic := '0';
    signal r_TX_Ready  : std_logic := '1';
    signal r_RX_DV     : std_logic := '0';
    signal r_RX_Byte   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin

    assert (SPI_MODE >= 0 and SPI_MODE <= 3)
        report "SPI_MODE must be 0, 1, 2 or 3"
        severity failure;

    o_SPI_Clk  <= r_SPI_Clk;
    o_SPI_CS   <= r_SPI_CS;
    o_SPI_MOSI <= r_SPI_MOSI;
    o_TX_Ready <= r_TX_Ready;
    o_RX_DV    <= r_RX_DV;
    o_RX_Byte  <= r_RX_Byte;

    process(i_Clk, i_Rst_L)
        variable v_rx_next : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        if i_Rst_L = '0' then
            r_State     <= IDLE;
            r_SPI_Clk   <= c_CPOL;
            r_Clk_Count <= 0;
            r_TX_Shift  <= (others => '0');
            r_RX_Shift  <= (others => '0');
            r_Bit_Index <= 0;
            r_SPI_CS    <= '1';
            r_SPI_MOSI  <= '0';
            r_TX_Ready  <= '1';
            r_RX_DV     <= '0';
            r_RX_Byte   <= (others => '0');

        elsif rising_edge(i_Clk) then
            r_RX_DV <= '0';

            case r_State is

                when IDLE =>
                    r_SPI_CS    <= '1';
                    r_SPI_Clk   <= c_CPOL;
                    r_Clk_Count <= 0;
                    r_TX_Ready  <= '1';
                    r_SPI_MOSI  <= '0';
                    r_RX_Shift  <= (others => '0');
                    r_Bit_Index <= 0;

                    if i_TX_DV = '1' then
                        r_State     <= TRANSFER;
                        r_TX_Ready  <= '0';
                        r_SPI_CS    <= '0';
                        r_SPI_Clk   <= c_CPOL;
                        r_Clk_Count <= 0;
                        r_RX_Shift  <= (others => '0');
                        r_Bit_Index <= 0;

                        if c_CPHA = '0' then
                            -- Ýlk bit hemen hatta çýkar
                            r_SPI_MOSI <= i_TX_Byte(DATA_WIDTH-1);

                            -- Kalan bitler shift register'da tutulur
                            if DATA_WIDTH > 1 then
                                r_TX_Shift <= i_TX_Byte(DATA_WIDTH-2 downto 0) & '0';
                            else
                                r_TX_Shift <= (others => '0');
                            end if;
                        else
                            -- Ýlk bit ilk shift edge'inde çýkar
                            r_SPI_MOSI <= '0';
                            r_TX_Shift <= i_TX_Byte;
                        end if;
                    end if;

                when TRANSFER =>
                    r_TX_Ready <= '0';
                    r_SPI_CS   <= '0';

                    if r_Clk_Count = CLKS_PER_HALF_BIT-1 then
                        r_Clk_Count <= 0;

                        -- Clock hangi seviyedeyse, oluþacak edge ona göre belirlenir
                        if r_SPI_Clk = c_CPOL then
                            ------------------------------------------------
                            -- LEADING EDGE
                            ------------------------------------------------
                            r_SPI_Clk <= not r_SPI_Clk;

                            if c_CPHA = '0' then
                                -- Mode 0/2: leading edge'de sample
                                if DATA_WIDTH > 1 then
                                    v_rx_next := r_RX_Shift(DATA_WIDTH-2 downto 0) & i_SPI_MISO;
                                else
                                    v_rx_next := (others => i_SPI_MISO);
                                end if;

                                r_RX_Shift <= v_rx_next;

                                if r_Bit_Index = DATA_WIDTH-1 then
                                    r_RX_Byte <= v_rx_next;
                                    r_State   <= CLEANUP;
                                end if;

                            else
                                -- Mode 1/3: leading edge'de shift
                                r_SPI_MOSI <= r_TX_Shift(DATA_WIDTH-1);

                                if DATA_WIDTH > 1 then
                                    r_TX_Shift <= r_TX_Shift(DATA_WIDTH-2 downto 0) & '0';
                                else
                                    r_TX_Shift <= (others => '0');
                                end if;
                            end if;

                        else
                            ------------------------------------------------
                            -- TRAILING EDGE
                            ------------------------------------------------
                            r_SPI_Clk <= not r_SPI_Clk;

                            if c_CPHA = '0' then
                                -- Mode 0/2: trailing edge'de bir sonraki bit hazýrlanýr
                                if r_Bit_Index < DATA_WIDTH-1 then
                                    r_Bit_Index <= r_Bit_Index + 1;
                                    r_SPI_MOSI  <= r_TX_Shift(DATA_WIDTH-1);

                                    if DATA_WIDTH > 1 then
                                        r_TX_Shift <= r_TX_Shift(DATA_WIDTH-2 downto 0) & '0';
                                    else
                                        r_TX_Shift <= (others => '0');
                                    end if;
                                end if;

                            else
                                -- Mode 1/3: trailing edge'de sample
                                if DATA_WIDTH > 1 then
                                    v_rx_next := r_RX_Shift(DATA_WIDTH-2 downto 0) & i_SPI_MISO;
                                else
                                    v_rx_next := (others => i_SPI_MISO);
                                end if;

                                r_RX_Shift <= v_rx_next;

                                if r_Bit_Index = DATA_WIDTH-1 then
                                    r_RX_Byte <= v_rx_next;
                                    r_State   <= CLEANUP;
                                else
                                    r_Bit_Index <= r_Bit_Index + 1;
                                end if;
                            end if;
                        end if;

                    else
                        r_Clk_Count <= r_Clk_Count + 1;
                    end if;

                when CLEANUP =>
                    r_SPI_CS   <= '1';
                    r_SPI_Clk  <= c_CPOL;
                    r_SPI_MOSI <= '0';
                    r_RX_DV    <= '1';
                    r_TX_Ready <= '1';
                    r_State    <= IDLE;

            end case;
        end if;
    end process;

end architecture RTL;