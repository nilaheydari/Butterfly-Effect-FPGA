library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TopLevel is
Port(
    CLOCK_24 : in std_logic;
    RESET_N  : in std_logic;
    PB       : in std_logic_vector(3 downto 0); -- ???????

    VGA_HS :  out std_logic;
    VGA_VS : out std_logic;
    VGA_R  : out std_logic_vector(1 downto 0);
    VGA_G  : out std_logic_vector(1 downto 0);
    VGA_B  : out std_logic_vector(1 downto 0);

    Leds : out std_logic_vector(7 downto 0);
    an : out bit_vector(3 downto 0);
    sseg : out bit_vector(7 downto 0)
);
end TopLevel; 

 architecture Behavioral of TopLevel is

component VGA_controller
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
end component;

-- ================= Constants =================
constant X_MIN : integer := 200;
constant X_MAX : integer := 440; 
constant Y_MIN : integer := 140;
constant Y_MAX : integer := 340;
constant THICK : integer := 16;


constant W_PATH : integer := X_MAX - X_MIN;
constant H_PATH : integer := Y_MAX - Y_MIN;

constant L1 : integer := W_PATH;
constant L2 : integer := W_PATH + H_PATH;
constant L3 : integer := W_PATH + H_PATH + W_PATH;
constant PATH_LEN_NEW : integer := 2*W_PATH + 2*H_PATH;

constant MAX_BALLS : integer := 12;
constant BALL_GAP  : integer := 2;
constant PATH_LEN  : integer := 1520;
constant HOLE_RADIUS : integer := 6;
constant BALL_RADIUS : integer := 6;  -- ??????? ?? ???
constant CHAIN_SPEED : integer := 8_000_000; 
-- ???? 0.1 ?????

-- Shooter position
constant SHOOTER_X : integer := 280;  -- ??? ????
constant SHOOTER_Y : integer := 420;  -- ????? ???? (??? ????)
constant SHOT_SPEED : integer := 8;
constant SHOT_MOVE_SPEED : integer := 500_000;

-- ===== 7-segment codes (Active-Low) =====
constant SEG_0 : bit_vector(7 downto 0) := "11000000";
constant SEG_8 : bit_vector(7 downto 0) := "10000000";
constant SEG_9 : bit_vector(7 downto 0) := "10010000";
-- ===== 7-seg letters (Active-Low) =====
constant SEG_B : bit_vector(7 downto 0) := "10000011"; -- b
constant SEG_O : bit_vector(7 downto 0) := "11000000"; -- 0 ? O
constant SEG_R : bit_vector(7 downto 0) := "10101111"; -- r
constant SEG_D : bit_vector(7 downto 0) := "10100001"; -- d

constant SEG_L : bit_vector(7 downto 0) := "11000111"; -- L
constant SEG_S : bit_vector(7 downto 0) := "10010010"; -- S
constant SEG_E : bit_vector(7 downto 0) := "10000110"; -- E

-- ================= Types =================
type int_array   is array (0 to MAX_BALLS-1) of integer range -3000 to 3000;
type color_array is array (0 to MAX_BALLS-1) of std_logic_vector(5 downto 0);
type bool_array  is array (0 to MAX_BALLS-1) of std_logic;

type angle_array is array (0 to 15) of integer;

-- ================= Signals =================
signal color : std_logic_vector(5 downto 0);
signal sx, sy : std_logic_vector(10 downto 0);
signal rst : std_logic;

signal spawn_count : integer range 0 to MAX_BALLS := 0;
signal head_index : integer range 0 to MAX_BALLS-1 := 0;

signal collapse_pending : std_logic := '0';

signal ball_idx     : int_array;
signal ball_c      : color_array;
signal ball_active : bool_array;

signal tick        : unsigned(23 downto 0) := (others => '0');
signal spawn_timer : unsigned(22 downto 0) := (others => '0');
signal spawn_done  : std_logic := '0';

