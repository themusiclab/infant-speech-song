#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Oct 19 23:38:43 2018

Use this to take a bunch of TextGrids with annotated silence (as well as there
corresponding .wav files) and export subclips.

In order to use:
- Set textgrid_path, audio_path and export_path
- Make sure you have the libraries required (textgrid and soundfile)

@author: Harry Lee-Rubin
"""

import os
from textgrid import TextGrid # https://github.com/kylebgorman/textgrid
import soundfile as sf # https://github.com/bastibe/SoundFile
from math import floor
import pandas as pd

# Where we pull the annotations from
textgrid_path = '..\\IDSProject\TextGrids'
# Where we pull the corresponding wavs
audio_path = '..\\IDSProject\Clips'
# Where we save the exported subclips
export_path = '..\\IDSProject\Subclips'


# Exports a subclip (file_out) from a .wav (file_in) given start and end times (seconds)
def export_subclip(file_in, file_out, start, end):
    #print(file_in + ' ' + str(start) + ' ' + str(end))
    data, sr = sf.read(file_in)
    #Determine start time and end time
    start_sample, end_sample = floor(start*sr), floor(end*sr)
    sf.write(file_out, data[start_sample:end_sample], sr)

def wav_length(file_in):
    data, sr = sf.read(file_in)
    #Calculate length
    return len(data) / sr

filenames = os.listdir(textgrid_path)
#Filter by filetype
filenames = list(filter(lambda x: os.path.splitext(x)[1] == '.TextGrid', filenames))

clip_times = []
subclip_times = []

for filename in filenames:
    print('~' + filename + '~')
    
    # Get length of original file
    print('Saving length of original file...')
    old_name, ext = os.path.splitext(filename)
    old_filename = os.path.join(audio_path, old_name + '.wav')
    clip_times.append({'id': old_name, 'length': wav_length(old_filename)})
    
    # Load TextGrid
    print('Loading textgrid...', end=' ')
    # Retrieve .TextGrid information
    filepath = os.path.join(textgrid_path, filename)
    # Import .TextGrid
    tg = TextGrid.fromFile(filepath)
    # Filter out silences
    tg = list(filter(lambda x: x.mark != '', tg[0]))
    print('Done.')
    
    # Construct pathnames and export
    ''' 
        Example paths:
        ./AnnotatedTextGrids/WEL24D.wav
        ./HarryProcessedTextGrids/WEL24D.TextGrid
        ./Subclips/WEL24D_12.wav
    ''' 
    print('Exporting subclips...', end='')
    file_num = 1
    for interval in tg:
        print(str(file_num) + '...', end='')
        
        # Make new filename out of old one
        new_name = old_name + '_' + str(file_num)
        new_filename = os.path.join(export_path, new_name + '.wav')

        # Extract time info
        beg = float(interval.minTime)
        end = float(interval.maxTime)

        # Export .wav and time data for .csv
        subclip_times.append({'id': new_name, 'length': end - beg, 'beg': beg, 'end': end})
        # export_subclip(old_filename, new_filename, beg, end)
        export_subclip(old_filename, new_filename, interval.minTime, interval.maxTime)
        file_num += 1
    print('\nSubclips of ' + filename + ' exported!\n')

print()
print('Exporting .csvs of filelengths...')
clip_times_df = pd.DataFrame(clip_times)
clip_times_df.to_csv('./clip_times.csv', index=False)
subclip_times_df = pd.DataFrame(subclip_times)
subclip_times_df.to_csv('./subclip_times.csv', index=False)
print('Done!')