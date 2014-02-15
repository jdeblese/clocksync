library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package phasedet_comp is
	component phasedet
		Port ( ref : in  STD_LOGIC;
		       vco : in  STD_LOGIC;
		       mclk : in  STD_LOGIC;
		       rst : in std_logic;
		       phase : out  signed (15 downto 0));
	end component;
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity phasedet is
	Port ( ref : in  STD_LOGIC;
	       vco : in  STD_LOGIC;
	       mclk : in  STD_LOGIC;
	       rst : in std_logic;
	       phase : out  signed (15 downto 0));
end phasedet;

architecture Behavioral of phasedet is
	signal pre, pre_new, post, post_new : std_logic;
	signal last, last_new, count, count_new : signed(15 downto 0);
	signal synref, synvco : std_logic_vector(2 downto 0);
begin
	
	phase <= last;

	process(rst, mclk)
	begin
		if rst = '1' then
			last <= (others => '0');
			count <= (others => '0');
			pre <= '0';
			post <= '0';
			
			synref <= (others => '0');
			synvco <= (others => '0');
		elsif rising_edge(mclk) then
			last <= last_new;
			count <= count_new;
			pre <= pre_new;
			post <= post_new;
			
			synref <= synref(1 downto 0) & ref;
			synvco <= synvco(1 downto 0) & vco;
		end if;
	end process;
	
	process(synref, synvco, last, count, pre, post)
		variable last_next, count_next : signed(15 downto 0);
		variable pre_next, post_next : std_logic;
	begin
		last_next := last;
		count_next := count;
		pre_next := pre;
		post_next := post;
		
		if pre = '0' and post = '0' then
			-- reference clock rising edge is first
			if synref(2) = '0' and synref(1) = '1' then
				if synvco(2) = '0' and synvco(1) = '1' then
					last_next := (others => '0');
				else
					post_next := '1';
					count_next := (others => '0');
				end if;
			-- VCO rising edge is first
			elsif synvco(2) = '0' and synvco(1) = '1' then
				if synref(2) = '0' and synref(1) = '1' then
					last_next := (others => '0');
				else
					pre_next := '1';
					count_next := (others => '0');
				end if;
			end if;
		else
			-- If waiting for VCO edge and get REF edge, reset the count
			if post = '1' and synref(2) = '0' and synref(1) = '1' then
				count_next := (others => '0');
			-- If waiting for REF edge and get VCO edge, reset the count
			elsif pre = '1' and synvco(2) = '0' and synvco(1) = '1' then
				count_next := (others => '0');
			-- If waiting for edge and get edge, store phase
			elsif (post = '1' and synvco(2) = '0' and synvco(1) = '1') or (pre = '1' and synref(2) = '0' and synref(1) = '1') then
				pre_next := '0';
				post_next := '0';
				last_next := count_next;
			-- waiting for VCO edge, count up
			elsif post = '1' then
				count_next := count + "1";
			-- waiting for REF edge, count down
			elsif pre = '1' then
				count_next := count - "1";
			end if;
		end if;
		
		last_new <= last_next;
		count_new <= count_next;
		pre_new <= pre_next;
		post_new <= post_next;
	end process;
end Behavioral;

