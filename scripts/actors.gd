extends Node

var _team1: Array = []  # untyped array due to using get_nodes_in_group
var _team2: Array = []
var _all_actors: Array = []

func _ready() -> void:
	pass

## rebuild internal team lists
func refresh_team_lists() -> void:

	var units: Array = get_tree().get_nodes_in_group("units")

	for unit in units:
		if unit.has_group("team1"):
			_team1.append(unit)
		elif unit.has_group("team2"):
			_team2.append(unit)

	_all_actors.clear()
	for team in [_team1, _team2]:
		for unit in team:
			for actor in unit.actors:
				_all_actors.append(actor)

	# print_rich("team1: ", team1, "| team2:", team2)

## returns copy of array of team's units
func get_team(team: String) -> Array:
	if team == "team1":
		return _team1.duplicate()
	elif team == "team2":
		return _team2.duplicate()

	push_warning("Team given (", team, ") doesnt exist. Returned empty array instead.")
	return []

## returns copy of array of all actors
func get_actors() -> Array:
	return _all_actors.duplicate()

## add a unit to a team
func add_to_team(unit: Unit, team: String) -> void:
	if team == "team1":
		if not _team1.has(unit):
			_team1.append(unit)
		else:
			push_warning("Tried to add unit ", unit ," to ", team, ", but already exists in team.")
	elif team == "team2":
		if not _team2.has(unit):
			_team2.append(unit)
		else:
			push_warning("Tried to add actor ", unit ," to ", team, ", but already exists in team.")

	for actor in unit.actors:
		_all_actors.append(actor)

## get the unit closest in a given team
func get_closest_unit_in_team(unit: Unit, team: String) -> Unit:
	var target_team: Array = [] # untyped array due to using get_nodes_in_group

	if team == "team1":
		target_team = _team1.duplicate()
	elif team == "team2":
		target_team = _team2.duplicate()
	else:
		push_error("Team given, ", team, ", isnt valid.")
		return

	if target_team.size() == 0:
		push_warning("No possible targets in ", team, ".")
		return

	var closest_unit: Unit = target_team.pop_back()  # pop_back as faster and dont care about order
	var current_distance: float = unit.position.distance_to(closest_unit.position)

	for poss_target in target_team:
		if _is_closer(unit.position, poss_target.position, current_distance):
			closest_unit = poss_target
			current_distance = unit.position.distance_to(closest_unit.position)

	return closest_unit

## get the actor closest in a given team
func get_closest_actor_in_team(actor: Actor, team: String) -> Actor:
	var target_team: Array = [] # untyped array due to using get_nodes_in_group

	if team == "team1":
		target_team = _team1.duplicate()
	elif team == "team2":
		target_team = _team2.duplicate()
	else:
		push_error("Team given, ", team, ", isnt valid.")
		return

	if target_team.size() == 0:
		push_warning("No possible targets in ", team, ".")
		return

	var closest_actor: Actor = target_team[0].actors[0]  # pop_back as faster and dont care about order
	var current_distance: float = actor.position.distance_to(closest_actor.position)

	for unit: Unit in target_team:
		for poss_target: Actor in unit.actors:
			if _is_closer(actor.position, poss_target.position, current_distance):
				closest_actor = poss_target
				current_distance = actor.position.distance_to(closest_actor.position)

	return closest_actor

func _is_closer(origin: Vector2, target: Vector2, current_distance: float) -> bool:
	return origin.distance_to(target) < current_distance

