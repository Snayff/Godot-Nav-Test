extends Node

var team1: Array = []  # untyped array due to using get_nodes_in_group
var team2: Array = []
var all_actors: Array = []

func _ready() -> void:
	pass

## rebuild team1, team2, and all_actors
func refresh_team_lists() -> void:
	team1 = get_tree().get_nodes_in_group("team1")
	team2 = get_tree().get_nodes_in_group("team2")
	all_actors.clear()
	all_actors.append_array(team1)
	all_actors.append_array(team2)
	# print_rich("team1: ", team1, "| team2:", team2)

## add single actor to a team
func add_to_team(actor: Actor, team: String) -> void:
	if team == "team1":
		if not team1.has(actor):
			team1.append(actor)
		else:
			push_warning("Tried to add actor ", actor ," to ", team, ", but already exists in team.")
	elif team == "team2":
		if not team2.has(actor):
			team2.append(actor)
		else:
			push_warning("Tried to add actor ", actor ," to ", team, ", but already exists in team.")

## get the actor closest in a given team
func get_closest_actor_in_team(actor: Actor, team: String) -> Actor:
	var target_team: Array = [] # untyped array due to using get_nodes_in_group
	
	if team == "team1":
		target_team = team1.duplicate()
	elif team == "team2":
		target_team = team2.duplicate()
	else:
		push_error("Team given, ", team, ", isnt valid.")
		return
	
	if target_team.size() == 0:
		push_warning("No possible targets in ", team, ".")
		return
		
	var closest_actor: Actor = target_team.pop_back()  # pop_back as faster and dont care about order
	var current_distance: float = actor.position.distance_to(closest_actor.position) 
	
	for poss_target in target_team:
		if _is_closer(actor.position, poss_target.position, current_distance):
			closest_actor = poss_target
			current_distance = actor.position.distance_to(closest_actor.position)
	
	return closest_actor
		
func _is_closer(origin: Vector2, target: Vector2, current_distance: float) -> bool:
	return origin.distance_to(target) < current_distance 
	
	