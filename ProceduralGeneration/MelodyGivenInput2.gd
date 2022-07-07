"""
	------------------------------------------------------------------------------------------------
	Description: Generates a melody given an input melody, melody should have similar ideas as the input
	By: Jayden Moore
	Last Updated: 3/26/22
	------------------------------------------------------------------------------------------------
"""

extends Node
class_name MelodyGivenInput2

signal finished

var tiles = []
var note_info = NoteInfo.new()
var transition_matrix

var wave
	
func generate(path : String):
	var util = Util.new()
	util.midi_to_csv(path)
	#util.set_path("res://Output/Twinkle.csv")
	#util.set_path("res://Output/crazy.csv")
	#util.set_path("res://Output/jack.csv")
	tiles = util.convert_to_tiled()
	var w = WaveFunction.new(tiles)
	w.observe()
	emit_signal("finished")
	wave = w.get_wave().duplicate()
	var playback = Playback.new(wave)
	util.queue_free()
	return playback

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
		"tension": 1,
		
		#Ratio between steps in leaps
		"step": 1
	}
	
	const level_of_correction = 0
	
	var song_length = 10
	var note_info = NoteInfo.new()
	var scale = []
	
	var tiles = []
	var wave = []
	var first_layer_transition_matrix
	var second_layer_transition_matrix
	var columns
	var rng = RandomNumberGenerator.new()
	
	func _init(_tiles : Array):
		tiles = _tiles
		song_length = len(tiles)
		set_up()
		
	func set_up():
		scale = note_info.determine_scale(tiles[0].pitch, tiles[len(tiles) - 1].pitch)[0]
		create_first_layer_transition_matrix()
		determine_tension_ratio()
		determine_step_ratio()
		first_layer_transition_matrix.apply_tension(probabilities.tension, note_info)
		first_layer_transition_matrix.apply_step(probabilities.step, note_info)
		
		create_second_layer_transition_matrix()
		#second_layer_transition_matrix.apply_tension(probabilities.tension, note_info)
		#second_layer_transition_matrix.apply_step(probabilities.step, note_info)
		
		second_layer_transition_matrix.print_matrix()
	
	#Accounts for only the current note and the probability of transitioning to another note
	func create_first_layer_transition_matrix():
		first_layer_transition_matrix = Matrix.new()
		columns = []
		
		for x in tiles:
			if !columns.has(x.pitch):
				columns.append(x.pitch)
		
		first_layer_transition_matrix.create(len(columns), columns)
				
		for y in range(0, len(columns)):
			for z in range(0, len(columns)):
				first_layer_transition_matrix.set_element(y, z, search_pair(columns[y], columns[z]))
				
		first_layer_transition_matrix.normalize_rows()

	func search_pair(x, y):
		var tiles_temp = tiles.duplicate()
		var count = 0
		for i in range(0, len(tiles) - 1):
			if tiles[i].pitch == x && tiles[i + 1].pitch == y:
				tiles_temp.remove(i - (count * 2))
				tiles_temp.remove(i - (count * 2))
				count += 1
		return count
	
	#Accounts for the previous as well as the current note and the probability of transitioning to certain notes
	#eg. AA transitioning to A again could be 0.05 or 5% chance but AA transitioning to C could be 0.5 or 50% chance
	func create_second_layer_transition_matrix():
		second_layer_transition_matrix = Matrix.new()
		columns = []
		
		for x in range(0, len(tiles) - 1):
			var exists = false
			for y in range(len(columns)):
				exists = false
				if (columns[y].substr(0,1) == tiles[x].pitch.substr(0,1) && columns[y].substr(1,2) == tiles[x + 1].pitch.substr(0,1)):
					exists = true
				elif (columns[y].substr(0,1) == tiles[x + 1].pitch.substr(0,1) && columns[y].substr(1,2) == tiles[x].pitch.substr(0,1)):
					exists = true
			if !exists:
				columns.append(tiles[x].pitch.substr(0,1) + tiles[x + 1].pitch.substr(0,1))
				
		print(columns)
		
		second_layer_transition_matrix.create(len(columns), columns)
				
		for y in range(0, len(columns)):
			for z in range(0, len(columns)):
				for a in range(0, len(columns)):
					second_layer_transition_matrix.set_element(y, z, search_triad(columns[y], columns[z], columns[a]))
				
		second_layer_transition_matrix.normalize_rows()

	func search_triad(x, y, z):
		var tiles_temp = tiles.duplicate()
		var count = 0
		for i in range(0, len(tiles) - 2):
			if tiles[i].pitch == x && tiles[i + 1].pitch == y && tiles[i + 2].pitch == z:
				tiles_temp.remove(i - (count * 3))
				tiles_temp.remove(i - (count * 3))
				tiles_temp.remove(i - (count * 3))
				count += 1
		return count
		
	func determine_tension_ratio():
		var tension = 0
		var resolve = 0
		for i in range(0, len(tiles)):
			if note_info.get_tension(tiles[i].pitch):
				tension += 1
			else:
				resolve += 1
		if resolve == 0:
			resolve = tension
			
		probabilities.tension = stepify(float(tension)/(resolve + tension), 0.01)
		
		
	func determine_step_ratio():
		var step = 0
		var leap = 0
		for i in range(0, len(tiles) - 1):
			if note_info.is_step(tiles[i].pitch, tiles[i + 1].pitch):
				step += 1
			else:
				leap += 1
		if leap == 0:
			leap = step

		probabilities.step = stepify(float(step)/(leap + step), 0.01)
		
	func observe():
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
			wave.append(chosen_note)
		#corrections()
			
	func collapsed():
		return len(wave) == song_length
		
	func choose_note(curr_tile : Dictionary):
		var row
		var note
		
		if len(wave) < 2:
			row = first_layer_transition_matrix.get_index_of_row(curr_tile.pitch)
			note = columns[sample_matrix(row, first_layer_transition_matrix)]
		else:
			row = second_layer_transition_matrix.get_index_of_row(curr_tile.pitch + curr_tile.pitch)
			note = columns[sample_matrix(row, second_layer_transition_matrix)]
			 
		for x in range(len(tiles)):
			if tiles[x].pitch == note:
				return tiles[x].duplicate()
		
	func sample_matrix(row : int, matrix : Matrix):
		var probability_scale = []
		var transition_row = matrix.get_matrix()[row]
		
		for i in range(1, len(transition_row)):
			if probability_scale.size() == 0:
				probability_scale.append(transition_row[i] + transition_row[i - 1])
			else:
				probability_scale.append(probability_scale[len(probability_scale) - 1] + transition_row[i])
			
		rng.randomize()
		var num = rng.randf()
		
		for j in range(len(probability_scale)):
			if probability_scale[j] >= num:
				return j
		
		#Default in case it adds up to something less than 1
		return probability_scale[len(probability_scale) - 1]
		
	func correct(beginning_tile : Dictionary):
		wave.append(beginning_tile)
		while !collapsed():
			var curr_tile = wave[len(wave) - 1]
			var chosen_note = choose_note(curr_tile)
			if chosen_note == null:
				break
			wave.append(chosen_note)
			
		return wave
		
	func corrections():
		var produced_melodies = [wave]
		
		for _i in range(level_of_correction):
			var w  = WaveFunction.new(tiles)
			produced_melodies.append(w.correct(wave[0]))
		
		var pitches = {}
		
		for j in range(len(wave)):
			pitches = {}
			for k in range(len(produced_melodies)):
				if pitches.get(produced_melodies[k][j].pitch):
					pitches[produced_melodies[k][j].pitch] += 1
				else:
					pitches[produced_melodies[k][j].pitch] = 1
			
			var selected = pitches.keys()[0]
			var total = 0
			var probability = []
			
			for x in pitches:
				total += pitches.get(x)
			
			for a in pitches:
				probability.append(pitches.get(a) / float(total))
				
			selected = pitches.keys()[sample_probabilities(probability)]
			
			for y in produced_melodies:
				for z in y:
					if z.pitch == selected:
						wave[j] = z
						break
						
	func sample_probabilities(probability : Array):
		var probability_scale = []
		
		if len(probability) == 1:
			return 0
		
		for i in range(1, len(probability)):
			if probability_scale.size() == 0:
				probability_scale.append(probability[i] + probability[i - 1])
			else:
				probability_scale.append(probability_scale[len(probability_scale) - 1] + probability[i])
			
		rng.randomize()
		var num = rng.randf()
		
		for j in range(len(probability_scale)):
			if probability_scale[j] >= num:
				return j
		
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
