"""
Created on Sun Dec  2 20:09:46 2018
Use this script to extract nPVI data from *whole* files in the IDS Corpus.
Do not run on split or concatenated data.
This script first requires prosogram data extracted using Mertens' Prosogram software (v215f) using default settings.

@author: totaldorkist
"""

import csv
import os
import matplotlib.pyplot as plt
import numpy as np
import pickle
from scipy.io import loadmat
import pandas as pd

# Source: https://medium.com/@adds68/parsing-tsv-file-with-csv-in-python-662d6347b0cd
def extract_tsv(path):
    tsvfile = open(path)
    reader = csv.DictReader(tsvfile, dialect='excel-tab')
    events = []
    for event in reader:
        events.append(event)
    tsvfile.close()
    fn = os.path.split(path)[1]
    d = {'events': events,
         'culture': fn[0:3],
         'participant': fn[3:5],
         'condition': fn[5],
         'id': fn[0:6] }
    return d

def compute_npvi(phrase):
    if len(phrase) < 2:
        return None
    npvi = 0
    for i in range(0, len(phrase) - 1):
        curr = float(phrase[i]['nucl_t2'])  - float(phrase[i]['nucl_t1'])
        nxt = float(phrase[i+1]['nucl_t2']) - float(phrase[i+1]['nucl_t1'])
        npvi += abs((curr - nxt) / ((curr + nxt) / 2))
    npvi /= len(phrase) - 1
    npvi *= 100
    #print(npvi)
    return npvi

def split_phrases(events):
    phrases = []
    phrase = []
    npvis = []
    for event in events:
        phrase.append(event)
        if int(event['before_pause']):
            #print(event['rowLabel'])
            npvi = compute_npvi(phrase)
            phrases.append({'phrase': phrase, 'npvi': npvi})
            npvis.append(npvi)
            phrase = []
    return phrases, npvis

def erase_nones(l):
    return list(filter(None, l))

#%%
# Fetch all of the files in prosogram_path that end in _data.txt
directory = '..\IDSProjects\ProsogramFiles'
prosogram_path = directory + 'prosograms_just_text'
filenames = os.listdir(prosogram_path)
filenames = list(filter(lambda x: '_data.txt' in x, filenames)) # Filter by filetype

#%%
# Compute NPVI for each file in prosogram_path and save as a dictionary
recs = []
for file in filenames:
    rec = extract_tsv(prosogram_path + '/' + file)
    [phrases, npvi_phrases] = split_phrases(rec['events'])
    rec['phrases'] = phrases # Intermediary phrase data
    rec['npvi_phrase'] = np.mean([i for i in npvi_phrases if i != None]) # Average nPVI of all individual phrases
    rec['npvi_total'] = compute_npvi(rec['events']) # Treat whole thing as phrase
    rec['npvi_num_events'] = len(rec['events'])
    recs.append(rec)

#%% Convert dictionary into DataFrame and pickle it

df = pd.DataFrame(recs)
pickle.dump(df, open(directory + "npvi_data.p", "wb" ))

#%% These following to lines are only necessary if you loading the pickled file
#df = pickle.load(open(directory + "npvi_data.p", "rb"))
#df['npvi_num_events'] = df.apply(lambda row: len(row['events']), axis=1)

#%% Load the DataFrame and drop the extraneous stuff, save as .csv
    
df = pickle.load(open(directory + "npvi_data.p", "rb"))
df = df.drop(columns=['phrases', 'events', 'npvi_num_events', 'culture', 'participant', 'condition'])
df.to_csv(directory + 'npvi_summary.csv', index=False)
