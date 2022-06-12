"""
	------------------------------------------------------------------------------------------------
	Description: Generates a melody given an input melody, melody should have similar ideas as input
	By: Jayden Moore
	Last Updated: 3/16/22
	------------------------------------------------------------------------------------------------
"""

extends Node
class_name MelodyGivenInput

var tiles = []

var wave
	
func generate(path : String):
	var util = Util.new()
	util.midi_to_csv(path)
	tiles = util.convert_to_tiled()
	determine_compatibilities()
	var w = WaveFunction.new(tiles)
	w.observe()
	wave = w.get_wave().duplicate()
	var playback = Playback.new(wave)
	util.queue_free()
	return playback
	
#Determines the compatibilities for each note in the tiles array
func determine_compatibilities():		
	create_compatibilities()
	
	var tiles_w_compatibilities = []
	
	for x in range(0, len(tiles)):
		for tile in tiles_w_compatibilities:
			if tile.pitch == tiles[x].pitch:
				tiles[x].compatibility = tile.compatibility
				if x == len(tiles) - 1:
					break
				tile.compatibility.add_compatibility(tiles[x + 1])
				
				break
		check_tiles(tiles[x])
		tiles_w_compatibilities.append(tiles[x])
	
#Creates Compatibility object for every tile
#There may be some identical compatabilities as there can be some identical notes
func create_compatibilities():
	for x in range(0, len(tiles)):
		tiles[x].compatibility = Compatibility.new()
	
#Checks note in front of the current note and then adds compatability with that note to cur note.
func check_tiles(cur_tile):
	for x in range(0, len(tiles) - 1):
		if tiles[x].length == cur_tile.length && tiles[x].pitch == cur_tile.pitch:
			tiles[x].compatibility.add_compatibility(tiles[x + 1])
			
class Structure:
	pass

class Compatibility:
	var data = []
	
	func add_compatibility(tile):
		data.push_back(tile)
	
	func check(tile):
		return data.has(tile)
		
	func get_compatibilities():
		return data

class WaveFunction:
	var probabilities = {
		#probability of variating a note with these types
		"second" : 0.1,
		"third" : 0.1,
		"fifth" : 0.05,
		"seventh": 0.01,
		
		#Forceful approach - probability of variating a note with these types
		"force_second" : 0.4,
		"force_third" : 0.4,
		"force_fifth" : 0.15,
		"force_seventh": 0.05,
		
		#Ratio between resolve and tension
		#Will change as more notes are generated
		"tension": 1,
		"resolve": 0,
		"true_ratio": 0.8 #True ratio between tension and resolve notes
	}
	
	const second_chance = 0.1
	const third_chance = 0.1
	const max_attempts = 3
	
	var song_length = 10
	var note_info
	var scale = []
	
	var tiles = []
	var wave = []
	var rng = RandomNumberGenerator.new()
	
	func _init(_tiles : Array):
		tiles = _tiles
		song_length = len(tiles)
		
	func observe():
		note_info = NoteInfo.new()
		scale = note_info.determine_scale(tiles[0].pitch, tiles[len(tiles) - 1].pitch)[0]
		wave.clear()
		rng.randomize()
		wave.append(tiles[rng.randi_range(0, len(tiles) - 1)])
		collapse()
	
	func collapse():
		while !collapsed():
			var curr_tile = wave[len(wave) - 1]
			var chosen_note = choose_note(curr_tile)
			if chosen_note == null:
				break
			"""var compatibilities = curr_tile.compatibility.get_compatibilities()
			if compatibilities.size() == 0:
				break
			rng.randomize()
			var chosen_note = variate(compatibilities[rng.randi_range(0, len(compatibilities) - 1)])"""
			wave.append(chosen_note)
			
	func collapsed():
		return len(wave) == song_length
		
	func choose_note(curr_tile : Dictionary):
		var temp1_compatibilities = curr_tile.compatibility.get_compatibilities().duplicate()
		var temp2_compatibilities = temp1_compatibilities.duplicate()
		
		if temp1_compatibilities.size() == 0:
			return null
		
		rng.randomize()
		
		#Force resolve notes towards the end
		if song_length - len(wave) < rng.randi_range(2,4):
			probabilities.tension = 0
			probabilities.resolve = 1
		#Tries to maintain true ratio between tension and resolve
		else:
			var tension_count = 0
			
			for x in wave:
				if note_info.get_tension(x.pitch):
					tension_count += 1
					
			if tension_count / len(wave) < probabilities.true_ratio:
				probabilities.tension = 1
				probabilities.resolve = 0
			else:
				probabilities.tension = 0
				probabilities.resolve = 1
					
		rng.randomize()
		var tension = false
		if rng.randf() <= probabilities.tension:
			tension = true
		
		rng.randomize()
		var index = rng.randi_range(0, len(temp1_compatibilities) - 1)
		var chosen_note = variate(temp1_compatibilities[index])
		temp1_compatibilities.remove(index)
		
		#Forces last note to tonic, come up with better solution to interpolate closer towards the tonic in the future
		if len(wave) + 1 == song_length:
			chosen_note = tiles[0].duplicate()
			chosen_note.length = note_info.determine_length_from_ticks(note_info.NoteLengths.Half)
			return chosen_note
			
		while wave[len(wave) - 1] == wave[len(wave) - 2] && chosen_note == wave[len(wave) - 1]:
			index = rng.randi_range(0, len(temp1_compatibilities) - 1)
			chosen_note = force_variate(temp1_compatibilities[index])
			temp1_compatibilities.remove(index)
			if !(wave[len(wave) - 1] == wave[len(wave) - 2] && chosen_note == wave[len(wave) - 1]):
				return chosen_note
		
		var attempts = 0
		
		#Two methods of attempting to get a tension/resolve note
		while note_info.get_tension(chosen_note.pitch) != tension && attempts < max_attempts && len(temp1_compatibilities) != 0:
			rng.randomize()
			index = rng.randi_range(0, len(temp1_compatibilities) - 1)
			chosen_note = temp1_compatibilities[index]
			temp1_compatibilities.remove(index)
			attempts += 1
			
		attempts = 0
		
		#If even all this fails, I give up.
		while note_info.get_tension(chosen_note.pitch) != tension && attempts < max_attempts && len(temp2_compatibilities) != 0:
			rng.randomize()
			index = rng.randi_range(0, len(temp2_compatibilities) - 1)
			chosen_note = force_variate(temp2_compatibilities[index])
			attempts += 1
			
		return chosen_note
	
	func force_variate(note):
		note.pitch = note_info.find_major_second(note.pitch)
		return note
		
	func variate(note):
		var new_note = {}
		rng.randomize()
		
		var num = rng.randf()
		
		if num <= third_chance:
			new_note.pitch = note_info.find_major_third(note.pitch)
			new_note.length = note.length
			new_note.compatibility = note.compatibility
			return new_note
		elif num > third_chance && num <= second_chance + third_chance:
			new_note.pitch = note_info.find_major_second(note.pitch)
			new_note.length = note.length
			new_note.compatibility = note.compatibility
			return new_note
		return note
		
	func get_wave():
		return wave
		
func render_output(output_file):
	var util = Util.new()
	util.set_path("res://Output/output.csv")
	util.csv_to_array()
	
	for tile in wave:
		util.create_note(tile.length, tile.pitch)
		
	util.export_midi(output_file)
	util.queue_free()
		
class Model:
	pass
	
