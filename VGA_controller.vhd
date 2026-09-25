library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA_controller is
  port (
    CLK_24MHz : in std_logic;
    VS        : out std_logic;
    HS        : out std_logic;
    RED       : out std_logic_vector(1 downto 0);
    GREEN     : out std_logic_vector(1 downto 0);
    BLUE      : out std_logic_vector(1 downto 0);
    RESET     : in std_logic;
    ColorIN   : in std_logic_vector(5 downto 0);
    ScanlineX : out std_logic_vector(10 downto 0);
    ScanlineY : out std_logic_vector(10 downto 0)
  );
end VGA_controller;

architecture Behavioral of VGA_controller is

  -- VGA 640x480 @ 60Hz timing parameters
  constant HDisplayArea : integer := 640;
  constant HLimit       : integer := 800;
  constant HFrontPorch  : integer := 16;
  constant HBackPorch   : integer := 48;
  constant HSyncWidth   : integer := 96;

  constant VDisplayArea : integer := 480;
  constant VLimit       : integer := 525;
  constant VFrontPorch  : integer := 10;
  constant VBackPorch   : integer := 33;
  constant VSyncWidth   : integer := 2;

  signal HBlank, VBlank, Blank : std_logic := '0';

  signal CurrentHPos : std_logic_vector(10 downto 0) := (others => '0');
  signal CurrentVPos : std_logic_vector(10 downto 0) := (others => '0');

begin

  --------------------------------------------------------------------
  -- Horizontal & Vertical Counters
  --------------------------------------------------------------------
  VGAPosition : process (CLK_24MHz, RESET)
  begin
    if RESET = '1' then
      CurrentHPos <= (others => '0');
      CurrentVPos <= (others => '0');

    elsif rising_edge(CLK_24MHz) then
      if CurrentHPos < HLimit - 1 then
        CurrentHPos <= CurrentHPos + 1;
      else
        CurrentHPos <= (others => '0');
        if CurrentVPos < VLimit - 1 then
          CurrentVPos <= CurrentVPos + 1;
        else
          CurrentVPos <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Sync Signals
  --------------------------------------------------------------------
  HS <= '0' when CurrentHPos < HSyncWidth else '1';
  VS <= '0' when CurrentVPos < VSyncWidth else '1';

  --------------------------------------------------------------------
  -- Blanking
  --------------------------------------------------------------------
  HBlank <= '0' when
    (CurrentHPos >= HSyncWidth + HFrontPorch) and
    (CurrentHPos <  HSyncWidth + HFrontPorch + HDisplayArea)
    else '1';

  VBlank <= '0' when
    (CurrentVPos >= VSyncWidth + VFrontPorch) and
    (CurrentVPos <  VSyncWidth + VFrontPorch + VDisplayArea)
    else '1';

  Blank <= '1' when (HBlank = '1' or VBlank = '1') else '0';

  --------------------------------------------------------------------
  -- Visible Scan Coordinates
  --------------------------------------------------------------------
  ScanlineX <= CurrentHPos - HSyncWidth - HFrontPorch when Blank = '0'
               else (others => '0');

  ScanlineY <= CurrentVPos - VSyncWidth - VFrontPorch when Blank = '0'
               else (others => '0');

  --------------------------------------------------------------------
  -- RGB Output
  --------------------------------------------------------------------
  RED   <= ColorIN(5 downto 4) when Blank = '0' else "00";
  GREEN <= ColorIN(3 downto 2) when Blank = '0' else "00";
  BLUE  <= ColorIN(1 downto 0) when Blank = '0' else "00";

end Behavioral;
