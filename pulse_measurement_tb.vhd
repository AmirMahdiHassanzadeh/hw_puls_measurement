library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pulse_measurement_tb is
end pulse_measurement_tb;

architecture sim of pulse_measurement_tb is

    -- Clock generation
    constant CLK_PERIOD : time := 10 ns;
    signal clk_i   : std_logic := '0';
    signal rst_ni  : std_logic := '0';

    -- UUT signals
    signal pulse_i   : std_logic := '0';
    signal enable_i  : std_logic := '0';
    signal half_done : std_logic;
    signal done      : std_logic;
    signal first_edge: std_logic;
    signal high_dur  : std_logic_vector(31 downto 0);
    signal low_dur   : std_logic_vector(31 downto 0);
    signal period    : std_logic_vector(31 downto 0);

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.pulse_measurement
    port map (
        clk_i           => clk_i,
        rst_ni          => rst_ni,
        pulse_i         => pulse_i,
        enable_i        => enable_i,
        half_done_o     => half_done,
        done_o          => done,
        first_edge_o    => first_edge,
        high_duration_o => high_dur,
        low_duration_o  => low_dur,
        period_o        => period
    );

    -- Clock Process
    clk_i <= not clk_i after CLK_PERIOD/2;

    -- Stimulus Process
    stim_proc: process
    begin
        -- 1. Reset
        rst_ni <= '0';
        wait for 50 ns;
        rst_ni <= '1';
        wait for 20 ns;

        -- 2. Enable
        enable_i <= '1';
        
        -- 3. Generate Pulse pattern
        -- Low 100ns (10 clk), High 200ns (20 clk), Low 150ns (15 clk)
        
        -- Low phase
        pulse_i <= '0';
        wait for 100 ns;
        
        -- High phase
        pulse_i <= '1';
        wait for 200 ns;
        
        -- Low phase (Measurement starts here)
        pulse_i <= '0';
        wait for 150 ns;
        
        -- High phase (250ns)
        pulse_i <= '1';
        wait for 250 ns;
        
        -- Final Low
        pulse_i <= '0';
        wait for 200 ns;

        -- Disable for a moment
        enable_i <= '0';
        wait for 50 ns;
        enable_i <= '1';
        wait for 100 ns;

        wait;
    end process;

end sim;
