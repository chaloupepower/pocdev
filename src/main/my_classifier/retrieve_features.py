#!/usr/bin/env python2
import os
import csv
//adapt command to location of bmv2 sswitch CLI and compiled P4 json
features=os.popen('echo register_read | simple_switch_CLI --json p4src/target/base.p4.json').read()

with open('features_list.csv', mode='w') as csv_file:
    features_writer = csv.writer(csv_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    for x in features:
        feature_write.writerow(features[x])
