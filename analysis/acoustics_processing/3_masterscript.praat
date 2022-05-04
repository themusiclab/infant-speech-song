## Use this script in Praat to extract f0, f1, f2, and intensity data from sound files in a directory every 0.03125 seconds
# Call a form upon running the script to insert parameters
form Get Acoustic Measurements
	comment Directory of sound files. Be sure to include the final "\"
	text directory ..\SoundFiles\Femalesubclips\
	sentence Sound_file_extension .wav
	comment Full path of the resulting text file. Be sure to include the file name and extension:
	text resultsfile ..\Results\results.csv
	comment Pitch floor (Change to 75 for males)
	positive minimum_pitch_(Hz) 100
	comment Pitch ceiling (Change to 300 for males)
	positive maximum_pitch_(Hz) 600
	comment Maximum formant for your speaker. Set to 5500 for females and children and 5000 for males
	positive maximum_formant_(Hz) 5500

endform

# Make a listing of all the sound files in a directory:
Create Strings as file list... list 'directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

# Check if the result file exists:
if fileReadable (resultsfile$)
	pause The file 'resultsfile$' already exists! Do you want to overwrite it?
	filedelete 'resultsfile$'
endif

# Set up headers for excel file
header$ = "Filename,	time,	praat_f0,	praat_f1,	praat_f2,	praat_intensity,'newline$'"
fileappend "'resultsfile$'" 'header$'

# Open each sound file in the directory:
for d from 1 to numberOfFiles
	select Strings list
	filename$ = Get string... d
	dotInd = rindex(filename$, ".")
	soundname$ = left$ (filename$, dotInd-1)
	Read from file... 'directory$''filename$'
	select Sound 'soundname$'
	To Pitch... 0 'minimum_pitch' 'maximum_pitch'
	pitchID = selected ("Pitch")
	select Sound 'soundname$'
	To Intensity...  'minimum_pitch' 0
	intensityID = selected ("Intensity")
	select Sound 'soundname$'
	To Formant (burg)... 0 5 'maximum_formant' 0.05 50
	formantID = selected ("Formant")
	# get the name of the sound object:
	soundname$ = left$ (filename$, dotInd-1)
	# Look for a TextGrid by the same name:
	    Read from file... 'directory$''soundname$''Sound_file_extension$'
		# Determine length of file
		end = Get finishing time
		# Determine number of times the file is divided by .03125 seconds
		numTimes = end / 0.03125
		# Pass through all intervals in the designated tier, and if they have a label, do the analysis at 0.03125 second granularity:
				for itime to numTimes
					curtime = 0.03125 * itime
					select 'pitchID'
					f0 = 0
					f0 = Get value at time... 'curtime' Hertz Linear
					f0$ = fixed$ (f0, 2)
					if f0$ = "--undefined--"
						f0$ = "0"
					endif
					select Formant 'soundname$'
					f1 = Get value at time... 1 'curtime' Hertz Linear
					f1$ = fixed$ (f1, 2)
					if f1$ = "--undefined--"
						f1$ = "0"
					endif
					f2 = Get value at time... 2 'curtime' Hertz Linear
					f2$ = fixed$ (f2, 2)
					if f2$ = "--undefined--"
						f2$ = "0"
					endif
					select 'intensityID'
					intensity = Get value at time... 'curtime' Cubic
					intensity$ = fixed$ (intensity,2)
					if intensity$ = "--undefined--"
						intensity$ = "0"
					endif
					curtime$ = fixed$ (curtime, 5)
					resultline$ = "'soundname$',	'curtime$',	'f0$',	'f1$',	'f2$',	'intensity$','newline$'"
					fileappend "'resultsfile$'" 'resultline$'
				endfor
		# Remove the TextGrid, Formant, and Pitch objects from Praat Objects List
		select all
		minus Strings list
		Remove
endfor
# When everything is done, remove the list of sound file paths:
select all
Remove