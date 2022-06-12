"""
	----------------------------------------------------------------------------------------------
	Description: Utility script to handle the creation of midis after randomly generating a melody
	By: Jayden Moore
	Last Updated: 3/15/22
	----------------------------------------------------------------------------------------------
"""

#	------------------------------------------------------------------------------------------------	#
#	CSV Utility is a simple tool created to handle the writing and reading of CSVs in midicsv format	#
#	------------------------------------------------------------------------------------------------	#


extends Node
class_name Util

const default_in_path = "res://Output/Csvs/CSVOutput.csv"
const default_out_path = "res://Output/Midis/MIDIOutput.mid"

var path : String 
var csv_name : String 
var csv_array : Array = []
var file = File.new()

var dir = Directory.new()\

var cache_dir

func _init():
	dir.open("user://")
	
	if !dir.dir_exists("Cache"):
		dir.make_dir("Cache")
	
	cache_dir = OS.get_user_data_dir().plus_file("Cache")
	
func set_path(_path : String):
	path = _path
	
	
#Uses path to open csv then convert it into an array
func csv_to_array():
	if !check_path():
		return
	
	set_csv_name()
	
	file.open(path, File.READ)
	while !file.eof_reached():
		csv_array.append(file.get_csv_line(","))
	file.close()
	remove_empty()
	
#Converts an array back into csv form, creates a csv file at given path
func array_to_csv(arr : Array = csv_array, out_path : String = default_in_path):
	file.open(out_path, File.WRITE)
	for row in arr:
		file.store_csv_line(row)
	file.close()
	
#Removes empty array at the end of csv_array
func remove_empty():
	for row in range(0, len(csv_array)):
		if csv_array[row].size() == 1:
			csv_array.remove(row)
			break

func set_csv_name():
	var string_array = path.split("/")
	csv_name = string_array[len(string_array) - 1]
	
func get_csv_length():
	if len(csv_array) == 0:
		push_error("csv_array has not been properly initialized, please make sure the path has been set correctly.")
		breakpoint
	return len(csv_array)

#Checks if path has been set and path exists
func check_path():
	if path == "":
		push_error("Path hasn't been set, remember to use set_path(path) after instantiating a CSV object")
		return false
	elif !file.file_exists(path):
		push_error("File at path %s does not exist" % path)
		return false
	
	return true
	
#	-------------------------------------------------------------------------------   #
#	Converts Csv into wave form (tiled form) so it can be used by the wave function   #
#	-------------------------------------------------------------------------------   #

var tiles = []

func convert_to_tiled():
	var notes = []
	
	for x in range(find_first_note(), find_last_note() + 1):
		notes.append(csv_array[x])
	
	for x in range(0, len(notes) - 1):
		var note = {}
		if x % 2 == 0:
			note.length = determine_length_from_ticks(int(notes[x + 1][1]) - int(notes[x][1]))
			note.pitch = determine_note_from_pitch(int(notes[x][4]))
			tiles.append(note)
			
	return tiles
	
func find_first_note():
	for x in range(0, get_csv_length()):
		if default_event in csv_array[x][2]:
			return x
	return -1
	
func find_last_note():
	if default_event in csv_array[get_csv_length() - 3][2]:
		return get_csv_length() - 3
	return -1
	
#	---------------------------------------------------   #
#	Important values regarding note lengths and pitches   #
#	---------------------------------------------------   #

#Time in Midi Ticks
var NoteLengths = NoteInfo.new().NoteLengths

var NotePitches = NoteInfo.new().NotePitches

func determine_note_length(length : String):
	return NoteLengths.get(length)
	
func determine_length_from_ticks(ticks : int):
	for x in NoteLengths:
		if NoteLengths.get(x) == ticks || NoteLengths.get(x) - ticks < 5 && ticks - NoteLengths.get(x) < 5: #Provides some margin for error
			return x
	return NoteLengths.get("Sixteenth")
	
func determine_note_pitch(pitch : String):
	return NotePitches.get(pitch)
	
func determine_note_from_pitch(pitch : int):
	for x in NotePitches:
		if NotePitches.get(x) == pitch:
			return x
	return "C4"

#	-------------------------------------------------	#
#	Formatter for creating midi notes in the csv file	#
#	-------------------------------------------------	#

#Unit note for timing
const quarter_note = 455
const margin = 0.5

const default_track = "1"
const default_event = "Note_on_c"
const default_channel = "0"

#Note event format
#Track, Time, Event Type, Channel, Note, Velocity
class MIDINote:
	var properties = []
	
	# Time, Note-Value, Velocity
	func _init(time : String, note : String, velocity : String):
		properties.append(default_track)
		properties.append(time)
		properties.append(default_event)
		properties.append(default_channel)
		properties.append(note)
		properties.append(velocity)
		format()

	func format():
		for x in range(1,6):
			properties[x] = " " + properties[x]
		
	func get_array():
		return properties

#Creates a note and then adds it to the csv array
#Note_time - initially string -> int
#Note_pitch - initially string -> int
func create_note(time, pitch):
	time = determine_note_length(time)
	pitch = determine_note_pitch(pitch)
	var start_time = 0
	var end_time = 0
	if previous_note():
		start_time = get_previous_note_time() + 15
		end_time = get_previous_note_time() + 15 + time
	else:
		end_time = time
		
	var start_note = MIDINote.new(str(start_time), str(pitch), "80")
	csv_array.insert(get_csv_length() - 2, start_note.get_array())
	
	var end_note = MIDINote.new(str(end_time), str(pitch), "0")
	csv_array.insert(get_csv_length() - 2, end_note.get_array())
	
	edit_end_track()

#Checks if the event type is a note_off_c or note_on_c with a velocity of 0 (same as note_off_c)
#Then returns if previous note does exist
func previous_note():
	var prev_event = csv_array[get_csv_length() - 3][2]
	if "Note_off_c" in prev_event || "Note_on_c" in prev_event:
		if int(csv_array[get_csv_length() - 3][5]) == 0:
			return true
	return false

func get_previous_note_time():
	if previous_note():
		return int(csv_array[get_csv_length() - 3][1])
		
func edit_end_track():
	csv_array[get_csv_length() - 2][1] = " " + str(get_previous_note_time() + 1)
	
#	-------------------------------------------------	#
#	Midi Exporter, executes csvmidi.exe in background	#
#	   csvmidi.exe is written by John Walker (2004)     #
#	-------------------------------------------------	#

#Fix directories later, doesn't really matter now
func export_midi(output_path):
	var directory = "C:/Users/Jayden/Desktop/Converter/"
	array_to_csv()
	file.open(default_in_path, File.READ)
	# warning-ignore:return_value_discarded
	#directory.plus_file("Midis/") + "Output.mid"
	OS.execute(directory + "Csvmidi.exe", [file.get_path_absolute(), output_path], true)
	file.close()
	
#	---------------------------------------------------	  #
#	Converts input midi into a csv file for interaction   #
#	   midicsv.exe is written by John Walker (2004)       #
#	---------------------------------------------------   #

#Fix directories later, doesn't really matter now
func midi_to_csv(input_path : String):
	var directory = "C:/Users/Jayden/Desktop/Converter/"
	var cache_filename = input_path.get_file().get_basename() + ".csv"
	# warning-ignore:return_value_discarded
	OS.execute(directory + "Midicsv.exe", [input_path, cache_dir.plus_file(cache_filename)], true)
	set_path(cache_dir.plus_file(cache_filename))
	csv_to_array()

