extends Control

@onready var crosshair_text = $CrosshairText
var crosshair_text_timer: float = 0.0
var crosshair_text_countdown: float = 0.2

func _ready() -> void:
	if !is_multiplayer_authority():
		hide()

func _process(delta: float) -> void:
	crosshair_text_timer -= delta
	if crosshair_text_timer <= 0:
		clear_crosshair_text()

func display_crosshair_text(text: String) -> void:
	crosshair_text.text = text
	crosshair_text_timer = crosshair_text_countdown
	
func clear_crosshair_text() -> void:
	crosshair_text.text = ""
