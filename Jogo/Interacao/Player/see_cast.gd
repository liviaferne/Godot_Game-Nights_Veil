extends RayCast3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# O RayCast será ativado e configurado (target_position e collision_mask)
	# no Godot Editor ou através do PlayerInteractionHandler.
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# A lógica de interação/coleta é verificada no _input do PlayerInteractionHandler.
	pass
