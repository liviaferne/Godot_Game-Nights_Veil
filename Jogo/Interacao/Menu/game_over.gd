extends Node2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_retornar_pressed() -> void:
	get_tree().change_scene_to_file("res://Interacao/Menu/main_menu.tscn")
