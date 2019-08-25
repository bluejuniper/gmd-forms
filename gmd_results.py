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


# In[24]:


def merge_results(output):
    net = output['case']
    soln = output['result']['solution']
    table_names = 'bus branch gen dcline storage shunt load gmd_bus gmd_branch'.split()
    
    for tname in table_names:
        # print(f'Table {tname}')
        
        for oid, obj in net[tname].items():
            if tname not in soln:
                continue
                
            soln_obj = soln[tname][oid]
            
            for fieldname, val in soln_obj.items():
                obj[fieldname] = val
        
    return net


# In[ ]:


net = merge_results(output)


# In[23]:


buses = pd.DataFrame(list(net['bus'].values()))
branches = pd.DataFrame(list(net['branch'].values()))
gens = pd.DataFrame(list(net['gen'].values()))
loads = pd.DataFrame(list(net['load'].values()))
gmd_buses = pd.DataFrame(list(net['gmd_bus'].values()))
gmd_branches = pd.DataFrame(list(net['gmd_branch'].values()))


# In[25]:


buses


# In[ ]:




