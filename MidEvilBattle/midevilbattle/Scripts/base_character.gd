class_name Character
extends CharacterBody2D

const GRAVITY := 600.0
@export var can_respawn: bool
@export var damage : int
@export var damage_power : int
@export var duration_grounded: float
@export var jump_intensity : float
@export var knockback_intensity : float
@export var flight_speed : float
@export var knockdown_intensity : float
@export var max_health : int
@export var speed : float

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $Sprite
@onready var collateral_damage_emitter :Area2D= $CollatDamageEmitter
@onready var collision_shape := $CollisionShape2D
@onready var damage_emitter := $DamageEmitter
@onready var damage_receiver : DamageReceiver = $DamageReciver

var is_last_hit_successfull := false
enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LAND, JUMPKICK, HURT, FALL, GROUNDED, DEATH, FLY}
var anim_attacks := ["punch", "punch_alt", "punch_alt_2", "punch_alt_3"]
var attack_combo_index := 0
var anim_map : Dictionary = {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.TAKEOFF: "take_off",
	State.JUMP: "jump",
	State.LAND: "landing",
	State.JUMPKICK: "jump_kick",
	State.HURT: "hurt",
	State.FALL: "fall",
	State.GROUNDED: "grounded",
	State.DEATH: "grounded",
	State.FLY: "fly"
}
var current_health := 0
var height := 0.0
var height_speed := 0.0
var state := State.IDLE
var heading:= Vector2.RIGHT
var time_since_grounded := Time.get_ticks_msec()

func _ready() -> void:
	damage_emitter.area_entered.connect(on_emit_damage.bind())
	damage_receiver.damage_received.connect(on_receive_damage.bind())
	collateral_damage_emitter.area_entered.connect(on_emit_collarteral_damage.bind())
	collateral_damage_emitter.body_entered.connect(on_wall_hit.bind())
	current_health = max_health

func _process(delta: float) -> void:
	handle_input()
	handle_movement()
	handle_animations()
	handle_air_time(delta)
	handle_death(delta)
	set_heading()
	handle_grounded()
	flip_sprites()
	character_sprite.position = Vector2.UP * height
	collision_shape.disabled = is_collision_enabled()
	move_and_slide()

func handle_movement() -> void:
	if can_move():
		if velocity.length() == 0:
			state = State.IDLE
		else:
			state = State.WALK

func handle_input() -> void:
	pass

func handle_grounded() -> void:
	if state == State.GROUNDED and (Time.get_ticks_msec() - time_since_grounded > duration_grounded):
		if current_health <= 0:
			state = State.DEATH
		else:
			state = State.LAND
func handle_death(delta):
	if state == State.DEATH and not can_respawn:
		modulate.a -= delta / 2.0
		if modulate.a <= 0:
			queue_free()
		

func handle_animations() -> void:
	if state == State.ATTACK:
		animation_player.play(anim_attacks[attack_combo_index])
	elif animation_player.has_animation(anim_map[state]):
		animation_player.play(anim_map[state])

func handle_air_time(delta: float) -> void:
	if [State.JUMP, State.JUMPKICK, State.FALL].has(state):
		height += height_speed * delta
		if height < 0:
			height = 0
			if state == State.FALL:
				state = State.GROUNDED
				time_since_grounded = Time.get_ticks_msec()
			else:
				state = State.LAND
			velocity = Vector2.ZERO
		else:
			height_speed -= GRAVITY * delta
func set_heading():
	pass
func flip_sprites() -> void:
	if heading == Vector2.RIGHT:
		character_sprite.flip_h = false
		damage_emitter.scale.x = 1
	elif heading == Vector2.LEFT:
		character_sprite.flip_h = true
		damage_emitter.scale.x = -1

func can_move() -> bool:
	return state == State.IDLE or state == State.WALK

func can_attack() -> bool:
	return state == State.IDLE or state == State.WALK

func can_jump() -> bool:
	return state == State.IDLE or state == State.WALK

func can_jumpkick() -> bool:
	return state == State.JUMP
func can_get_hurt() -> bool:
	return [State.IDLE, State.WALK, State.TAKEOFF, State.JUMP, State.LAND].has(state)
	
func is_collision_enabled() -> bool:
	return [State.GROUNDED, State.DEATH, State.FLY].has(state)
func on_action_complete() -> void:
	state = State.IDLE

func on_takeoff_complete() -> void:
	state = State.JUMP
	height_speed = jump_intensity

func on_land_complete() -> void:
	state = State.IDLE
	
func on_wall_hit(wall: AnimatableBody2D):
	state = State.FALL
	height_speed = knockback_intensity
	velocity = -velocity / 2.0

func on_receive_damage(amount: int, direction: Vector2, hit_type: DamageReceiver.HitType) -> void:
	if can_get_hurt():
		current_health = clamp(current_health - amount, 0, max_health)
		if current_health == 0 or hit_type == DamageReceiver.HitType.KNOCKDOWN:
			state = State.FALL
			height_speed = knockdown_intensity
			velocity = direction * knockback_intensity
		elif hit_type == DamageReceiver.HitType.POWER:
			state = State.FLY
			velocity = direction * flight_speed
		else:
			state = State.HURT
			velocity = direction * knockback_intensity
func on_emit_collarteral_damage(receiver: DamageReceiver):
	if receiver != damage_receiver:
		var direction := Vector2.LEFT if receiver.global_position.x < global_position.x else Vector2.RIGHT
		receiver.damage_received.emit(0, direction, DamageReceiver.HitType.KNOCKDOWN)
	
func on_emit_damage(receiver: DamageReceiver) -> void:
	var hit_type := DamageReceiver.HitType.NORMAL
	var direction := Vector2.LEFT if receiver.global_position.x < global_position.x else Vector2.RIGHT
	var current_damage = damage
	is_last_hit_successfull = true
	if state == State.JUMPKICK:
		hit_type = DamageReceiver.HitType.KNOCKDOWN
		is_last_hit_successfull = false
		attack_combo_index = 0
	if attack_combo_index == anim_attacks.size() -1:
		hit_type = damage_receiver.HitType.POWER
		current_damage = damage_power
	receiver.damage_received.emit(current_damage, direction, hit_type)
	
