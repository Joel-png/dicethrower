extends Node3D
@onready var player = $Player
@onready var dice = $Dice

func _ready() -> void:
	add_to_group("world")
