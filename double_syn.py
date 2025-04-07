from DCWrapper.DCWrapper import Design

if __name__ == '__main__':
    design = Design('Double')

    design.set_pdk(target_library=r'pdk/tcbn12ffcllbwp20p90cpdulvtssgnp0p72v125c_ccs.db')
    design.set_design(['./double_mac_int4_int8.v'],'double_mac_unit')
    design.set_clock('clk',1)
    design.add_multi_switching_activity(['in_a1','in_a2','in_b1','in_b2'],0.3,0.5)
    design.add_case_activity('pulse',1)
    design.add_case_activity('reset',0)

    design.generate_tcl_file()