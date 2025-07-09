extends RigidBody2D

@export var affected_by_gravity := true
@export var infinite_health := false

var alive := true

func _ready():
	if not affected_by_gravity:
		gravity_scale = 0

@rpc("authority", "call_local", "reliable")
func recieve_damage():
	if not alive:
		return

	if infinite_health:
		print("Bloque ignoró daño (vida infinita)")
		return

	print("Bloque destruido por daño")
	explode()

func explode():
	alive = false
	send_state.rpc(alive)
	queue_free()

@rpc("authority")
func send_state(state: bool):
	alive = state