-- Shooter
signal shooter_color : std_logic_vector(5 downto 0) := "110000";
signal shooter_dir : integer range 0 to 2 := 1; -- ???
signal fired_color : std_logic_vector(5 downto 0) := "110000";
signal shot_tick : unsigned(21 downto 0) := (others => '0');

signal insert_freeze : std_logic := '0';
signal freeze_timer  : unsigned(21 downto 0) := (others => '0');
constant FREEZE_TIME : integer := 1_500_000;
signal remove_pending : std_logic := '0';
signal remove_index   : integer range 0 to MAX_BALLS-1 := 0;


-- ================= Shot signals =================
signal shot_active : std_logic := '0';
signal shot_x      : integer range -1000 to 2000 := 0;
signal shot_y      : integer range -1000 to 2000 := 0;
signal shot_dx     : integer range -8 to 8 := 0;
signal shot_dy     : integer range -8 to 8 := 0;

signal shoot_prev  : std_logic := '1';

signal rand_reg : std_logic_vector(7 downto 0) := "10101010";

signal insert_pending : std_logic := '0';
signal insert_index   : integer range 0 to MAX_BALLS-1 := 0;
signal insert_color   : std_logic_vector(5 downto 0) := (others => '0');


  constant PATH_SIZE : integer := 40;

type path_array is array (0 to PATH_SIZE-1) of integer;

-- ===== Game State =====
type game_state_t is (PLAYING, WIN, LOSE);
signal game_state : game_state_t := PLAYING;



signal removed_count : integer range 0 to 100 := 0;
-- ??? ????
type shot_type_t is (NORMAL, BOMB_1, BOMB_3);
signal shot_type         : shot_type_t := NORMAL;
signal shot_type_latched : shot_type_t := NORMAL;
signal shot_type_next : shot_type_t := NORMAL;
signal preview_type : shot_type_t := NORMAL;

signal reward_3_given : std_logic := '0';
signal reward_6_given : std_logic := '0';


-- ??????? ????
signal shot_count : integer range 0 to 9 := 0;

-- ??????? ?? ??? ??????
signal collision_done : std_logic := '0';
-- ===== Bomb control signals =====
signal bomb_pending : std_logic := '0';
signal bomb_center  : integer range 0 to MAX_BALLS-1 := 0;
signal bomb_type    : shot_type_t := NORMAL;

-- ================= Path LUT (64 points, big rectangle) =================

constant path_x : path_array := (
-- top edge (left -> right) 10
240,248,256,264,272,280,288,296,304,312,

-- right edge (top -> bottom) 10
320,320,320,320,320,320,320,320,320,320,

-- bottom edge (right -> left) 10
312,304,296,288,280,272,264,256,248,240,

-- left edge (bottom -> top) 10
240,240,240,240,240,240,240,240,240,240
);

constant path_y : path_array := (
-- top edge
180,180,180,180,180,180,180,180,180,180,

-- right edge
188,196,204,212,220,228,236,244,252,260,

-- bottom edge
260,260,260,260,260,260,260,260,260,260,

-- left edge
252,244,236,228,220,212,204,196,188,180
);
function rand_color(r : std_logic_vector(2 downto 0))
return std_logic_vector is
begin
    case r is
        when "000" => return "110000"; -- red
        when "001" => return "111100"; -- yellow
        when "010" => return "000011"; -- blue
        when "011" => return "001100"; -- green
        when "100" => return "001111"; -- cyan (NEW)
        when others => return "110000"; -- fallback
    end case;
end function;

begin

rst <= not RESET_N;

-- ================= VGA =================
VGA_INST : VGA_controller
port map(
    CLK_24MHz => CLOCK_24,
    VS => VGA_VS,
    HS => VGA_HS,
    RED => VGA_R,
    GREEN => VGA_G,
    BLUE => VGA_B,
    RESET => rst,
    ColorIN => color,
    ScanlineX => sx,
    ScanlineY => sy
);

-- === ============== Main Logic =================
process(CLOCK_24)
  variable cbx, cby : integer;
    variable left  : integer;
    variable right : integer;
    variable count : integer;
    variable col   : std_logic_vector(5 downto 0);
	 variable bomb_removed : integer := 0;
