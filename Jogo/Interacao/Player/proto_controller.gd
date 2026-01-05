extends CharacterBody3D

@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = false
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_forward : String = "ui_up"
@export var input_back : String = "ui_down"
@export var input_jump : String = "ui_accept"
@export var input_sprint : String = "sprint"
@export var input_freefly : String = "freefly"

var allow_auto_capture: bool = true

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
# --- ADICIONADO: referências aos AudioStreamPlayers ---
@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var jump_player: AudioStreamPlayer = $JumpPlayer
# -------------------------------------------------------

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	# Garante que o estado inicial do mouse seja capturado (se não estiver no menu)
	capture_mouse() 

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if allow_auto_capture and not mouse_captured:
			capture_mouse()

	# ESC (ou sua tecla de inventário/menu)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Se a tecla ESC liberar o mouse, o movimento será pausado no _physics_process
		if mouse_captured:
			release_mouse()
		else:
			capture_mouse() # Volta ao jogo

	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func disable_auto_capture():
	allow_auto_capture = false
	release_mouse()

func enable_auto_capture():
	allow_auto_capture = true

func _physics_process(delta: float) -> void:
	# 1. VERIFICA ESTADO DO MOUSE: Se o mouse não está capturado, NÃO PODE MOVER
	if not mouse_captured and not freeflying:
		# Se o mouse não estiver capturado (inventário/menu visível), para o player imediatamente.
		velocity.x = 0
		velocity.z = 0
		# --- ADICIONADO: garante que som de passos pare quando não pode mover ---
		if footstep_player.playing:
			footstep_player.stop()
		# ---------------------------------------------------------------
		move_and_slide()
		return
		
	# 2. Lógica de Freefly (se ativo)
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		# durante freefly, não tocar passos
		if footstep_player.playing:
			footstep_player.stop()
		return

	# 3. Lógica de Gravidade
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# 4. Lógica de Pulo
	if can_jump:
		# --- MODIFICADO: tocar som de pulo quando pular ---
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity
			if jump_player:
				jump_player.play()
	# ---------------------------------------------------------

	# 5. Lógica de Sprint
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# 6. Lógica de Movimento A/D/W/S (Só chega aqui se o mouse estiver CAPTURADO)
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0

	# --- ADICIONADO: Lógica simples de passos ---
	# Se está no chão e movendo-se horizontalmente (velocidade > limiar), toca passos.
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var step_threshold := 0.5 # ajuste se necessário (valor mínimo para considerar "andando")
	if is_on_floor() and horizontal_speed > step_threshold and not freeflying and mouse_captured:
		if footstep_player and not footstep_player.playing:
			footstep_player.play()
	else:
		# para o som de passos se não estiver andando
		if footstep_player and footstep_player.playing:
			footstep_player.stop()
	# ------------------------------------------------

	move_and_slide()

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO
	# garantir que passos parem ao entrar em freefly
	if footstep_player.playing:
		footstep_player.stop()

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		can_freefly = false
