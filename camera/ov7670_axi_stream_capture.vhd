----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ov7670_axi_stream_capture is
  generic (
    gray_length : natural := 9
  );
    port (
        pclk              : in  std_logic;
        vsync             : in  std_logic;
        href              : in  std_logic;
        d                 : in  std_logic_vector (7 downto 0);
        address_out                : out  std_logic_vector (18 downto 0);
        m_axis_tvalid     : out std_logic;
        m_axis_tready     : in  std_logic;
        m_axis_tlast      : out std_logic;
        m_axis_tdata      : out std_logic_vector ( 31 downto 0 );
        m_axis_tuser      : out std_logic;
        aclk              : out std_logic
    );
end ov7670_axi_stream_capture;

architecture behavioral of ov7670_axi_stream_capture is
    signal d_latch          : std_logic_vector(15 downto 0) := (others => '0');
    signal address          : std_logic_vector(18 downto 0) := (others => '0');
    signal line             : std_logic_vector(1 downto 0)  := (others => '0');
    signal href_last        : std_logic_vector(6 downto 0)  := (others => '0');
    signal we_reg           : std_logic := '0';
    signal href_hold        : std_logic := '0';
    signal latched_vsync    : std_logic := '0';
    signal latched_href     : std_logic := '0';
    signal latched_d        : std_logic_vector (7 downto 0) := (others => '0');
    signal sof              : std_logic := '0';
    signal eol              : std_logic := '0';
    constant common_divider             : natural := 10;    -- 2**10 == 1024
    constant convertion_multiplier      : unsigned(31 downto 0) := to_unsigned(17, 32);
    constant r_multiplier               : unsigned(31 downto 0) := to_unsigned(309, 32);
    constant g_multiplier               : unsigned(31 downto 0) := to_unsigned(615, 32);
    constant b_multiplier               : unsigned(31 downto 0) := to_unsigned(105, 32);
    signal init_r, init_g, init_b       : unsigned(31 downto 0) := (others => '0');
    signal mult_r, mult_g, mult_b       : unsigned(31 downto 0) := (others => '0');
    signal final_r, final_g, final_b    : unsigned(31 downto 0) := (others => '0');
begin
     -- Expand 16-bit RGB (5:6:5) to 32-bit RGBA (8:8:8:8)
     
    init_r  <= resize(unsigned(d_latch(15 downto 12)), init_r'length);
    init_g  <= resize(unsigned(d_latch(11 downto 8)), init_g'length);
    init_b  <= resize(unsigned(d_latch(7 downto 4)), init_b'length);

    mult_r  <= resize(r_multiplier * convertion_multiplier * init_r, mult_r'length);
    mult_g  <= resize(g_multiplier * convertion_multiplier * init_g, mult_g'length);
    mult_b  <= resize(b_multiplier * convertion_multiplier * init_b, mult_b'length);
    
    final_r <= shift_right(mult_r, common_divider);
    final_g <= shift_right(mult_g, common_divider);
    final_b <= shift_right(mult_b, common_divider);
     
     
     
     
     
     
     m_axis_tdata  <= "00000000000000000000000" &std_logic_vector(resize(final_r + final_g + final_b,9)); 
     m_axis_tvalid <= we_reg;
     m_axis_tlast <= eol;
     m_axis_tuser <= sof;
     aclk <= not pclk;

capture_process: process(pclk)
begin
    if rising_edge(pclk) then
        if we_reg = '1' then
            address <= std_logic_vector(unsigned(address)+1);
        end if;

        if href_hold = '0' and latched_href = '1' then
            case line is
                when "00" => line <= "01";
                when "01" => line <= "10";
                when "10" => line <= "11";
                when others => line <= "00";
            end case;
        end if;
        href_hold <= latched_href;

        -- Capturing the data from the camera
        if latched_href = '1' then
            d_latch <= d_latch( 7 downto 0) & latched_d;
        end if;
        we_reg  <= '0';

        -- Is a new screen about to start (i.e. we have to restart capturing)
        if latched_vsync = '1' then
            address        <= (others => '0');
            href_last     <= (others => '0');
            line            <= (others => '0');
        else
            -- If not, set the write enable whenever we need to capture a pixel
            if href_last(0) = '1' then
                we_reg <= '1';
                href_last <= (others => '0');
            else
                href_last <= href_last(href_last'high-1 downto 0) & latched_href;
            end if;
        end if;

        case unsigned(address) mod 640 = 639 is
            when true => eol <= '1';
            when others => eol <= '0';
        end case;

        case unsigned(address) = 0 is
            when true => sof <= '1';
            when others => sof <= '0';
        end case;
    end if;
    if falling_edge(pclk) then
        latched_d     <= d;
        latched_href  <= href;
        latched_vsync <= vsync;
    end if;
end process;
end behavioral;