#!/usr/bin/env python
# coding: utf-8

# In[2]:


get_ipython().run_line_magic('matplotlib', 'inline')
import matplotlib.pyplot as plt
import json, os


# In[5]:


os.chdir('C:\\Users\\305232\\repos\\gmd-forms\\data')


# In[6]:


os.getcwd()


# In[7]:


wf_file = 'b4gic-gmd-wf.json'

with open(wf_file) as io:
    wf_data = json.load(io)


# In[8]:


outfile = 'B4GIC_gmd_opf_ts.json'

with open(outfile) as io:
    output = json.load(io)


# In[9]:


output.keys()


# In[10]:


wf_data.keys()


# In[11]:


wf_data['time']


# In[12]:


output['result']['solution']['nw'].keys()


# In[13]:


output['case']['nw'].keys()


# In[14]:


t = wf_data['time']


# In[15]:


output['result']['solution']['nw']['1']['branch']


# In[16]:


do1 = []
do2 = []

for i in range(1, len(t)+1):
    dK = output['result']['solution']['nw'][f'{i}']['branch']['1']['delta_topoilrise_ss']
    do1.append(dK)
    dK = output['result']['solution']['nw'][f'{i}']['branch']['3']['delta_topoilrise_ss']
    do2.append(dK)    


# In[17]:


plt.plot(t,do1,t,do2)
plt.show()


# In[ ]:




