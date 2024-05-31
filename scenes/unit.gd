class_name Unit
extends CharacterBody2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer_path: Timer = $Timer_Path
@onready var timer_target: Timer = $Timer_Target

const actor_scene: PackedScene = preload("res://scenes/actor.tscn")

var actors: Array[Actor] = []
var target_destination: Vector2 = Vector2.ZERO
var target_unit: Unit
var ally_team_group: String = ""
var enemy_team_group: String = ""
var movement_speed: float = 50.0  ## TODO: take average from child actors
@export var unit_size: int = 3 ## how many actors in unit
@export var spawn_radius: int = 35


func _ready() -> void:
	EventBus.connect("destination_set", set_destination)
	nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))

	if is_in_group("team1"):
		ally_team_group = "team1"
		enemy_team_group = "team2"
	else:
		ally_team_group = "team2"
		enemy_team_group = "team1"

	# TODO: remove when diff actors in place
	if ally_team_group == "team2":
		modulate = Color.CRIMSON

	_spawn_actors()

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


## spawn required number of actors randomly around the unit's position
func _spawn_actors() -> void:
	var max_attempts: int = 32
	var pos_variance: int = floor(spawn_radius / 2)

	for i in unit_size:
		for j in max_attempts:

			var rand_x : int = randi_range(global_position.x - pos_variance, global_position.x + pos_variance)
			var rand_y : int = randi_range(global_position.y - pos_variance, global_position.y + pos_variance)
			var spawn_pos: Vector2 = Vector2(rand_x, rand_y)

			var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
			var shape_query_params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
			var shape: CircleShape2D = CircleShape2D.new()
			shape.radius = 10
			shape_query_params.shape = shape
			shape_query_params.transform.origin = spawn_pos

			# check query
			var results: Array[Dictionary] = space_state.intersect_shape(shape_query_params)
			var filtered_array: Array = results.filter(
				func (collision_object):
						return (collision_object.collider.is_in_group("actor") or collision_object.collider.is_in_group("actor"))
			)

			# visual and console output for debugging
			#print(results)
#			var area_2d = Area2D.new()
#			var collision_shape_2d = CollisionShape2D.new()
#			var collision_shape = CircleShape2D.new()
#			area_2d.add_child(collision_shape_2d)
#			add_child(area_2d)
#			area_2d.global_position = shape_query_params.transform.origin
#			collision_shape.radius = shape.radius
#			collision_shape_2d.shape = collision_shape

			# if no collisions
			if filtered_array.size() == 0:
				var actor: Actor = actor_scene.instantiate()
				add_child(actor)
				#actor.top_level = true
				actor.global_position = spawn_pos

				# colour enemy
				if ally_team_group == "team2":
					actor.modulate = Color.CRIMSON

				print("Unit pos: ", global_position, " | actor (", actor, ") spawned at: ", spawn_pos)
				break

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
