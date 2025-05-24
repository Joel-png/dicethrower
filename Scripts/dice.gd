extends RigidBody3D
class_name Dice

var sound_list = [
	preload("res://sounds/dicehit01.wav"),
	preload("res://sounds/dicehit02.wav"),
	preload("res://sounds/dicehit03.wav"),
	preload("res://sounds/dicehit04.wav")
]
var ground_sound_list = [
	preload("res://sounds/groundhit01.wav"),
	preload("res://sounds/groundhit02.wav"),
	preload("res://sounds/groundhit03.wav"),
	preload("res://sounds/groundhit04.wav")
]
@onready var audioStreamPlayer = $AudioStreamPlayer3D
@export var minRandomForce = 25
@export var maxRandomForce = 50

var isMoving = false

func _ready() -> void:
	self.connect("body_entered", Callable(self, "play_hit_sound"))
	
func _physics_process(delta: float) -> void:
	isMoving = linear_velocity.length() > 0.1 + delta * 0
	if !isMoving:
		apply_torque(Vector3(0.01, 0.01, 0.01))
	
func play_hit_sound(body: Node):
	#print("playing sound")
	var random_sound
	if body is Dice:
		random_sound = sound_list[randi() % sound_list.size()]
	else:
		random_sound = ground_sound_list[randi() % ground_sound_list.size()]
	audioStreamPlayer.stream = random_sound
	audioStreamPlayer.play()
	
##func _unhandled_input(event):
	##if event is InputEventMouseButton and event.pressed:
		##roll_dice()

func roll_dice():
	if isMoving: 
		return
	
	var rng = RandomNumberGenerator.new()
	var randomDirection = [-1, 1]
	var force = Vector3.ZERO
	var force_displace = Vector3.ZERO
	
	force_displace.x += -position.z
	force_displace.z += position.x
	
	force.x = rng.randi_range(minRandomForce, maxRandomForce) * sign(force_displace.x)
	force.y = rng.randi_range(minRandomForce, maxRandomForce) * randomDirection.pick_random()
	force.z = rng.randi_range(minRandomForce, maxRandomForce) * sign(force_displace.z)
	
	
	apply_torque(force)
	apply_force(Vector3(force.x / 2.0, 120.0, force.z / 2.0))
