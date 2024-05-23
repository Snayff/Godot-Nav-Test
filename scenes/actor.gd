class_name Actor
extends CharacterBody2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const movement_speed: float = 80.0
enum STATE {
	MOVING,
	IDLE
}

var target_destination: Vector2 = Vector2.ZERO
var current_state: int = STATE.IDLE

func _ready() -> void:
	EventBus.connect("destination_set", set_destination)
	nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))

	set_state(STATE.IDLE)

func _process(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		set_state(STATE.IDLE)
	else:
		set_state(STATE.MOVING)

func _physics_process(delta) -> void:
	if current_state == STATE.MOVING and target_destination != Vector2.ZERO:	
		var next_path_pos: Vector2 = nav_agent.get_next_path_position()
		var new_velocity: Vector2 = global_position.direction_to(next_path_pos) * movement_speed
		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(new_velocity)
		else:
			_on_velocity_computed(new_velocity)

func set_destination(destination: Vector2) -> void:
	target_destination = destination
	update_path()  # do immediately, dont queue

func update_path() -> void:
	nav_agent.target_position = target_destination
	
func queue_update_path() -> void:
	Pathing.add_to_path_refresh_queue(self)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func _on_timer_path_timeout() -> void:
	if current_state == STATE.MOVING:
		queue_update_path()
	
func set_state(new_state: STATE) -> void:
	_exit_state()
	_enter_state(new_state)
	
	current_state = new_state
	
func _exit_state() -> void:
	if current_state == STATE.MOVING:
		pass
	elif current_state == STATE.IDLE:
		pass

func _enter_state(state: STATE) -> void:
	if state == STATE.MOVING:
		sprite.play("moving")
	elif state == STATE.IDLE:
		sprite.play("idle")