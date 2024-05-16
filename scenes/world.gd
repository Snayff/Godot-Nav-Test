extends Node2D



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var destination: Vector2 = get_global_mouse_position()
			EventBus.destination_set.emit(destination)
			