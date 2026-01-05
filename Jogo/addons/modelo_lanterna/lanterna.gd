extends Node3D


func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("Toggle"): 
		if $Bateria.value > 0:
			$Luz.light_energy = 16
		else:
			$Luz.light_energy = 0
	else:
		$Luz.light_energy = 0

func _physics_process(delta: float) -> void:
	if $Luz.light_energy == 16:
		$Bateria.value -= 1
