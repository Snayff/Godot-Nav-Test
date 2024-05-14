extends CharacterBody2D

const speed: int = 100
var dir: Vector2
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var next_path_pos := nav_agent.get_next_path_position()
	var dir := global_position.direction_to(next_path_pos)
	velocity = dir * speed
	move_and_slide()
	
func _unhandled_input(event: InputEvent) -> void:
#	dir.x = Input.get_axis("ui_left", "ui_right")
#	dir.y = Input.get_axis("ui_up", "ui_down")
#	dir = dir.normalized()
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			nav_agent.target_position = get_global_mouse_position()