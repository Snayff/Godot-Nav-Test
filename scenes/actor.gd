extends CharacterBody2D


const movement_speed: float = 80.0
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var target_destination: Vector2

func _ready() -> void:
	EventBus.connect("destination_set", set_destination)
	nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))


func _physics_process(delta) -> void:
	if nav_agent.is_navigation_finished():
		return
		
	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_pos) * movement_speed
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)


func set_destination(destination: Vector2) -> void:
	target_destination = destination
	_update_path()

func _update_path() -> void:
	nav_agent.target_position = target_destination

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func _on_timer_path_timeout() -> void:
	# TODO: change to queing for path update, to limit fps drop
	_update_path()