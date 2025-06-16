extends RigidBody3D
class_name Frog

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
#@onready var audioStreamPlayer = $AudioStreamPlayer3D
@export var minRandomForce = 25
@export var maxRandomForce = 50
@export var twerk_speed = 1.0
@export var twerk_amount = 1.0

@onready var top = $top
@onready var bottom = $bottom
@onready var twerk_bone = $frog/Armature_001/Skeleton3D/Jigglebone_TOP

var isMoving = false
var jump_timer = 0.0
var jump_timer_dur = 7.0
var twerk_timer = 0.0
var twerk_timer_dur = 0.5


func _ready() -> void:
	pass
	#self.connect("body_entered", Callable(self, "play_hit_sound"))
	
func _process(delta: float) -> void:
	jump_timer -= delta
	if jump_timer < 0.0:
		roll_frog(10.0, 3.0)
		

func _physics_process(delta: float) -> void:
	isMoving = linear_velocity.length() > 0.1 + delta * 0
	if !isMoving:
		if top.global_position.y <= bottom.global_position.y:
			#jump_timer = randf_range(jump_timer_dur, jump_timer_dur * 4.0)
			roll_frog(1.0, 0.5)
		else:
			twerk_timer += delta
			twerk_bone.position.x += twerk_amount / 200 - sin(twerk_timer * twerk_speed) * twerk_amount / 100
			twerk_bone.position.z += twerk_amount / 200 - sin(twerk_timer * twerk_speed) * twerk_amount / 100
			twerk_bone.position.y += twerk_amount / 200 - cos(twerk_timer * twerk_speed) * twerk_amount / 100
			apply_torque(Vector3(0.01, 0.01, 0.01))
	
#func play_hit_sound(body: Node):
	##print("playing sound")
	#var random_sound
	#if body is Dice:
		#random_sound = sound_list[randi() % sound_list.size()]
	#else:
		#random_sound = ground_sound_list[randi() % ground_sound_list.size()]
	#audioStreamPlayer.stream = random_sound
	#audioStreamPlayer.play()
	
##func _unhandled_input(event):
	##if event is InputEventMouseButton and event.pressed:
		##roll_dice()

func roll_frog(torque_intensity, force_intensity):
	jump_timer = randf_range(jump_timer_dur, jump_timer_dur * 4.0)
	if isMoving: 
		pass
		#return
	
	var rng = RandomNumberGenerator.new()
	var randomDirection = [-1, 1]
	var force = Vector3.ZERO
	var force_displace = Vector3.ZERO
	
	force_displace.x += -position.z
	force_displace.z += position.x
	
	force.x = rng.randi_range(minRandomForce, maxRandomForce) * sign(force_displace.x)
	force.y = rng.randi_range(minRandomForce, maxRandomForce) * randomDirection.pick_random()
	force.z = rng.randi_range(minRandomForce, maxRandomForce) * sign(force_displace.z)
	
	
	apply_torque(force * torque_intensity)
	apply_force(Vector3(force.x * force_intensity, 120.0 * 2 * force_intensity, force.z * force_intensity))
