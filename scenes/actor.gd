class_name Actor
extends CharacterBody2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer_path: Timer = $Timer_Path
@onready var timer_target: Timer = $Timer_Target

@export var max_speed: float = 100.0
@export var min_speed: float = 80.0
@export var target_force: float = 2.0
@export var cohesion_force: float = 2.0
@export var alignment_force: float = 3.0
@export var separation_force: float = 5.0
@export var view_distance: float = 50.0
@export var avoid_distance: float = 15.0
@export var max_flock_size: float = 15


const movement_speed: float = 80.0
enum STATE {
	MOVING,
	IDLE
}

var target_destination: Vector2 = Vector2.ZERO
var target_actor: Actor
var current_state: int = STATE.IDLE
var ally_team_group: String = ""
var enemy_team_group: String = ""

var _targets: Array = []
var flock: Array = []  ## a 2D array of cells in World._grid  # TODO:  set to unit
var flock_size: int = 0

func _ready() -> void:
	EventBus.connect("destination_set", set_destination)
	nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))

	set_state(STATE.IDLE)

	if is_in_group("team1"):
		ally_team_group = "team1"
		enemy_team_group = "team2"
	else:
		ally_team_group = "team2"
		enemy_team_group = "team1"

	Actors.refresh_team_lists()  # TODO: this is dumb. better to add self to team list.

func _process(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		set_state(STATE.IDLE)
	else:
		set_state(STATE.MOVING)



func _physics_process(delta) -> void:
	if current_state == STATE.MOVING and target_destination != Vector2.ZERO:
		var next_path_pos: Vector2 = nav_agent.get_next_path_position()
		var target_vec: Vector2 = global_position.direction_to(next_path_pos) * movement_speed * target_force

		# get steering forces
		var flock_status: Array = _get_flock_status()
		var cohesion_vec: Vector2 = flock_status[0] * cohesion_force
		var align_vec: Vector2 = flock_status[1] * alignment_force
		var separation_vec: Vector2 = flock_status[2] * separation_force
		flock_size = flock_status[3]

		var acceleration: Vector2 = align_vec + cohesion_vec + separation_vec + target_vec

		var new_velocity: Vector2 = (velocity * acceleration).limit_length(max_speed)
		if new_velocity.length() <= min_speed:
			new_velocity = (new_velocity * acceleration).limit_length(min_speed)

		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(new_velocity)
		else:
			_on_velocity_computed(new_velocity)

####################
##### PATHING ######
####################

func set_destination(destination: Vector2) -> void:
	target_destination = destination
	update_path()  # do immediately, dont queue

## updates the nav path, targeting the target_destination
##
## make sure to update  target_destination first
func update_path() -> void:
	nav_agent.target_position = target_destination
	timer_path.start()

func queue_update_path() -> void:
	Pathing.add_to_path_refresh_queue(self)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func _on_timer_path_timeout() -> void:
	if current_state == STATE.MOVING:
		queue_update_path()

## get the cohesion, alignment, separation and flock size as an array
func _get_flock_status() -> Array:
	var centre_vec: Vector2 = Vector2.ZERO
	var flock_centre: Vector2 = Vector2.ZERO
	var align_vec: Vector2 = Vector2.ZERO
	var avoid_vec: Vector2 = Vector2.ZERO
	var other_count: int = 0

	for cell in flock:
		for other in cell:
			# FIXME: remove when using unit
			if other_count == max_flock_size:
				break

			# ignore self
			if other == self:
				continue

			var other_pos: Vector2 = other.global_position
			var other_velocity: Vector2  = other.velocity
			var distance_to_other: float = global_position.distance_to(other_pos)

			# FIXME: why view distance?!
			if distance_to_other < view_distance:
				other_count += 1
				align_vec += other_velocity
				flock_centre += other_pos

				if distance_to_other < avoid_distance:
					avoid_vec -= other_pos - global_position

	# average values
	if other_count:
		align_vec /= other_count
		flock_centre /= other_count
		centre_vec /= other_count

	return [
		centre_vec.normalized(),
		align_vec.normalized(),
		avoid_vec.normalized(),
		other_count
	]




####################
#### TARGETING #####
####################

func refresh_target_actor() -> void:
	var target = Actors.get_closest_actor_in_team(self, enemy_team_group)

	if target:
		set_target_actor(target)
		timer_target.start()

func set_target_actor(target: Actor) -> void:
	target_actor = target
	set_destination(target_actor.position)

func _on_timer_target_timeout() -> void:
	refresh_target_actor()


####################
###### STATE #######
####################

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
