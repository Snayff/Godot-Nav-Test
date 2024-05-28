class_name Actor
extends CharacterBody2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer_path: Timer = $Timer_Path
@onready var timer_target: Timer = $Timer_Target

@export var max_speed: float = 50.0
@export var min_speed: float = 8.0
@export var target_force: float = 4.0  ## pull towards target destination
@export var cohesion_force: float = 2.0  ## pull towards centre of unit
@export var alignment_force: float = 3.0  ## pull towards moving at same speed (I think?)
@export var separation_force: float = 5.0  ## pull away from other actors in unit
@export var avoid_distance: float = 15.0  ## how far to move away from other actors
@export var acceleration_ramp_up: float = 0.01  ## lerp weight for reaching max speed


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
var local_neighbours: Array = []  ## set by world. others actors in vicinity.
var unit_allies: Array = []  ## set by unit. other actors in unit.
var unit_anchor_point: Vector2 = Vector2.ZERO  ## initially set by parent Unit

func _ready() -> void:
	nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))

	set_state(STATE.IDLE)

	if is_in_group("team1"):
		ally_team_group = "team1"
		enemy_team_group = "team2"
	else:
		ally_team_group = "team2"
		enemy_team_group = "team1"


func _process(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		set_state(STATE.IDLE)
	else:
		set_state(STATE.MOVING)

func _physics_process(delta) -> void:
	if current_state == STATE.MOVING and target_destination != Vector2.ZERO:
		var next_path_pos: Vector2 = nav_agent.get_next_path_position()

		# get target vectors and modify by steering forces
		var target_vec: Vector2 = global_position.direction_to(next_path_pos) * movement_speed * target_force
		var flock_status: Array = _get_flocking_info()
		var cohesion_vec: Vector2 = flock_status[0] * cohesion_force
		#var cohesion_vec: Vector2 = unit_anchor_point * cohesion_force
		var align_vec: Vector2 = flock_status[1] * alignment_force
		var separation_vec: Vector2 = flock_status[2] * separation_force

		# consolidate forces
		var acceleration: Vector2 = align_vec + cohesion_vec + separation_vec + target_vec

		# calculate target velocity
		var target_velocity: Vector2 = (velocity  + acceleration).limit_length(max_speed)
		if target_velocity.length() <= min_speed: # TODO: not really sure what this is for
			target_velocity = (target_velocity * min_speed).limit_length(max_speed)

		# lerp towards target velocity
		var new_velocity: Vector2 = velocity.lerp(target_velocity, acceleration_ramp_up)

#		if name == "Actor":
#			print("curr vel: ", velocity, "| acc: ", acceleration,  " | target vel: ", target_velocity, "| new vel: ", new_velocity)

		# apply new velocity
		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(new_velocity)
		else:
			_on_velocity_computed(new_velocity)

####################
##### PATHING ######
####################

func set_destination(destination: Vector2) -> void:
	target_destination = destination
#	if name == "Actor":
#		print("Destination: ", destination)
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
func _get_flocking_info() -> Array:
	#TODO: can we remove flock centre calcs, as using fixed point (the anchor)?
	var centre_vec: Vector2 = Vector2.ZERO
	var flock_centre: Vector2 = Vector2.ZERO
	var align_vec: Vector2 = Vector2.ZERO
	var avoid_vec: Vector2 = Vector2.ZERO
	var flock_count: int   = 0

	var actors: Array = local_neighbours.duplicate() + unit_allies.duplicate()

	# get uniques only
	var flock: Array = []
	for actor in actors:
		if not flock.has(actor):
			flock.append(actor)

#	if name == "Actor":
#		print("Possible Flock size:", actors.size(), "| Actual Flock size:", flock.size())

	# get steering forces from flock
	for actor in flock:

		# ignore self
		if actor == self:
			continue
			
		var other_pos: Vector2 = actor.global_position
			
		# we want to use only unit allies for most calculations
		if unit_allies.has(actor):

			
			var other_velocity: Vector2  = actor.velocity
			flock_count += 1
			align_vec += other_velocity
			flock_centre += other_pos
		
		# must be a local neighbour
		else: 
			var distance_to_other: float = global_position.distance_to(other_pos)
			if distance_to_other < avoid_distance:
				avoid_vec -= other_pos - global_position

	# average values
	if flock_count:
		align_vec /= flock_count
		flock_centre /= flock_count
		centre_vec /= flock_count

	return [
		centre_vec.normalized(),
		align_vec.normalized(),
		avoid_vec.normalized()
	]


####################
#### TARGETING #####
####################

func refresh_target_actor() -> void:
	var target = Actors.get_closest_actor_in_team(self, enemy_team_group)

	if target:
		set_target_actor(target)
		timer_target.start()
#		if name == "Actor":
#			print(name, ": target refreshed. Targeting pos: ", target.position)

func set_target_actor(target: Actor) -> void:
	target_actor = target
	set_destination(target_actor.global_position)

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