begin
    if rising_edge(CLOCK_24) then
      if rst = '1' then
    -- timers
	 reward_3_given <= '0';
reward_6_given <= '0';

	 bomb_pending <= '0';
    tick <= (others => '0');
    spawn_timer <= (others => '0');
    shot_tick <= (others => '0');
	 
	 game_state   <= PLAYING;
    removed_count <= 0;

    -- game state
    spawn_count <= 0;
    insert_pending <= '0';
    remove_pending <= '0';
    collapse_pending <= '0';

    -- shooter
    shooter_dir <= 1;
    shooter_color <= "110000";
    shot_active <= '0';
    shoot_prev <= '1';
	 
	 shot_count        <= 0;
shot_type_latched <= NORMAL;
preview_type      <= NORMAL;

fired_color <= "110000" ;
    -- balls
    for i in 0 to MAX_BALLS-1 loop
        ball_active(i) <= '0';
        ball_idx(i) <= -1;
        ball_c(i) <= (others => '0');
    end loop;

        else
		  -- ================= Random update =================
rand_reg <= rand_reg(6 downto 0) & (rand_reg(7) xor rand_reg(5));
            tick <= tick + 1;
            spawn_timer <= spawn_timer + 1;
				shot_tick <= shot_tick + 1 ;
			
			

      -- ================= Shoot logic =================
-- ????? ??? ????
if PB(1) = '0' then
    shooter_dir <= 0; -- ??
elsif PB(3) = '0' then
    shooter_dir <= 1; -- ???
elsif PB(2) = '0' then
    shooter_dir <= 2; -- ????
end if;

-- ???? (????? ????)
-- ==== FIRE only on button edge ====
if shoot_prev = '1' and PB(0) = '0' then
    if shot_active = '0' and game_state = PLAYING then

-- ================= Latch shot type (ONLY HERE) =================

-- latch fired color for NORMAL shots
if preview_type = NORMAL then
    fired_color <= shooter_color;
end if;

shot_type_latched <= preview_type;
if preview_type /= NORMAL then
    preview_type <= NORMAL;
end if;

shot_active <= '1';
collision_done <= '0';

        shot_x <= SHOOTER_X;
        shot_y <= SHOOTER_Y - 8;

        -- ================= Shot direction =================
        case shooter_dir is
            when 0 =>  -- ??
                shot_dx <= -SHOT_SPEED;
                shot_dy <= -SHOT_SPEED;
            when 1 =>  -- ???
                shot_dx <= 0;
                shot_dy <= -SHOT_SPEED;
            when others => -- ????
                shot_dx <= SHOT_SPEED;
                shot_dy <= -SHOT_SPEED;
        end case;

        -- ================= Next shooter color =================
       shooter_color <= rand_color(rand_reg(6 downto 4));


    end if;
end if;

shoot_prev <= PB(0);

-- ================= Move balls on path (CHAIN + INSERT + EXIT) =================
if game_state = PLAYING then
  if tick >= CHAIN_SPEED then
    tick <= (others => '0');

    -- ===== INSERT PHASE (absolute freeze) =====
    if insert_pending = '1' then

        for j in MAX_BALLS-1 downto 1 loop
    if j > insert_index then
        ball_idx(j)    <= ball_idx(j-1);
        ball_c(j)      <= ball_c(j-1);
        ball_active(j) <= ball_active(j-1);
    end if;
