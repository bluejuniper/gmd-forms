#!/usr/bin/env python
# coding: utf-8

import numpy as np
import matplotlib.pyplot as plt
import json, os

with open('data/b4gic-gmd-wf.json') as io:
    wf_data = json.load(io)


with open('data/B4GIC_gmd_opf_ts.json') as io:
    output = json.load(io)

t = wf_data['time']
output['result']['solution']['nw']['1']['branch']


with open('data/B4GIC_gmd_opf_ts_decoupled.json') as io:
    decoupled_output = json.load(io)




def timeseries(output, table, row, field):
    values = []
    for i in range(len(output['result']['solution']['nw'])):
        x = output['result']['solution']['nw'][str(i+1)][table][row][field]
        values.append(x)
        
    return values

doss = timeseries(output, 'branch', '1', 'topoil_rise_ss')
do = timeseries(output, 'branch', '1', 'topoil_rise')
dhsss = timeseries(output, 'branch', '1', 'hotspot_rise_ss')
dhs = timeseries(output, 'branch', '1', 'hotspot')
p = timeseries(output, 'branch', '1', 'pf')
q = timeseries(output, 'branch', '1', 'qf')
ieff = timeseries(output, 'branch', '1', 'gmd_idc_mag')

    
n = len(p)
dt = 5
tc = np.linspace(0, dt*n, n)

# for i in range(len(t)):
#     # dK = output['result']['solution']['nw'][f'{i+1}']['branch']['1']['delta_topoilrise_ss']
#     # do1.append(dK)
#     # dK = output['result']['solution']['nw'][f'{i+1}']['branch']['3']['delta_topoilrise_ss']
#     # do2.append(dK)    

#     dK = decoupled_output['result'][i]['temperatures']['delta_topoilrise_ss'][0]
#     do1d.append(dK)
#     dK = decoupled_output['result'][i]['temperatures']['delta_topoilrise_ss'][1]
#     do2d.append(dK)    

#     pf1 = decoupled_output['result'][i]['ac']['result']['solution']['branch']['1']['pf']
#     qf1 = decoupled_output['result'][i]['ac']['result']['solution']['branch']['1']['qf']
#     ratea = decoupled_output['case']['branch']['1']['rate_a']

#     pd.append(pf1)
#     qd.append(qf1)

    # print(f'p, q = {pf1:0.2f}, {qf1:0.2f}, rate_a = {ratea}')

### Temperatures ###
# import ipdb; ipdb.set_trace()

plt.subplot(2,2,1)
plt.plot(tc,doss,'.-',tc,do,'.-')
plt.title('Top-Oil')

plt.subplot(2,2,2)
plt.plot(tc,dhsss,'.-',tc,dhs,'.-')
plt.title('Hotspot')
plt.ylim(0, 1.1*max(dhs))


plt.subplot(2,2,3)
plt.plot(tc,ieff,'.-')
plt.title('Ieff')
plt.ylim(0, 1.1*max(ieff))

plt.subplot(2,2,4)
plt.plot(tc,p,'.-',tc,q,'.-')
plt.title('Power')
plt.ylim(0, 1.1*max(p))
plt.legend(['P', 'Q'])



# plt.plot(t,do1d,'.-',t,do2d,'.-')
# plt.legend(['XF1','XF3'])
# plt.title('Decoupled')

### Powers ###

# plt.subplot(1,2,1)
# plt.plot(tc,p,'.-',tc,q,'.-')
# plt.title('Coupled')
# plt.legend(['P', 'Q'])

# plt.subplot(1,2,2)
# plt.plot(t,pd,'.-',t,qd,'.-')
# plt.legend(['P', 'Q'])
# plt.title('Decoupled')
# plt.show()

# plot the decoupled powers
# plt.plot(t,p,t,q)

plt.show()