extends Control
@onready var boton_iniciar = $VBoxContainer/Button
func _ready() -> void:
	if not is_multiplayer_authority():
		boton_iniciar.visible = false	
		
@rpc("authority","call_local")
func cambiar_escena(ruta):
	get_tree().change_scene_to_file(ruta)
func _on_button_pressed() -> void:
	cambiar_escena.rpc("res://scenes/main_game.tscn")
