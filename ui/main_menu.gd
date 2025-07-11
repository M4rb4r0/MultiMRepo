class_name MainMenu
extends Control


@onready var host: Button = %Host
@onready var join: Button = %Join
@onready var credits: Button = %Credits
@onready var quit: Button = %Quit


func _ready() -> void:
	print("host:", host)
	print("join:", join)
	print("credits:", credits)
	print("quit:", quit)

	if Game.multiplayer_test:
		get_tree().change_scene_to_file("res://lobby/lobby_test.tscn")
		return
	
	quit.pressed.connect(func(): get_tree().quit())
	host.pressed.connect(func(): get_tree().change_scene_to_file("res://lobby/host_screen.tscn"))
	join.pressed.connect(func(): get_tree().change_scene_to_file("res://lobby/join_screen.tscn"))
	credits.pressed.connect(func(): get_tree().change_scene_to_file("res://lobby/credits.tscn"))
	
	host.grab_focus()