end loop;
        ball_idx(insert_index)    <= ball_idx(insert_index) - BALL_GAP;
        ball_c(insert_index)      <= insert_color;
        ball_active(insert_index) <= '1';

        insert_pending <= '0';

    else
        -- ===== NORMAL CHAIN MOVE =====
        if ball_active(0) = '1' then
            ball_idx(0) <= ball_idx(0) + 1;
        end if;

        for i in 1 to MAX_BALLS-1 loop
            if ball_active(i) = '1' then
                if (ball_idx(i-1) - ball_idx(i)) > BALL_GAP then
                    ball_idx(i) <= ball_idx(i) + 1;
                end if;
            end if;
        end loop;

        -- exit hole
        if ball_active(0) = '1' and ball_idx(0) >= PATH_SIZE-1 then
		  game_state <= LOSE;
            ball_active(0) <= '0';
            ball_idx(0)    <= -2000;

            for i in 0 to MAX_BALLS-2 loop
                ball_idx(i)    <= ball_idx(i+1);
                ball_c(i)      <= ball_c(i+1);
                ball_active(i) <= ball_active(i+1);
            end loop;

            ball_active(MAX_BALLS-1) <= '0';
            ball_idx(MAX_BALLS-1)    <= -2000;
        end if;
    end if;
end if;
end if;
-- ================= Spawn balls (LIMITED) =================
if game_state = PLAYING then
    if spawn_timer >= 400000 then
	 if spawn_count < MAX_BALLS then
        spawn_timer <= (others => '0');
        ball_active(spawn_count) <= '1';
        ball_idx(spawn_count) <= -BALL_GAP;
       ball_c(spawn_count) <= rand_color(rand_reg(2 downto 0));

        spawn_count <= spawn_count + 1;
    end if;
end if;
end if;
-- ================= Collision & Insert =================-- ================= Collision & Decision =================
collision_done <= '0';

if shot_active = '1' then
    for i in 0 to MAX_BALLS-1 loop
        if ball_active(i) = '1' and ball_idx(i) >= 0 then

            -- ?????? ??? ??? ????
            cbx := path_x(ball_idx(i));
            cby := path_y(ball_idx(i));

            -- ????? ??????
            if (shot_x >= cbx-5 and shot_x <= cbx+5 and
                shot_y >= cby-5 and shot_y <= cby+5 and
                collision_done = '0') then

                collision_done <= '1';
                shot_active <= '0';

case shot_type_latched is

    when NORMAL =>
        insert_pending <= '1';
        insert_index   <= i;
        insert_color   <= fired_color;
        remove_pending <= '1';
        remove_index   <= i;

    when BOMB_1 =>
        -- ??? ????: ??? ??? ? ??
        bomb_pending <= '1';
        bomb_center  <= i;
        bomb_type    <= BOMB_1;

    when BOMB_3 =>
        -- ??? ??????: ??? ? ??? ???
        bomb_pending <= '1';
        bomb_center  <= i;
        bomb_type    <= BOMB_3;

end case;

                exit;  -- ??? ?? ??????
            end if;

        end if;
    end loop;
end if;
-- ================= Move shot ball (SLOW & VISIBLE) =================
if shot_active = '1' and shot_tick >= SHOT_MOVE_SPEED then
    shot_tick <= (others => '0');

    shot_x <= shot_x + shot_dx;
    shot_y <= shot_y + shot_dy;

    if shot_x < -20 or shot_x > 660 or
       shot_y < -20 or shot_y > 500 then
        shot_active <= '0';
    end if;
end if;
-- ================= Release insert freeze =================
-- ================= Release insert freeze =================
if remove_pending = '1' then

    case shot_type_latched is
    when NORMAL =>
        col := fired_color;
    when others =>
        col := (others => '0'); -- ????? ??? ????? ?????? ???? ??? ???? ??????
end case;
 
    if ball_c(remove_index) = col then

        left  := remove_index;
        right := remove_index;
        count := 2;

        -- scan left
        for k in 1 to MAX_BALLS-1 loop
            if left > 0 and ball_active(left-1) = '1' and ball_c(left-1) = col then
                left  := left - 1;
                count := count + 1;
            end if;
        end loop;

        -- scan right
        for k in 1 to MAX_BALLS-1 loop
            if right < MAX_BALLS-1 and ball_active(right+1) = '1' and ball_c(right+1) = col then
                right := right + 1;
                count := count + 1;
            end if;
        end loop;

      if count >= 3 then
   for i in 0 to MAX_BALLS-1 loop
    if i >= left and i <= right then
        ball_active(i) <= '0';
        ball_idx(i)    <= -2000;
    end if;
