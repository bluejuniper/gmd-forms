#!/usr/bin/env python
# coding: utf-8

import matplotlib.pyplot as plt
import json, os

wf_file = 'data/b4gic-gmd-wf.json'

with open(wf_file) as io:
    wf_data = json.load(io)


outfile = 'data/B4GIC_gmd_opf_ts.json'

with open(outfile) as io:
    output = json.load(io)

t = wf_data['time']
output['result']['solution']['nw']['1']['branch']


do1 = []
do2 = []

for i in range(1, len(t)+1):
    dK = output['result']['solution']['nw'][f'{i}']['branch']['1']['delta_topoilrise_ss']
    do1.append(dK)
    dK = output['result']['solution']['nw'][f'{i}']['branch']['3']['delta_topoilrise_ss']
    do2.append(dK)    


plt.plot(t,do1,t,do2)
plt.show()

