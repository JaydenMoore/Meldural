"""
	----------------------------------------------------------------------------------------------
	Description: Helper functions and dictionary containing notes in relation to their midi pitch
	By: Jayden Moore
	Last Updated: 3/15/22
	----------------------------------------------------------------------------------------------
"""

extends Reference
class_name NoteInfo

#pitch in Midi Pitches
#Currently Three Octaves
#Source: https://www.inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies
const NotePitches = {
																								  "A0": 21, "A#0": 22, "B0": 23,
	"C1": 24, "C#1": 25, "D1": 26, "D#1": 27, "E1": 28, "F1": 29, "F#1": 30, "G1": 31, "G#1": 32, "A1": 33, "A#1": 34, "B1": 35,
	"C2": 36, "C#2": 37, "D2": 38, "D#2": 39, "E2": 40, "F2": 41, "F#2": 42, "G2": 43, "G#2": 44, "A2": 45, "A#2": 46, "B2": 47,
	"C3": 48, "C#3": 49, "D3": 50, "D#3": 51, "E3": 52, "F3": 53, "F#3": 54, "G3": 55, "G#3": 56, "A3": 57, "A#3": 58, "B3": 59,
	"C4": 60, "C#4": 61, "D4": 62, "D#4": 63, "E4": 64, "F4": 65, "F#4": 66, "G4": 67, "G#4": 68, "A4": 69, "A#4": 70, "B4": 71,
	"C5": 72, "C#5": 73, "D5": 74, "D#5": 75, "E5": 76, "F5": 77, "F#5": 78, "G5": 79, "G#5": 80, "A5": 81, "A#5": 82, "B5": 83,
	"C6": 84, "C#6": 85, "D6": 86, "D#6": 87, "E6": 88, "F6": 89, "F#6": 90, "G6": 91, "G#6": 92, "A6": 93, "A#6": 94, "B6": 95,
	"C7": 96, "C#7": 97, "D7": 98, "D#7": 99, "E7": 100, "F7": 101, "F#7": 102, "G7": 103, "G#7": 104, "A7": 105, "A#7": 106, "B7": 107,
	"C8": 108,
}

#Note lengths in relation to midi ticks
const NoteLengths = {
	"Sixteenth" : 113,
	"Eighth" : 227,
	"Quarter" : 455,
	"Dotted_Quarter" : 683,
	"Half" : 911,
	"Dotted_Half" : 1357,
	"Whole" : 1823,
}

const major_scale = "wwhwww"
const minor_scale = "whwwhw"
const step = 3

const scale_degrees = [
		"Tonic",
		"Supertonic", 
		"Mediant",
		"Sub-dominant",
		"Dominant",
		"Sub-mediant",
		"Leading Tone",
		"Tonic"
]

const tension = [
	"Leading Tone",
	"Sub-dominant",
	"Dominant"
]

var scale = []

#Determines scale based of first and last note found in input melody. 
#Will usually be correct unless a picardy third is done or scale change
#Not very optimal but gets the job done :v
func determine_scale(start_note : String, end_note : String):
	var major = false
	var accurate = true
	
	if start_note.substr(0,1) == end_note.substr(0,1):
		accurate = false
	if start_note.substr(0,1) == find_major_seventh_raised(start_note).substr(0,1):
		major = true
	
	scale.append(start_note)
	
	if major:
		for x in range(0,7):
			if major_scale.substr(x - 1, x) == "h":
				scale.append(find_minor_second(scale[len(scale) - 1]))
			else:
				scale.append(find_major_second(scale[len(scale) - 1]))
	else:
		for x in range(0,7):
			if minor_scale.substr(x - 1, x) == "h":
				scale.append(find_minor_second(scale[len(scale) - 1]))
			else:
				scale.append(find_major_second(scale[len(scale) - 1]))
	
	return [scale, accurate]
	
func determine_scale_degree(note : String):
	if scale.size() != 8:
		push_error("determine_scale has not been called")
		breakpoint
		
	for i in range(len(scale)):
		if scale[i].substr(0,1) == note.substr(0,1):
			return scale_degrees[i]
		
	return -1
		
func get_tension(note : String):
	return determine_scale_degree(note) in tension
	
func is_step(note1 : String, note2 : String):
	var pitches =  NotePitches.keys()
	
	var val1
	var val2
	var result
	
	for x in range(len(pitches)):
		if pitches[x] == note2:
			val2 = x
			
	for x in range(len(pitches)):
		if pitches[x] == note1:
			val1 = x
			
	result = val2 - val1
	
	if result > step || result < -step:
		return false
	
	return true

func find_minor_second(note : String):
	var pitch = NotePitches.get(note)
	var change = 1
	for x in NotePitches:
		if NotePitches.get(x) == pitch + change:
			return x
	# Note is either too high or too low
	return "C8" 

func find_major_second(note : String):
	var pitch = NotePitches.get(note)
	var change = 2
	if "B" in note || "E" in note:
		change = 1
	for x in NotePitches:
		if NotePitches.get(x) == pitch + change:
			return x
	# Note is either too high or too low
	return "C8" 

func find_major_third(note : String):
	var pitch = NotePitches.get(note)
	var change = 4
	if "B" in note || "E" in note || "D" in note || "A" in note:
		change = 3
	for x in NotePitches:
		if NotePitches.get(x) == pitch + change:
			return x
	# Note is either too high or too low
	return "C8" 
	
func find_major_fifth(note : String):
	var pitch = NotePitches.get(note)
	var change = 7
	for x in NotePitches:
		if NotePitches.get(x) == pitch + change:
			return x
	# Note is either too high or too low
	return "C8" 
	
func find_major_seventh(note : String):
	var pitch = NotePitches.get(note)
	var change = 11
	for x in NotePitches:
		if NotePitches.get(x) == pitch + change:
			return x
	# Note is either too high or too low
	return "C8" 
	
func find_major_seventh_raised(note : String):
	var pitch = NotePitches.get(note)
	var change = 12
	for x in NotePitches:
		if NotePitches.get(x) == pitch + change:
			return x
	# Note is either too high or too low
	return "C8" 
	
func determine_length_from_ticks(ticks : int):
	for x in NoteLengths:
		if NoteLengths.get(x) == ticks || NoteLengths.get(x) - ticks < 5 && ticks - NoteLengths.get(x) < 5: #Provides some margin for error
			return x
	return NoteLengths.get("Sixteenth")
	
func determine_note_length(length : String):
	return NoteLengths.get(length)
