class_name proyectile
extends RigidBody2D
@export var speed = 100
@export var destroy_time = 0.8

var zona_colision:CollisionShape2D
var pos_spawn:Vector2
var rotacion_spawn:float
var dir:float
var animation:AnimatedSprite2D
var is_destroyed_timer: float
func _ready():
	global_position = pos_spawn
	global_rotation = rotacion_spawn
	dir = global_rotation
	apply_central_impulse(Vector2(speed,0).rotated(global_rotation))
	zona_colision = $CollisionShape2D
	animation = $AnimatedSprite2D
	is_destroyed_timer = -1
func _physics_process(delta: float) -> void:
	if not is_destroyed_timer < -0.5:
		#print('Explosion timer +=' + str(delta) )
		is_destroyed_timer = is_destroyed_timer + delta
		#print('timer actual = ' + str(is_destroyed_timer))
		if is_destroyed_timer > destroy_time:
			queue_free()
func _on_body_entered(body):
	explode.rpc()

@rpc("authority","call_local","reliable")
func explode(): 
	if is_destroyed_timer < -0.5 :
		print('Explosion')
		is_destroyed_timer = 0
		animation.animation = "Explotion"
		$".".sleeping = true
		$".".mass = 0
	

	
