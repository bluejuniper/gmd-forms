#!/usr/bin/env python
# coding: utf-8

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


do1 = []
do2 = []

do1d = []
do2d = []

import ipdb; ipdb.set_trace()

for i in range(len(t)):
    dK = output['result']['solution']['nw'][f'{i+1}']['branch']['1']['delta_topoilrise_ss']
    do1.append(dK)
    dK = output['result']['solution']['nw'][f'{i+1}']['branch']['3']['delta_topoilrise_ss']
    do2.append(dK)    

    dK = decoupled_output['result'][i]['temperatures']['delta_topoilrise_ss'][0]
    do1d.append(dK)
    dK = decoupled_output['result'][i]['temperatures']['delta_topoilrise_ss'][1]
    do2d.append(dK)    

plt.subplot(1,2,1)
plt.plot(t,do1,t,do1d)
plt.subplot(1,2,2)
plt.plot(t,do1d,t,do2d)
plt.show()

