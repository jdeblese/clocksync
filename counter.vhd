library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.driveseg_comp.all;
use work.phasedet_comp.all;

entity counter is
	Port ( clk : in std_logic;
		btn : in std_logic;
		seg : out std_logic_vector (7 downto 0);
		an : out std_logic_vector (3 downto 0));
end counter;

architecture Behavioral of counter is
	signal cnt : unsigned(38 downto 0);
	signal data : std_logic_vector(15 downto 0);
	constant en : std_logic_vector(3 downto 0) := "1111";
	
	signal base, base_new, hi, hi_new, sp : unsigned(16 downto 0);
	signal offset, offset_new : signed(15 downto 0);
	signal ref, vco : std_logic;
	
	signal phase : signed(15 downto 0);
begin

	u1: driveseg port map(
		data => data,
		seg_c => seg,
		seg_a => an,
		en => en,
		clk => clk,
		rst => btn);
		
	u2: phasedet port map(
		ref => ref,
		vco => vco,
		mclk => clk,
		rst => btn,
		phase => phase);

	--data <= std_logic_vector(cnt(38 downto 23));
	--data <= std_logic_vector(phase);
	data <= std_logic_vector(sp(15 downto 0));

	process(clk,btn)
		variable old : std_logic;
	begin
		if btn = '1' then
			cnt <= (others => '0');
			
			base <= (others => '0');
			hi <= (others => '0');
			offset <= (others => '0');
			
			old := '0';
		elsif rising_edge(clk) then
			cnt <= cnt + "1";
			
			base <= base_new;
			hi <= hi_new;
			
			if old = '0' and ref = '1' then
				offset <= offset_new;
			end if;
			
			old := ref;
		end if;
	end process;
	
	ref <= base(14);
	vco <= hi(14);

	process(base, hi, offset, phase)		
		variable base_next, hi_next : unsigned(16 downto 0);
		variable offset_next : signed(15 downto 0);
		variable setpoint : unsigned(16 downto 0);
	begin
		base_next := base + "1";
		hi_next := hi + "1";
		offset_next := offset;
		
		if base = x"FFF0" then
			base_next := (others => '0');
		end if;

		offset_next := offset + phase;
		-- Use 'offset' and not 'offset_next' to improve stability
		setpoint := unsigned(phase(15 downto 0) + offset(15 downto 4) + "01111111111000000");
		sp <= setpoint;
	
		if hi = setpoint then
			hi_next := (others => '0');
		end if;

		base_new <= base_next;
		hi_new <= hi_next;
		offset_new <= offset_next;
	
	end process;

end Behavioral;
