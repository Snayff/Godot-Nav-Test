extends Node

var _path_refresh_queue : Array[Actor] = []
const _actors_updated_per_cycle: int = 5


func _process(delta: float) -> void:
	var num_to_refresh: int = min(_path_refresh_queue.size(), _actors_updated_per_cycle)
	
	for i in range(0, num_to_refresh):
		var actor = _path_refresh_queue.pop_front()
		actor.update_path()
		

func add_to_path_refresh_queue(actor: Actor) -> void:
	if _path_refresh_queue.has(actor):
		push_warning("Attempted to add Actor to path refresh queue, but already exists.")
		return
	
	_path_refresh_queue.append(actor) 