end loop;

    removed_count <= removed_count + count;
	 -- ===== Reward logic (NORMAL remove) =====
if removed_count + count >= 6 and reward_6_given = '0' then
    preview_type   <= BOMB_3;
    reward_6_given <= '1';

elsif removed_count + count >= 3 and reward_3_given = '0' then
    preview_type   <= BOMB_1;
    reward_3_given <= '1';
end if;


    if removed_count + count >= 8 then
        game_state <= WIN;
    end if;

    collapse_pending <= '1';
end if;

    end if;

    remove_pending <= '0';
end if;
-- ================= Bomb effect (delayed remove) =================
if bomb_pending = '1' then
    bomb_pending <= '0';
    bomb_removed := 0;

    case bomb_type is

        when BOMB_1 =>
            if bomb_center > 0 and ball_active(bomb_center-1) = '1' then
                ball_active(bomb_center-1) <= '0';
                ball_idx(bomb_center-1)    <= -2000;
                bomb_removed := bomb_removed + 1;
            end if;

            if ball_active(bomb_center) = '1' then
                ball_active(bomb_center) <= '0';
                ball_idx(bomb_center)    <= -2000;
                bomb_removed := bomb_removed + 1;
            end if;

            if bomb_center < MAX_BALLS-1 and ball_active(bomb_center+1) = '1' then
                ball_active(bomb_center+1) <= '0';
                ball_idx(bomb_center+1)    <= -2000;
                bomb_removed := bomb_removed + 1;
            end if;

        when BOMB_3 =>
            for k in 1 to 3 loop
                if bomb_center-k >= 0 and ball_active(bomb_center-k) = '1' then
                    ball_active(bomb_center-k) <= '0';
                    ball_idx(bomb_center-k)    <= -2000;
                    bomb_removed := bomb_removed + 1;
                end if;
            end loop;

        when others =>
            null;
    end case;

    -- ? ????? ?? ??????? ??
    removed_count <= removed_count + bomb_removed;
	 -- ===== Reward logic (BOMB remove) =====
if removed_count + bomb_removed >= 3 and reward_3_given = '0' then
    preview_type   <= BOMB_1;
    reward_3_given <= '1';

elsif removed_count + bomb_removed >= 6 and reward_6_given = '0' then
    preview_type   <= BOMB_3;
    reward_6_given <= '1';
end if;


    -- ? ??? ???
    if removed_count + bomb_removed >= 8 then
        game_state <= WIN;
    end if;

    collapse_pending <= '1';
end if;
-- ================= Collapse Chain =================
if collapse_pending = '1' then
for i in 0 to MAX_BALLS-2 loop
    if ball_active(i) = '0' then
        for j in i to MAX_BALLS-2 loop
            ball_active(j) <= ball_active(j+1);
            ball_idx(j)    <= ball_idx(j+1);
            ball_c(j)      <= ball_c(j+1);
        end loop;

        ball_active(MAX_BALLS-1) <= '0';
        ball_idx(MAX_BALLS-1)    <= -2000;
    end if;
end loop;
end if;
            end if;

        end if;
  

end process;

-- ================= Render =================
process(sx, sy, ball_idx, ball_c, ball_active, shooter_dir)
    variable x, y : integer;
    variable rx, ry : integer;
begin
    x := to_integer(unsigned(sx));
    y := to_integer(unsigned(sy));

    color <= "000000";

    -- ????
   -- if (x >= X_MIN and x <= X_MAX and y >= Y_MIN and y <= Y_MIN+THICK) or
       --(x >= X_MIN and x <= X_MAX and y >= Y_MAX-THICK and y <= Y_MAX) or
       --(x >= X_MIN and x <= X_MIN+THICK and y >= Y_MIN and y <= Y_MAX) or
       --(x >= X_MAX-THICK and x <= X_MAX and y >= Y_MIN and y <= Y_MAX) then
        --color <= "001100";
    --end if;

    -- ?????
    if (x >= X_MIN-6 and x <= X_MIN+6 and
        y >= Y_MIN-6 and y <= Y_MIN+6) then
        color <= "000000";
    end if;
