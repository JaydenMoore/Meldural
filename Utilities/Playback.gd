extends Node
class_name Playback

var note_info = NoteInfo.new()
var audioPlayer
var progressBar
var timer
var playButton
var wave = []
var playing = false

var index = -1

func _init(_wave):
	wave = _wave

func play(_audioPlayer, _progressBar, _timer, _playButton):
	if !audioPlayer:
		audioPlayer = _audioPlayer
		progressBar = _progressBar
		timer = _timer
		playButton = _playButton
		timer.connect("timeout", self, "play_note")
		audioPlayer.volume_db = -10
		progressBar.max_value = len(wave)
	
	playButton.text = "Stop"
	progressBar.value = 0
	index = -1
	playing = true
	timer = _timer
	play_note()
	
func stop():
	if audioPlayer:
		index = len(wave) - 1
		progressBar.value = 0
		audioPlayer.stop()
		playButton.text = "Play"

func play_note():
	index += 1
	if !index == len(wave):
		var note = wave[index]
		audioPlayer.stream = load("res://Samples".plus_file(note.pitch + ".ogg"))
		progressBar.value += 1
		audioPlayer.play()
		timer.start(timer_time(note_info.determine_note_length(note.length)))
	else:
		index = -1
		audioPlayer.stop()
		playing = false
		playButton.text = "Play"
		return
	
func timer_time(time):
	return time * ((60000 / (120.0 * 480)) / 1000)
