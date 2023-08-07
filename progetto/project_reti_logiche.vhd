library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
    port ( 
        i_clk : in std_logic;
        i_rst : in std_logic; 
        i_start : in std_logic; 
        i_w : in std_logic;

        o_z0 : out std_logic_vector(7 downto 0); 
        o_z1 : out std_logic_vector(7 downto 0); 
        o_z2 : out std_logic_vector(7 downto 0); 
        o_z3 : out std_logic_vector(7 downto 0); 
        o_done : out std_logic;

        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0); 
        o_mem_we : out std_logic; 
        o_mem_en : out std_logic
    );
end project_reti_logiche;

architecture project_reti_logiche_arch of project_reti_logiche is

    type S is (S0,S1,S2,S3,S4,S5,S6);
    
    --fsm
    signal curr_state : S; 
    
    --uscita fsm
    signal Rind_load : std_logic;
    signal R0_load : std_logic;
    signal R1_load : std_logic;
    signal Rout_load : std_logic;
    signal tmp_done : std_logic_vector(7 downto 0);
    signal shift_rst : std_logic;
    
    --ff di selezione
    signal sel_0 : std_logic;
    signal sel_1 : std_logic;
    
    --ff uscita
    signal input_ff_z0 : std_logic_vector(7 downto 0);
    signal input_ff_z1 : std_logic_vector(7 downto 0);
    signal input_ff_z2 : std_logic_vector(7 downto 0);
    signal input_ff_z3 : std_logic_vector(7 downto 0);
    
    signal output_ff_z0 : std_logic_vector(7 downto 0);
    signal output_ff_z1 : std_logic_vector(7 downto 0);
    signal output_ff_z2 : std_logic_vector(7 downto 0);
    signal output_ff_z3 : std_logic_vector(7 downto 0);
    
    --tmp shift reg
    signal tmp : std_logic_vector(15 downto 0) := "0000000000000000";
    

begin
    
    --codice fsm
    fsm : process(i_clk,i_rst)
    
    begin
        if i_rst = '1' then
            curr_state <= S0;
        elsif i_clk'event and i_clk = '1' then
            case curr_state is
                when S0 =>
                    if i_start='0' then
                        curr_state <= S0;
                    elsif i_start='1' then
                        curr_state <= S1;
                    end if;
                when S1 =>
                    if i_start='1' then
                        curr_state <= S2;
                    end if;
                when S2 =>
                    if i_start='0' then
                        curr_state <= S3;
                    elsif i_start='1' then
                        curr_state <= S2;
                    end if;
                when S3 =>
                    curr_state <= S4;
                when s4 =>
                    curr_state <= S5;
                when S5 =>
                    curr_state <= S6;
                when S6 =>
                    curr_state <= S0;
            end case;
        end if;
    end process;

    
    fsm_lambda : process(curr_state)
    
    begin
        o_mem_en <= '0';
        o_mem_we <= '0';
        Rind_load <= '0';
        R0_load <= '0';
        R1_load <= '0';
        Rout_load <= '0';
        tmp_done <= "00000000";
        shift_rst <= '0';

        case curr_state is
            when S0 => 
                R1_load <= '1';
                
            when S1 =>
                R1_load <= '0';
                R0_load <= '1';
                
            when S2 =>
                R0_load <= '0';
                Rind_load <= '1';
                
            when S3 =>
                o_mem_en <= '1';
                Rind_load <= '0';
                
            when S4 =>
                o_mem_en <= '0';
                shift_rst <= '1';
                
            when S5 =>
                shift_rst <= '1';
                Rout_load <= '1';
                
            when S6 =>
                Rout_load <= '0';
                tmp_done <= "11111111";
                shift_rst <= '0';
                
        end case;
    end process;

    
    --ff_selettori
    ff_sel_0 : process(i_clk, R0_load)
    begin
        if i_clk'event and i_clk = '1' and R0_load = '1' then
            sel_0 <= i_w;
        else
            sel_0 <= sel_0;
        end if;         
    end process;
    

    ff_sel_1 : process(i_clk, R1_load)
    begin
        if i_clk'event and i_clk = '1' and R1_load = '1' then
            sel_1 <= i_w;
        else
            sel_1 <= sel_1;
        end if;         
    end process;


    --decoder uscita
    input_ff_z0 <= i_mem_data and not("0000000" & sel_0) and not("0000000" & sel_1);
    input_ff_z1 <= i_mem_data and ("1111111" & sel_0) and not("0000000" & sel_1);
    input_ff_z2 <= i_mem_data and not("0000000" & sel_0) and ("1111111" & sel_1);
    input_ff_z3 <= i_mem_data and ("1111111" & sel_0) and ("1111111" & sel_1);


    --registri di uscita
    Rout_z0 : process(i_rst, i_clk, Rout_load, sel_1, sel_0)
    begin
        if i_rst = '1' then
            output_ff_z0 <= "00000000";
        elsif i_clk'event and i_clk = '1' and Rout_load = '1' and sel_1 = '0' and sel_0 = '0' then
            output_ff_z0 <= input_ff_z0;
        end if;         
    end process;
    

    Rout_z1 : process(i_rst, i_clk, Rout_load, sel_1, sel_0)
    begin
        if i_rst = '1' then
            output_ff_z1 <= "00000000";
        elsif i_clk'event and i_clk = '1' and Rout_load = '1' and sel_1 = '0' and sel_0 = '1' then
            output_ff_z1 <= input_ff_z1;    
        end if;         
    end process;
    

    Rout_z2 : process(i_rst, i_clk, Rout_load, sel_1, sel_0)
    begin
        if i_rst = '1' then
            output_ff_z2 <= "00000000";
        elsif i_clk'event and i_clk = '1' and Rout_load = '1' and sel_1 = '1' and sel_0 = '0' then
            output_ff_z2 <= input_ff_z2;
        end if;         
    end process;
    

    Rout_z3 : process(i_rst, i_clk, Rout_load, sel_1, sel_0)
    begin
        if i_rst = '1' then
            output_ff_z3 <= "00000000";
        elsif i_clk'event and i_clk = '1' and Rout_load = '1' and sel_1 = '1' and sel_0 = '1' then
            output_ff_z3 <= input_ff_z3;
        end if;         
    end process;
   

    --registro reverse indirizzo
    Reg_Ind : process(i_clk ,i_rst)
    begin   
        if i_rst = '1' then
            tmp(15 downto 0) <= "0000000000000000";
            
        elsif i_clk'event and i_clk = '1' then 

            if i_start = '1' and Rind_load = '1' then
                tmp (15 downto 0) <= tmp (14 downto 0) & i_w ;
            end if;
        
            if i_start = '0' and shift_rst = '1' then
                tmp(15 downto 0) <= "0000000000000000";
            end if;   

        end if;
         
    end process;
    o_mem_addr <= tmp;


    --uscite 
    o_done <= tmp_done(0);
    o_z0 <= output_ff_z0 and tmp_done;
    o_z1 <= output_ff_z1 and tmp_done;
    o_z2 <= output_ff_z2 and tmp_done;
    o_z3 <= output_ff_z3 and tmp_done;
    

end architecture;