extends Node
class_name Matrix

var matrix = []
var columns = []

func create(size, _columns):
	for x in range(size):
		matrix.append([])
		matrix[x].resize(size)
		
		for y in range(size):
			matrix[x][y] = 0
	
	columns = _columns
	return matrix
	
func get_matrix():
	return matrix.duplicate()
	
func set_element(x : int, y : int, new_value):
	matrix[x][y] = new_value
	
func add_to_element(x : int, y : int, value):
	matrix[x][y] += value
	
func multiply_by_matrix(_otherMatrix : Matrix):
	pass
	
func get_column_as_row(column : int , given_matrix = matrix):
	var _columns = []
	
	for x in range(len(given_matrix)):
		_columns.append(given_matrix[x][column])
		
	return _columns
			
func normalize_rows():
	var sum
	for x in range(len(matrix)):
		sum = 0
		for y in matrix[x]:
			sum += y
			
		if sum != 0:
			for z in range(len(matrix[x])):
				matrix[x][z] = stepify(matrix[x][z] / float(sum), 0.01)
				
func normalize_columns():
	var sum
	for x in range(len(matrix)):
		sum = 0
		for y in range(len(matrix[x])):
			sum += matrix[y][x]
			
		if sum != 0:
			for z in range(len(matrix[x])):
				matrix[z][x] = stepify(matrix[z][x] / float(sum), 0.01)
				
func print_matrix():
	print()
	var _columns = columns.duplicate()
	for x in range(len(_columns)):
		_columns[x] = columns[x].substr(0,1)
		
	print("  " + str(_columns))
	
	for j in range(len(matrix)):
		print(_columns[j] + " " + str(matrix[j]))
		
#------------- Helper functions specific to melody generation -------------
func set_zeros_to_ones():
	for i in range(len(matrix)):
		for j in range(len(matrix[i])):
			if matrix[i][j] == 0:
				matrix[i][j] = 1

func apply_tension(tension_ratio : float, note_info : NoteInfo):
	set_zeros_to_ones()
	var resolve_ratio = 1-tension_ratio
	var tension = []
	
	for i in range(len(matrix)):
		if note_info.get_tension(columns[i]):
			tension.append(i)
			
	var _tension_ratio = tension_ratio / tension.size()
	var _resolve_ratio = resolve_ratio / (columns.size() - tension.size())
			
	for i in range(len(matrix)):
		if tension.size() == 0:
			break
			
		if i in tension:
			for j in range(len(matrix[i])):
				if matrix[j][i] != 1:
					matrix[j][i] *= _tension_ratio + 1
				else:
					matrix[j][i] *= _tension_ratio
		else:
			for j in range(len(matrix[i])):
				if matrix[j][i] != 1:
					matrix[j][i] *= _resolve_ratio + 1
				else:
					matrix[j][i] *= _resolve_ratio
			
	#print_matrix()
	normalize_rows()
	#print_matrix()
	
func apply_step(step_ratio : float, note_info : NoteInfo):
	set_zeros_to_ones()
	var step = []
	
	for i in range(len(matrix)):
		step.append([])
		for j in range(len(matrix)):
			if note_info.is_step(columns[i], columns[j]):
				step[i].append(j)
			
	var step_ratios = []
	var leap_ratios = []
	
	if step.size() == 0:
		return
		
	for x in range(len(columns)):
		step_ratios.append(step_ratio / step[x].size())
		if columns.size() - step[x].size() != 0:
			leap_ratios.append(step_ratios[x] / (columns.size() - step[x].size()))
		else:
			leap_ratios.append(step_ratios[x] / 1)
			
	for i in range(len(matrix)):
		for j in range(len(step[i])):
			if j in step[i]:
				if matrix[j][i] != 1:
						matrix[j][i] *= step_ratios[j] + 1
				else:
					matrix[j][i] *= step_ratios[j]
			else:
				if matrix[j][i] != 1:
					matrix[j][i] *= leap_ratios[j] + 1
				else:
					matrix[j][i] *= leap_ratios[j]
			
	normalize_rows()
	#print_matrix()
	
func get_index_of_row(key : String):
	if columns.has(key):
		return columns.find(key)
