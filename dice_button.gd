extends Control
@export var label_text: String
@export var scene_to_spawn: PackedScene
@export var node_to_spawn: Node
var world
var player

@onready var label = $Label

func _ready() -> void:
	update_label()
	call_deferred("_init_later")
	

func _init_later():
	world = get_tree().get_nodes_in_group("world")[0]
	player = world.player
	spawn_scene()

func update_label():
	label.text = label_text

func spawn_scene():
	var instance = scene_to_spawn.instantiate()
	if node_to_spawn != null:
		node_to_spawn.add_child(instance)
		print(player.position)
		instance.position = Vector3(player.position.x, player.position.y + 10.0, player.position.z)
	
func delete_scene():
	var children = node_to_spawn.get_children()
	if children.size() > 0:
		var first_child = children[0]
		first_child.queue_free()
	
func _on_plus_button_pressed() -> void:
	print("+" + label_text)
	spawn_scene()

func _on_minus_button_pressed() -> void:
	print("-" + label_text)
	delete_scene()
