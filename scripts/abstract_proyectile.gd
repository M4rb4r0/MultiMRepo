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
@onready var despawn_timer = 20

func _ready():
	global_position = pos_spawn
	
#	if abs(rotacion_spawn) > PI/2:
#		$AnimatedSprite2D.flip_h = true

	dir = rotacion_spawn
	apply_central_impulse(Vector2(speed,0).rotated(rotacion_spawn))
	zona_colision = $CollisionShape2D
	animation = $AnimatedSprite2D
	is_destroyed_timer = -1
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var max_vel = 3000
	$".".linear_velocity = linear_velocity.clamp(Vector2(-max_vel,-max_vel),Vector2(max_vel,max_vel))
func _physics_process(delta: float) -> void:
	despawn_timer -= delta
	print(despawn_timer)
	if despawn_timer < 0:
		explode.rpc()
	$AnimatedSprite2D.rotation = lerp($AnimatedSprite2D.rotation,$".".linear_velocity.angle(),0.8)
	
	if not is_destroyed_timer < -0.5:
		#print('Explosion timer +=' + str(delta) )
		is_destroyed_timer = is_destroyed_timer + delta
		#print('timer actual = ' + str(is_destroyed_timer))
		if is_destroyed_timer > destroy_time:
			queue_free()
func _on_body_entered(body):
	if is_multiplayer_authority():
		explode.rpc()
		

@rpc("authority","call_local","reliable")
func explode(): 
	if is_destroyed_timer < -0.5 :
		print('Explosion')
		is_destroyed_timer = 0
		animation.animation = "Explotion"
		$".".set_sleeping(true)
		$CollisionShape2D.set_deferred("disabled", true)
