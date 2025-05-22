extends Control

@onready var color1 = $Color1
@onready var color2 = $Color2
@onready var file_dialog = $LoadDialog
@onready var save_dialog = $SaveDialog
var base_material = preload("res://material/dice_material.tres")
var edge_material = preload("res://material/dice_material_edge.tres")
var inner_material = preload("res://material/dice_material_inner.tres")
var droppable_rects
var inner_is_color2 = false
var current_path

func _ready():
	get_tree().get_root().files_dropped.connect(_on_files_dropped)
	update_grad_color()
	DirAccess.make_dir_recursive_absolute("user://saved_dice")

func _on_files_dropped(files):
	var path = files[0]
	load_path(path)

func load_path(path):
	var image = Image.new()
	image.load(path)
	current_path = path
	
	var image_texture = ImageTexture.new()
	image_texture.set_image(image)
	
	select_correct_material(image_texture)

func select_correct_material(texture):
	update_material_with_texture(base_material, texture)
	update_material_with_texture(edge_material, texture)

func update_material_with_texture(material_to_update, texture) -> void:
	print(current_path)
	material_to_update.albedo_texture = texture

func check_hovered():
	for rect in droppable_rects:
		if mouse_over_control(rect):
			return(rect.name)

func mouse_over_control(node: Control):
	var mouse = get_global_mouse_position()
	if mouse.x < node.global_position.x \
		or mouse.x > node.global_position.x + node.size.x \
		or mouse.y < node.global_position.y \
		or mouse.y > node.global_position.y + node.size.y:
		return false
	return true

func update_grad_color():
	var texture = generate_vertical_gradient_texture(color1.color, color2.color, 1, 256)
	update_material_with_texture(inner_material, texture)
	$TextureRect.texture = texture

func generate_vertical_gradient_texture(top_color: Color, bottom_color: Color, width := 1, height := 256) -> ImageTexture:
	var image := Image.create(width, height * 2, false, Image.FORMAT_RGBA8)
	if inner_is_color2:
		image.fill(bottom_color)
	else:
		image.fill(top_color)
		
	for y in height:
		var t := float(y) / float(height - 1)
		var color
		if inner_is_color2:
			color = bottom_color.lerp(top_color, t)
		else:
			color = top_color.lerp(bottom_color, t)
		for x in width:
			image.set_pixel(x, y + height, color)

	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	return texture

func save_dice(save_name):
	var image = Image.new()
	var load_err = image.load(current_path)
	if load_err != OK:
		printerr("Failed to load image current path")
		return
	
	print(save_name)
	var image_file_name = save_name + ".png"
	var file_path = "user://saved_dice/" + image_file_name
	
	DirAccess.make_dir_recursive_absolute("user://saved_dice")
	
	var save_err = image.save_png(file_path)
	if save_err != OK:
		printerr("Failed to save image to user data folder")
		return
	
	var data = {
		"current_path": file_path,
		"gradient_top": color1.color,
		"gradient_bottom": color2.color
	}
	
	var file = FileAccess.open("user://saved_dice//" + save_name + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_dice(json_data):
	current_path = json_data["current_path"]
	color1.color = parse_color_string(json_data["gradient_top"])
	color2.color = parse_color_string(json_data["gradient_bottom"])
	update_grad_color()
	load_path(current_path)
	
func parse_color_string(color_string: String) -> Color:
	# Remove parentheses and split
	var parts = color_string.strip_edges().trim_prefix("(").trim_suffix(")").split(",")
	if parts.size() == 4:
		print(Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), parts[3].to_float()))
		return Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
	return Color.WHITE

func _on_check_button_toggled(toggled_on: bool) -> void:
	inner_is_color2 = toggled_on

func _on_check_button_pressed() -> void:
	update_grad_color()

func _on_color_1_color_changed(_color: Color) -> void:
	update_grad_color()

func _on_color_2_color_changed(_color: Color) -> void:
	update_grad_color()

func _on_save_pressed() -> void:
	var file_name = current_path.get_file()
	var save_name = file_name.get_basename()
	save_dialog.current_file = save_name + ".json"
	DirAccess.make_dir_recursive_absolute("user://saved_dice")
	save_dialog.popup_centered()

func _on_load_pressed() -> void:
	file_dialog.popup_centered()

func _on_file_dialog_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file.")
		return

	var content := file.get_as_text()
	var data = JSON.parse_string(content)

	if typeof(data) == TYPE_DICTIONARY:
		print("Loaded JSON:", data)
	else:
		push_error("Invalid JSON format.")
		
	load_dice(data)

func _on_save_dialog_file_selected(path: String) -> void:
	var file_name = save_dialog.current_file.get_file()
	var save_name = file_name.get_basename()
	save_dice(save_name)
