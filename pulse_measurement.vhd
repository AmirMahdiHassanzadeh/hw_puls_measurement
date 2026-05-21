library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pulse_measurement is

  port (

    clk_i           : in  std_logic;
    rst_ni          : in  std_logic;
    pulse_i         : in  std_logic;
    enable_i        : in  std_logic;

    half_done_o     : out std_logic;
    done_o          : out std_logic;
    first_edge_o    : out std_logic;

    high_duration_o : out std_logic_vector(31 downto 0);
    low_duration_o  : out std_logic_vector(31 downto 0);
    period_o        : out std_logic_vector(31 downto 0)

  );

end pulse_measurement;

architecture rtl of pulse_measurement is

  constant PULSE_WIDTH : natural := 4;
  
  signal counter_r      : unsigned(31 downto 0) := (others => '0');
  signal high_dur_r     : unsigned(31 downto 0) := (others => '0');
  signal low_dur_r      : unsigned(31 downto 0) := (others => '0');
  signal period_r       : unsigned(31 downto 0) := (others => '0');

  signal edge_cnt_r     : unsigned(1 downto 0) := (others => '0');

  -- synchronizer
  signal pulse_s1_r     : std_logic := '0';
  signal pulse_s2_r     : std_logic := '0';
  signal pulse_stable_r : std_logic := '0';
  signal pulse_last_r   : std_logic := '0';

  -- control
  signal first_edge_r   : std_logic := '0';
  signal half_done_r    : std_logic := '0';
  signal done_r         : std_logic := '0';

  signal half_cnt_r     : natural range 0 to PULSE_WIDTH := 0;
  signal done_cnt_r     : natural range 0 to PULSE_WIDTH := 0;

begin

  --------------------------------------------------------------------
  -- OUTPUTS
  --------------------------------------------------------------------

  high_duration_o <= std_logic_vector(high_dur_r);
  low_duration_o  <= std_logic_vector(low_dur_r);
  period_o        <= std_logic_vector(period_r);

  half_done_o <= half_done_r;
  done_o      <= done_r;
  first_edge_o <= first_edge_r;

  --------------------------------------------------------------------
  -- MAIN PROCESS
  --------------------------------------------------------------------

  process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then

      counter_r      <= (others => '0');
      high_dur_r     <= (others => '0');
      low_dur_r      <= (others => '0');
      period_r       <= (others => '0');
      edge_cnt_r     <= (others => '0');

      pulse_s1_r     <= '0';
      pulse_s2_r     <= '0';
      pulse_stable_r <= '0';
      pulse_last_r   <= '0';

      first_edge_r   <= '0';
      half_done_r    <= '0';
      done_r         <= '0';

      half_cnt_r     <= 0;
      done_cnt_r     <= 0;

    elsif rising_edge(clk_i) then

      ----------------------------------------------------------------
      -- SYNC
      ----------------------------------------------------------------
      pulse_s1_r     <= pulse_i;
      pulse_s2_r     <= pulse_s1_r;
      pulse_stable_r <= pulse_s2_r;

      ----------------------------------------------------------------
      -- PULSE_WIDTH de-assertion counters
      ----------------------------------------------------------------
      if half_cnt_r = 0 then
        half_done_r <= '0';
      else
        half_cnt_r <= half_cnt_r - 1;
      end if;

      if done_cnt_r = 0 then
        done_r <= '0';
      else
        done_cnt_r <= done_cnt_r - 1;
      end if;

      ----------------------------------------------------------------
      -- MAIN LOGIC
      ----------------------------------------------------------------
      if enable_i = '1' then

        -- counter increments continuously
        counter_r <= counter_r + 1;

        ----------------------------------------------------------------
        -- PERIOD COMPLETE (2 edges measured)
        ----------------------------------------------------------------
        if edge_cnt_r = "10" then  -- == 2
          period_r     <= high_dur_r + low_dur_r;
          edge_cnt_r   <= (others => '0');
          done_r       <= '1';
          done_cnt_r   <= PULSE_WIDTH;
        end if;

        ----------------------------------------------------------------
        -- RISING EDGE
        ----------------------------------------------------------------
        if (pulse_stable_r = '1') and (pulse_last_r = '0') then

          -- First edge detection
          if first_edge_r = '0' then
            first_edge_r <= '1';
          else
            half_done_r  <= '1';
            half_cnt_r   <= PULSE_WIDTH;
            edge_cnt_r   <= edge_cnt_r + 1;
          end if;

          low_dur_r   <= counter_r;
          counter_r   <= (others => '0');

        ----------------------------------------------------------------
        -- FALLING EDGE
        ----------------------------------------------------------------
        elsif (pulse_stable_r = '0') and (pulse_last_r = '1') then

          if first_edge_r = '0' then
            first_edge_r <= '1';
          else
            half_done_r  <= '1';
            half_cnt_r   <= PULSE_WIDTH;
            edge_cnt_r   <= edge_cnt_r + 1;
          end if;

          high_dur_r  <= counter_r;
          counter_r   <= (others => '0');

        end if;

      else
        -- reset measurement state when disabled
        counter_r    <= (others => '0');
        edge_cnt_r   <= (others => '0');
        first_edge_r <= '0';
      end if;

      -- update last pulse
      pulse_last_r <= pulse_stable_r;

    end if;
  end process;

end rtl;
