extends Control

onready var UIContainer = $UIContainer
onready var status = UIContainer.get_node("Background/Status")

onready var FileNames = UIContainer.get_node("FileNames")
onready var inputFileName = FileNames.get_node("InputFileName")
onready var outputFileName = FileNames.get_node("OutputFileName")

onready var Buttons = UIContainer.get_node("Buttons")
onready var chooseInputButton = Buttons.get_node("ChooseInput")
onready var chooseOutputButton = Buttons.get_node("ChooseOutput")
onready var exportButton = Buttons.get_node("Export")
onready var generateButton = Buttons.get_node("Generate")

onready var Playback = UIContainer.get_node("Playback")
onready var progressBar = Playback.get_node("ProgressBar")
onready var playButton = Playback.get_node("Play")
onready var audioPlayer = Playback.get_node("AudioStreamPlayer")
onready var timer = Playback.get_node("Timer")

onready var fd = get_parent().get_parent().get_node("FileDialog")

var proceduralMelody = MelodyGivenInput2.new()
var rng = RandomNumberGenerator.new()
var playback

var input_file
var output_file

var choosing_output = false
var output_chosen = false

func _ready():
	chooseInputButton.connect("pressed", self, "handle_choose_input")
	chooseOutputButton.connect("pressed", self, "handle_choose_output")
	exportButton.connect("pressed", self, "handle_export")
	generateButton.connect("pressed", self, "handle_generate")
	playButton.connect("pressed", self, "handle_playback")
	fd.connect("file_selected", self, "handle_file_chosen")
	
func handle_choose_input():
	fd.visible = true
	choosing_output = false
	fd.mode = FileDialog.MODE_OPEN_FILE
	
func handle_file_chosen(path : String):
	if ".mid" in path && !choosing_output:
		var file_name = path.get_file()
		inputFileName.text = "File Name: " + file_name
		input_file = path
		if !output_chosen:
			outputFileName.text = "File Name: " + file_name.get_basename() + "Output" + ".mid"
			output_file = path.substr(0, path.find_last("/") + 1) + file_name.get_basename() + "Output" + ".mid"
		generateButton.disabled = false
		playButton.disabled = true
		if playback:
			playback.stop()
		status.text = "Status: Not Generated"
	elif ".mid" in path && choosing_output:
		var file_name = path.get_file()
		outputFileName.text = "File Name: " + file_name
		output_file = path
		output_chosen = true
	else:
		if choosing_output: 
			handle_invalid_path(outputFileName)
		else:
			handle_invalid_path(inputFileName)
			generateButton.disabled = true
		
func handle_invalid_path(label : Node):
	label.text = "Invalid File Type"
	label.set("custom_colors/font_color", Color.red)
	yield(get_tree().create_timer(2), "timeout")
	label.set("custom_colors/font_color", Color.white)
	label.text = "File Name: "
		
func handle_choose_output():
	fd.visible = true
	choosing_output = true
	fd.mode = FileDialog.MODE_SAVE_FILE

func handle_export():
	status.text = "Status: Exporting"
	proceduralMelody.render_output(output_file)
	rng.randomize()
	yield(get_tree().create_timer(rng.randf_range(1,2)), "timeout")
	status.text = "Status: Exported"
	
func handle_generate():
	exportButton.disabled = true
	playButton.disabled = true
	status.text = "Status: Generating"
	if playback != null:
		playback.stop()
		playback.queue_free()
	else:
		proceduralMelody.connect("finished", self, "finished_generating")
	yield(get_tree().create_timer(0.5), "timeout")
	playback = proceduralMelody.generate(input_file)

func finished_generating():
	status.text = "Status: Generated"
	exportButton.disabled = false
	playButton.disabled = false

func handle_playback():
	if !playback.get_parent():
		add_child(playback)
		
	if playback && !playback.playing:
		playback.play(audioPlayer, progressBar, timer, playButton)
	else:
		playback.stop()

func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		if playback:
			playback.queue_free()
		if proceduralMelody:
			proceduralMelody.queue_free()
