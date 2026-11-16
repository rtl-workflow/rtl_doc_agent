

TEST_LIST = [
         {'TEST':'svf_sanity', 'RUN_TIMES':1,  'MODES':['base_fun']},
#         {'TEST':'tc_001_mode', 'RUN_TIMES':1,  'MODES':['base_fun1'], 'MAKE_OPTS':'ccov=on wave=fsdb'},
#         {'TEST':'tc_sanity', 'RUN_TIMES':1,  'MODES':['base_fun'], },
#         {'TEST':'tc_sanity', 'RUN_TIMES':1,  'MODES':['base_fun'], 'USER_BSUB_OPTS_TC': '-q long',},
#         {'TC_LIST':'../tc/tc.list', 'RUN_TIMES':1,  'MODES':['base_fun'], 'USER_BSUB_OPTS_TC': '-q long',},
#         {'TC_LIST':'../tc/tc.list', 'RUN_TIMES':1,  'MODES':['base_fun'], 'TEST_OWNER': 'j00123456',},
]




REPORT_LIST = {
     'base_fun':{'MODES':['base_fun'],  'URG':'off', 'PLAN':'off'}
}
