class_name Player
extends Character

@onready var enemy_slots : Array = $PrimaryEnemySlots.get_children()

func handle_input() -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	if can_attack() and Input.is_action_just_pressed("attack"):
		state = State.ATTACK
		if is_last_hit_successfull:
			attack_combo_index = (attack_combo_index + 1) % anim_attacks.size()
			is_last_hit_successfull = false
		else:
			attack_combo_index = 0
	if can_jump() and Input.is_action_just_pressed("jump"):
		state = State.TAKEOFF
	if can_jumpkick() and Input.is_action_just_pressed("attack"):
		state = State.JUMPKICK


func reserve_slot(enemy: BasicEnemy) -> EnemySlot:
	var available_slots := enemy_slots.filter(
		func(slot): return slot.is_free()
	)
	if available_slots.size() == 0:
		return null
	available_slots.sort_custom(
		func(a: EnemySlot, b: EnemySlot):
			var dist_a := (enemy.global_position - a.global_position).length()
			var dist_b := (enemy.global_position - b.global_position).length()
			return dist_a < dist_b
	)
	available_slots[0].occupy(enemy)
	return available_slots[0]

func free_slot(enemy: BasicEnemy) -> void:
	var target_slots := enemy_slots.filter(
		func(slot: EnemySlot): return slot.occupant == enemy
	)
	if target_slots.size() == 1:
		target_slots[0].free_up()

func set_heading():
	if velocity.x > 0: 
		heading = Vector2.RIGHT
	elif velocity.x < 0:
		heading =Vector2.LEFT
