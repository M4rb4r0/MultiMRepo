extends Area2D


@onready var animator: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	
func _on_body_entered(body):
	print("body entered")
	if body.is_in_group("pullable"):
		pull(body)

func pull(target):
	print("pullable")
	var sprite = target.get_node("Sprite2D")
	if !sprite:
		sprite = target.get_node("AnimatedSprite2D")
	
	if target is Player:
		sprite = target.get_node("pivot/Sprite2D")
		target.recieve_damage()
		target.emit_signal("player_death")
	target.queue_free()
	var duplicated=sprite.duplicate()
	add_child(duplicated)
	duplicated.global_position = sprite.global_position
	var duration = animator.current_animation_length * animator.speed_scale *0.3
	var tween := create_tween()
	tween.tween_property(duplicated, "position", Vector2.ZERO, duration)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_IN)
	
	tween.tween_property(duplicated, "scale", Vector2.ZERO, duration*0.1)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_IN)
