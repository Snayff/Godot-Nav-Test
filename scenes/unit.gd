class_name Unit
extends CharacterBody2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer_path: Timer = $Timer_Path
@onready var timer_target: Timer = $Timer_Target

var actors: Array[Actor] = []
var target_destination: Vector2 = Vector2.ZERO
var target_unit: Unit
var ally_team_group: String = ""
var enemy_team_group: String = ""
var movement_speed: float = 50.0  ## TODO: take average from child actors


func _ready() -> void:
	EventBus.connect("destination_set", set_destination)
	nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))

	if is_in_group("team1"):
		ally_team_group = "team1"
		enemy_team_group = "team2"
	else:
		ally_team_group = "team2"
		enemy_team_group = "team1"

	_refresh_actors_list()

	Actors.add_to_team(self, ally_team_group)

func _process(delta: float) -> void:
	_refresh_actors_list()
	_update_actors_unit_info()

func _physics_process(delta: float) -> void:
	if target_destination != Vector2.ZERO:
		var next_path_pos: Vector2 = nav_agent.get_next_path_position()
		var new_velocity: Vector2 = global_position.direction_to(next_path_pos) * movement_speed

		# apply new velocity
		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(new_velocity)
		else:
			_on_velocity_computed(new_velocity)

## loop children and add any actors founds to `actors` array.
## TODO: remove when Unit spawns actors, as we'll add them directly
func _refresh_actors_list() -> void:
	actors.clear()
	for child in get_children():
		if child is Actor:
			if not actors.has(child):
				actors.append(child)


## update anchor point, i.e. the unit centre, for all actors in unit
func _update_actors_unit_info() -> void:
	for actor in actors:
		actor.unit_anchor_point = global_position
		actor.unit_allies = actors



####################
##### PATHING ######
####################

## updates the nav path, targeting the target_destination
##
## make sure to update  target_destination first
func _update_path() -> void:
	nav_agent.target_position = target_destination
	timer_path.start()

func set_destination(destination: Vector2) -> void:
	target_destination = destination
	_update_path()  # do immediately, dont queue

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func _on_timer_path_timeout() -> void:
	_update_path()

####################
#### TARGETING #####
####################

func refresh_target_unit() -> void:
	var target = Actors.get_closest_unit_in_team(self, enemy_team_group)

	if target:
		set_target_unit(target)
		timer_target.start()

func set_target_unit(target: Unit) -> void:
	target_unit = target
	set_destination(target_unit.global_position)

func _on_timer_target_timeout() -> void:
	refresh_target_unit()
