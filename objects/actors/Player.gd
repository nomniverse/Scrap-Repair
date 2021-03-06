extends Actor

# Player class adapted from GDQuest 2D Platformer demo
class_name Player

onready var dialogue_display = $ChatBubble/Dialogue
onready var game_message_display = $ChatBubble2/GameMessage

onready var futility_timer = $FutilityTimer

const FLOOR_DETECT_DISTANCE = 40.0

var interactable_object = null

var parts_held = 0
var has_battery = false

var lang = "en"
var last_dialogue_part = ""
var last_game_message_part = ""

var respawn_point

export (String) var character = "robot1"

# Called when the node enters the scene tree for the first time.
func _ready():
	respawn_point = global_position
	
	$AnimationPlayer.play(character + "_idle")
	
# Called when input is pressed
func _input(event):
	if event.is_action_pressed("interact"):
		if interactable_object != null:
			interact_with()
				
	if event.is_action_pressed("pause"):
		$PauseMenu.show()
		get_tree().paused = true

# Called every physics tick
func _physics_process(delta):
	var direction = get_direction()
	
	var is_jump_interrupted = Input.is_action_just_released("jump") and _velocity.y < 0.0

	_velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted)
	
	var snap_vector = Vector2.DOWN * 32 if direction.y == 0.0 else Vector2.ZERO
	
	var is_on_platform = $PlatformDetector.is_colliding()
	
	_velocity = move_and_slide_with_snap(
		_velocity, snap_vector, FLOOR_NORMAL, is_on_platform, 4,  0.9, false
	)
	
	if direction.x != 0:
		$Sprite.scale.x = direction.x
		
		if direction.x > 0:
			$HoldPosition2D.position.x = 25
		else:
			$HoldPosition2D.position.x = -25

	set_animation()
	
func interact_with():
	interactable_object.interact(self)
	
func die():
	global_position = respawn_point
	
func set_animation():
	if is_on_floor():
		if _velocity.x != 0:
			$AnimationPlayer.play(character + "_walk")
		else:
			$AnimationPlayer.play(character + "_idle")
	else:
		$AnimationPlayer.play(character + "_idle")
	
func get_direction():
	var is_jumping = Input.is_action_just_pressed("jump")
	
	if is_jumping and is_on_floor():
		$JumpSoundEffect2D.play()
	
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-Input.get_action_strength("jump") if is_on_floor() and is_jumping else 0.0
	)

func calculate_move_velocity(
		linear_velocity,
		direction,
		speed,
		is_jump_interrupted
	):
	
	var velocity = linear_velocity
	velocity.x = speed.x * direction.x
	if direction.y != 0.0:
		velocity.y = speed.y * direction.y
	if is_jump_interrupted:
		velocity.y = 0.0
	return velocity

func set_interactable_object(object):
	if interactable_object != null and interactable_object.has_method("is_held"):
		if not interactable_object.is_held():
			interactable_object = object
	else:
		interactable_object = object

func show_dialogue_part(part, is_game_message, duration):
	if is_game_message:
		game_message_display.text = tr(part)
		$ChatBubble2.visible = true
		$GameMessageTimer.wait_time = duration
		last_game_message_part = part
		$GameMessageTimer.start()
	else:
		dialogue_display.text = tr(part)
		$ChatBubble.visible = true
		$DialogueTimer.wait_time = duration
		last_dialogue_part = part
		$DialogueTimer.start()

func _on_DialogueTimer_timeout():
	$ChatBubble.visible = false
	dialogue_display.text = ""
	
	if last_dialogue_part == "Reunion":
		get_tree().change_scene("res://menus/EndCredits.tscn")

func _on_GameMessageTimer_timeout():
	$ChatBubble2.visible = false
	game_message_display.text = ""
	
	if last_game_message_part == "Bebop":
		get_tree().change_scene("res://menus/EndCredits.tscn")

func _on_FutilityTimer_timeout():
	show_dialogue_part("Futility", false, 7)
	
	GameVariables.can_swap = true
	
	get_tree().get_root().get_node("Game/NormalAudioStreamPlayer").playing = false
	get_tree().get_root().get_node("Game/FutileAudioStreamPlayer").playing = true