-- ================= Hole (white) =================
if (x >= path_x(0)-HOLE_RADIUS and x <= path_x(0)+HOLE_RADIUS and
    y >= path_y(0)-HOLE_RADIUS and y <= path_y(0)+HOLE_RADIUS) then
    color <= "111111"; -- ????
end if;
    -- ??????? ????
    -- ===== render balls (lookup path) =====
for i in 0 to MAX_BALLS-1 loop
    if ball_active(i) = '1' and ball_idx(i) >= 0 then

        rx := path_x(ball_idx(i));
        ry := path_y(ball_idx(i));

        -- ===== Rounded & Bigger Ball (FPGA friendly) =====
if (abs(x - rx) <= BALL_RADIUS and
    abs(y - ry) <= BALL_RADIUS) then

    -- ??? ??????? ???? ??? ???? ???
    if not (
        abs(x - rx) = BALL_RADIUS and
        abs(y - ry) = BALL_RADIUS
    ) then
        color <= ball_c(i);
    end if;

end if;

    end if;
end loop;
	 -- ================= Shot ball render =================
-- ================= Shot ball render =================
if shot_active = '1' then
    if (x >= shot_x-3 and x <= shot_x+3 and
        y >= shot_y-3 and y <= shot_y+3) then
        case shot_type_latched is
            when BOMB_1 => color <= "111111";
            when BOMB_3 => color <= "101011";
            when others => color <= fired_color;
        end case;
    end if;
end if;

    -- Shooter ball
-- Shooter ball (preview next shot)
if (x >= SHOOTER_X-4 and x <= SHOOTER_X+4 and
    y >= SHOOTER_Y-4 and y <= SHOOTER_Y+4) then
    case preview_type is
        when BOMB_1 => color <= "111111"; -- ????
        when BOMB_3 => color <= "101011"; -- ????
        when others => color <= shooter_color;
    end case;
end if;

    -- Shooter angle line
  --  for i in 1 to 12 loop
    --    if (x = SHOOTER_X + angle_dx(shooter_angle)*i and
     --       y = SHOOTER_Y + angle_dy(shooter_angle)*i) then
       --     color <= "111111";
        --end if;
    --end loop;
end process;

Leds <= (others => '0');

process(CLOCK_24)
    variable seg_cnt : unsigned(15 downto 0) := (others => '0');
begin
    if rising_edge(CLOCK_24) then
        seg_cnt := seg_cnt + 1;

        -- ===== PRIORITY 1: GAME OVER =====
        if game_state = WIN then
            case seg_cnt(15 downto 14) is
                when "00" => an <= "1110"; sseg <= SEG_B;
                when "01" => an <= "1101"; sseg <= SEG_O;
                when "10" => an <= "1011"; sseg <= SEG_R;
                when others => an <= "0111"; sseg <= SEG_D;
            end case;

        elsif game_state = LOSE then
            case seg_cnt(15 downto 14) is
                when "00" => an <= "1110"; sseg <= SEG_L;
                when "01" => an <= "1101"; sseg <= SEG_O;
                when "10" => an <= "1011"; sseg <= SEG_S;
                when others => an <= "0111"; sseg <= SEG_E;
            end case;

        -- ===== PRIORITY 2: RESET =====
        elsif rst = '1' then
            case seg_cnt(15 downto 14) is
                when "00" => an <= "1110"; sseg <= SEG_8;
                when "01" => an <= "1101"; sseg <= SEG_0;
                when "10" => an <= "1011"; sseg <= SEG_0;
                when others => an <= "0111"; sseg <= SEG_9;
            end case;

        -- ===== NORMAL PLAY =====
        else
            an   <= "1111";
            sseg <= "11111111";
        end if;
    end if;
end process;

end Behavioral;