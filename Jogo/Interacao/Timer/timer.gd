extends Node

@onready var label = $Label
@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.start()
	

func tempo_restante():
	var time_left = timer.time_left
	var minutos = floor(time_left/60)
	var segundos = int(time_left)%60
	if minutos==0 and segundos==0:
		timeout()
	return [minutos, segundos]


func timeout():
	get_tree().change_scene_to_file("res://Interacao/Menu/game_over.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	label.text = "%02d:%02d"%tempo_restante()
