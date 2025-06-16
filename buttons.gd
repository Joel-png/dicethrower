extends Control
var dice_spawnpath

@export var node_to_delete: Node


func _on_clearbutton_pressed() -> void:
	var nodes = node_to_delete.get_children()
	for node in nodes:
		for child in node.get_children():
			child.queue_free()
