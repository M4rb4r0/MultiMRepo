extends Node2D
var bullet_path:String
@export var type_bullet:String = 'boomerang'
@onready var bullet_scene = load("res://scenes/projectiles/bullet_"+type_bullet+".tscn")

@rpc("authority","call_local","reliable")
func shoot():
	var bullet = bullet_scene.instantiate() 
	bullet.pos_spawn = $Marker2D.global_position
	#print(get_parent().rotation)
	bullet.rotacion_spawn = get_parent().rotation
	get_parent().get_parent().get_parent().add_child(bullet,true)
	
