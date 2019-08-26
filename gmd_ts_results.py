#!/usr/bin/env python
# coding: utf-8


import json, gzip, os
from glob import glob
import numpy as np
import pandas as pd

#%%
os.getcwd()


#%%
with open("data/epri21_ots_gmd_opf_ts.json") as h:
    output = json.load(h); 

net = output['case']
result = output['result']

#%%
def merge_multinetwork_results(output, table_names=None):
    networks = output['case']['nw']
    solutions = output['result']['solution']['nw']
    times = sorted([int(x) for x in networks.keys()])   
    n = len(times)
    solved_networks = []
    
    for t in times:
        print(f'processing time {t}/{n}')
        net = networks[f'{t}']
        soln = solutions[f'{t}']
        merge_results(net, soln, table_names=table_names)
        solved_networks.append(net)
        
    return solved_networks
        

#%%
def merge_results(output, table_names=None):
    net = output['case']
    soln = output['result']['solution']
    return merge_results(net, soln, table_names=table_names)
    
#%%
def merge_results(net, soln, table_names=None):   
    if table_names is None:
        table_names = 'bus branch gen dcline storage shunt load gmd_bus gmd_branch'.split()
    
    for tname in table_names:
        # print(f'Table {tname}')
        
        for oid, obj in net[tname].items():
            if tname not in soln:
                continue
                
            soln_obj = soln[tname][oid]
            
            for fieldname, val in soln_obj.items():
                if fieldname in obj:
                    soln_fieldname = fieldname + '_soln'
                    obj[soln_fieldname] = val
                else:
                    obj[fieldname] = val
        
    return net


#%%
tnames = 'bus branch gen dcline storage shunt load gmd_bus gmd_branch'.split()
#merge_results(result, solution, table_names=tnames)
solved = merge_multinetwork_results(output, table_names=tnames)


#%%
n = len(solved)
#%%

tables = {}
for tname in tnames:
    tables[tname] = []
    for i in range(n):
        t = pd.DataFrame(list(solved[i][tname].values()))
        tables[tname].append(t)

buses = tables['bus']
branches = tables['branch']
gens = tables['gen']
loads = tables['load']
gmd_buses = tables['gmd_bus']
gmd_branches = tables['gmd_branch']

