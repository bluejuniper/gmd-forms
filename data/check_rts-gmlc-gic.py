#!/usr/bin/env python
# coding: utf-8

# In[2]:


import json, gzip, os
from glob import glob
import numpy as np


# In[3]:


with open('epri21_ots_gmd_opf_ts.json') as io:
    output = json.load(io)


# In[4]:


output['case']['nw'].keys()


# In[5]:


output['result']['solution']['nw'].keys()


# In[10]:


get_ipython().run_cell_magic('capture', '', '# read in the gic version\nwith gzip.open("rts-gmlc-geo.json.gz") as h:\n    jnet = json.load(h); ')


# In[11]:


get_ipython().run_cell_magic('capture', '', '# read in the matpower version\nwith open("RTS_GMLC_Geo.json") as h:\n    mnet = json.load(h); ')


# In[ ]:


get_ipython().run_cell_magic('capture', '', "def compdiff(x, y):\n    for k,v in x.items():\n        if k not in y:\n            #print('{} not found'.format(k))\n            continue\n            \n        if k in set(('index','rate_b','rate_c')):\n            continue\n        \n        d = v - y[k]\n        \n        if np.abs(d) < 1e-6:\n            continue\n            \n        print('{:>10}: {:8.2f} = {:8.2f} - {:8.2f}'.format(k, d, v, y[k]))\n        \ndef tablediff(x, y):\n    for k,v in x.items():\n        if k not in y:\n            #print('{} not found'.format(k))\n            continue\n\n        print('Component {}\\n---------------------------'.format(k))\n        compdiff(v, y[k])\n        print()\n        ")


# In[24]:


list(mnet['bus'].values())[0]


# In[22]:


tablediff(mnet['bus'], jnet['bus'])


# In[15]:


# create dict of branches
jbranches = {}

for b in jnet['branch'].values():
    k = b['f_bus'], b['t_bus']
    jbranches[k] = b


# In[16]:


0.02*180/np.pi


# In[23]:


for i,mbr in mnet['branch'].items():
    k = mbr['f_bus'], mbr['t_bus']
    jbr = jbranches[k]              

    print('Component {}\n---------------------------'.format(i))
    compdiff(mbr, jbr)
    print()
    
# Differences observed
# rate_b, rate_c are zero for jnet, but these are not used
# angmin & angmax are much larger for jnet, for mnet it's just +/- 1 degree


# In[ ]:


0.02*

