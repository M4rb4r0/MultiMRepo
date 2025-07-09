class_name Player
extends CharacterBody2D

@export var health = 2
@export var jump_charges = 2
@export var max_speed = 300
@export var acceleration = 5000
@export var is_invincible = false
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree["parameters/Movement/playback"]
@onready var label: Label = $Label
@onready var pivot: Node2D = $pivot
@onready var weapon_container = $WeaponContainer
@onready var weapon = $WeaponContainer/AbstractWeapon
@onready var shoot_timer: Timer = $shootTimer
@onready var charge_power: float = 0
@onready var is_charging_weapon = false
@onready var shield: Sprite2D = $pivot/Sprite2D/Shield
@onready var parry_area: Area2D = $ParryArea
@onready var parry_timer: Timer = $parryTimer
@onready var bat: Sprite2D = $pivot/BatParry

#sound effects
@onready var shoot_charge_sound: AudioStreamPlayer2D = $ShootChargeSound
@onready var gun_shot_sound: AudioStreamPlayer2D = $GunShotSound
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var walking_sound: AudioStreamPlayer2D = $WalkingSound

@onready var camera_2d: Camera2D = $Camera2D
@onready var gravityArea = $GravityArea

@onready var sprite_2d: Sprite2D = $pivot/Sprite2D
var can_shoot = true
var can_jump = true
var can_parry = true
var parry_vel = 5000
var jump_velocity = 1500
var direction= Vector2.ZERO
var rotation_speed= 2
var spawn_point = Vector2.ZERO
var target_zoom := Vector2(0.5,0.5)
signal player_death
func setup(player_data: Statics.PlayerData,invincible = false):
	label.text = player_data.name
	name = str(player_data.id)
	set_multiplayer_authority(player_data.id)
	if is_multiplayer_authority():
			camera_2d.make_current()
	shoot_timer.timeout.connect(on_shoot_timer_timeout)
	is_invincible = invincible
		
var AttractedBy = []

func _physics_process(delta: float) -> void:
	for gravity in AttractedBy:
		if not is_on_floor():
			velocity += (gravity.get_global_position() - get_global_position()) * 0.4
		
	var initial_move_input=Vector2.ZERO
	
	if is_multiplayer_authority():
		camera_2d.zoom = camera_2d.zoom.lerp(target_zoom, 5 * delta)
		if AttractedBy.is_empty():
			# ROTACIÓN
			var turn_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
			rotation += turn_input * rotation_speed * delta

			# MOVIMIENTO HACIA ADELANTE/ATRÁS
			var forward_input = Input.get_action_strength("jump") * 0.1
			
			if forward_input != 0:
				# Aumentar velocidad en la dirección actual
				var direction = Vector2.UP.rotated(rotation)
				velocity += direction * acceleration * forward_input * delta
			var drag = 0.99
			# Aplicar freno por inercia
			velocity *= drag
			# Limitar velocidad máxima
			if velocity.length() > max_speed:
				velocity = velocity.normalized() * max_speed

			# Mover
			position += velocity * delta

			send_data.rpc(position, velocity, sign(forward_input), rotation)
		
		else:
			initial_move_input = Input.get_axis("move_left", "move_right")
			var move_input = Vector2(initial_move_input,0).rotated(get_global_rotation())
			direction= sign(initial_move_input)
			velocity= velocity.move_toward(move_input * max_speed, acceleration * delta)
			if is_on_floor():
				jump_charges = 2
				can_jump = true
			send_data.rpc(position, velocity, direction)
		
		if Input.is_action_just_pressed("jump") and can_jump:
			for gravity in AttractedBy:
				var gravity_direction = (gravity.get_global_position() - get_global_position()).normalized()
				velocity -= gravity_direction * jump_velocity
				jump_charges -= 1
				if jump_charges == 0:
					can_jump = false
					AttractedBy = []
			
		weapon_container.look_at(get_global_mouse_position())
		if is_charging_weapon:
			charge_power = min(charge_power + delta ,5)
			if charge_power > 4.0:
				weapon.overcharge()
		if Input.is_action_just_pressed('fire') and can_shoot:
			#weapon.shoot.rpc()
			shoot_charge_sound.play()
			weapon.begin_charge.rpc()
			is_charging_weapon = true
		if Input.is_action_just_released('fire') and can_shoot and is_charging_weapon:
			shoot_charge_sound.stop()
			gun_shot_sound.play()
			weapon.shoot.rpc(min(charge_power,2))
			shoot_timer.start()
			can_shoot = false
			charge_power = 0.2
			is_charging_weapon = false
		
		if Input.is_action_just_pressed('right_click') and can_parry:
			can_parry = false
			parry_timer.start()
			animation_tree["parameters/parry/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			if (parry_area.has_overlapping_bodies()):
				for i in parry_area.get_overlapping_bodies():
					if i.is_in_group("throwable"):
						i.linear_velocity = Vector2(0,0)
						Debug.log(global_position.distance_to(i.get_global_position()))
						parry_vel = inverse_lerp(0,1,global_position.distance_to(i.get_global_position()))*50
						Debug.log(parry_vel)
						i.apply_central_impulse(Vector2(parry_vel,0).rotated(weapon_container.get_global_rotation()))
			
			

	if not AttractedBy.is_empty():
		look_at(AttractedBy[0].get_global_position())
		rotate(-PI/2)
		up_direction = -global_transform.y
	move_and_slide()
	
	if direction:
		playback.travel("walk")
		pivot.scale.x = sign(direction)
	else:
		if is_on_floor():
			playback.travel("idle")
	
	if Input.is_action_just_pressed("jump") && not AttractedBy.is_empty():
		jump_sound.play()
		playback.travel("jump")
	
	if AttractedBy.is_empty():
		playback.travel("fly")


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom *= Vector2(0.9, 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom *= Vector2(1.1, 1.1)
		# Limitar el zoom entre 0.5x y 3x
		target_zoom.x = clamp(target_zoom.x, 0.2, 2.0)
		target_zoom.y = clamp(target_zoom.y, 0.2, 2.0)
	

@rpc("unreliable_ordered")
func send_data(pos: Vector2, vel: Vector2, dir: float, rot=0.0) -> void:
	position = lerp(position, pos, 0.3)
	velocity = vel
	
	if AttractedBy.is_empty():
		rotation = rot
	else:
		direction = dir

func _on_area_2d_area_entered(area: Area2D) -> void:
	AttractedBy.append(area)

func _on_area_2d_area_exited(area: Area2D) -> void:
	AttractedBy.erase(area)

func on_shoot_timer_timeout() -> void:
	can_shoot = true
	
func play_step() -> void:
	walking_sound.play()

@rpc("call_local", "authority","reliable")
func recieve_damage():
	print("recibo daño")
	if is_invincible:
		print("Es invencible")
		return
	if health == 2:
		health = 1
		shield.visible = false
	else:
		position = spawn_point
		health = 2
		shield.visible = true
		emit_signal("player_death")
		queue_free()

func _ready():
	parry_timer.timeout.connect(_on_parry_timer_timeout)
	
func _on_parry_timer_timeout():
	can_parry = true
	var tween = create_tween()
	tween.tween_property(bat, "modulate",Color(2,2,2), 0.1)
	tween.tween_property(bat, "modulate",Color(1,1,1), 0.05)
	
