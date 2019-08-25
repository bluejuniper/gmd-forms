#!/usr/bin/env python
# coding: utf-8

# In[22]:


import json, gzip, os
from glob import glob
import numpy as np
import pandas as pd


# In[2]:


os.getcwd()


# In[5]:


with open("data/epri21_ots.json") as h:
    output = json.load(h); 

result = output['result']
# In[24]:


def merge_results(output, table_names=None):
    net = output['case']
    soln = output['result']['solution']
    
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


# In[ ]:

tnames = 'bus branch gen dcline storage shunt load gmd_bus gmd_branch'.split()
merge_results(output, table_names=tnames)


# In[23]:

tables = {}
for tname in tnames:
    tables[tname] = pd.DataFrame(list(output['case'][tname].values()))


buses = tables['bus']
branches = tables['branch']
gens = tables['gen']
loads = tables['load']
gmd_buses = tables['gmd_bus']
gmd_branches = tables['gmd_branch']

# In[25]:





# In[ ]:




