extends Node2D

@onready var _tile_map: TileMap = $NavigationRegion2D/TileMap

@export var _show_grid: bool = true  ## whether to show the grid lines
@export var _grid_scale: int = 32 ## ratio of map to grid

var _grid: Array = []  ## Array[Array[Array[Node2D]]]
var grid_size: Vector2i
var map_size: Vector2


func _ready() -> void:
	map_size = _tile_map.get_used_rect().size * _tile_map.tile_set.tile_size
	grid_size = Vector2(_scale_axis_to_grid(map_size.x), _scale_axis_to_grid(map_size.y))
	_create_empty_grid()
	print("Map size: ", map_size, " | Grid Size: ", grid_size)

func _draw() -> void:
	if _show_grid:
		_draw_grid_lines()

func _draw_grid_lines() -> void:
	# FIXME: grid is offset
	var start: Vector2i = Vector2i.ZERO
	var end: Vector2i = Vector2i.ZERO
	var colour: Color = Color.PINK

	for x in range(0, grid_size.x + 1):
		start = Vector2i(x * _grid_scale, 0)
		end = Vector2i(x * _grid_scale, grid_size.y * _grid_scale)
		#print("Draw horizontal (", start, end, ")")
		var line = Line2D.new()
		add_child(line)
		line.add_point(start)
		line.add_point(end)
		line.default_color = colour
		line.z_index = 100
		line.width = 2
		#draw_line(start, end, colour, 2)
		#draw_dashed_line(start, end, colour)

	for y in range(0, grid_size.y + 1):
		start = Vector2i(0, y * _grid_scale)
		end = Vector2i(grid_size.x * _grid_scale, y * _grid_scale)
		#print("Draw vertical (", start, end, ")")
		var line = Line2D.new()
		add_child(line)
		line.add_point(start)
		line.add_point(end)
		line.default_color = colour
		line.z_index = 100
		line.width = 2
		#draw_line(start, end, colour, 2)
		#draw_dashed_line(start, end, colour)

func _process(delta: float) -> void:
	_rebuild_grid()
	_update_actors_local_neighbours()

## clear existing_grid, rebuild with empty arrays, and populate with bodies.
func _rebuild_grid() -> void:
	_grid.clear()
	_create_empty_grid()
	for actor in Actors.get_actors():
		var grid_point: Vector2i = _scale_pos_to_grid(actor.position)
		add_body_to_grid(actor, grid_point)

## build an empty 2d array of arrays for the _grid
func _create_empty_grid() -> void:
	# populate empty grid
	_grid.resize(grid_size.x)
	for x in range(grid_size.x):
		_grid[x] = []
		_grid[x].resize(grid_size.y)

		for y in range(grid_size.y):
			_grid[x][y] = []

## update the local neighbours, using _grid, for all actors. Includes self, i.e. the actor is its own neighbour.
func _update_actors_local_neighbours() -> void:
	for actor in Actors.get_actors():
		actor.local_neighbours = get_grid_neighbours(_scale_pos_to_grid(actor.position))

## scale an axis (i.e. single value) to a position in the grid
func _scale_axis_to_grid(point: float) -> int:
	#print("point: ", point)
	var scaled_point: int = int(floor(point / _grid_scale))
	#print("scaled point: ", scaled_point)
	return  scaled_point

## scale a map position to a position on the grid
func _scale_pos_to_grid(pos: Vector2) -> Vector2i:
	#print("pos: ", pos)
	var scaled_pos: Vector2 = (pos / _grid_scale).floor()
	#print("scaled pos: ", scaled_pos)
	scaled_pos.x = clamp(scaled_pos.x, 0, grid_size.x)
	scaled_pos.y = clamp(scaled_pos.y, 0, grid_size.y)
	#print("clamped & scaled pos: ", scaled_pos)
	return scaled_pos

func add_body_to_grid(body: Node2D, grid_pos: Vector2) -> void:
	_grid[grid_pos.x][grid_pos.y].append(body)
	#print("body appended to grid pos: ", grid_pos.x, ", ", grid_pos.y )

## get all bodies from neighbouring grid cells
func get_grid_neighbours(grid_pos: Vector2) -> Array:
	# ensure in bounds
	var x: int = clamp(grid_pos.x -1, 0, grid_size.x)
	var y: int = clamp(grid_pos.y -1, 0, grid_size.y)
	#print("x: ", x, "y: ", y)
	#print("grid[", x, ", ", y, "]:", _grid[x][y])
	var bodies: Array = []
	bodies.append_array(_grid[x][y])
	#print("bodies:", bodies)

	var up: int   = y - 1
	var down: int = y + 1
	var left: int  = x - 1
	var right: int = x + 1
	#print("up: ", up, ", down: ", down, ", left: ", left, ", right:", right)
	#print("grid size: ", grid_size)

	# up
	if up > 0:
		bodies.append_array(_grid[x][up])
		if left > 0:
			bodies.append_array(_grid[left][up])
		if right <= grid_size.x:
			bodies.append_array(_grid[right][up])
	# down
	if down <= grid_size.y:
		bodies.append_array(_grid[x][down])
		if left > 0:
			bodies.append_array(_grid[left][down])
		if right <= grid_size.x:
			bodies.append_array(_grid[right][down])

	# left and right
	if left > 0:
		bodies.append_array(_grid[left][y])
	if right <= grid_size.x:
		bodies.append_array(_grid[right][y])

	return bodies


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_grid = !_show_grid
			queue_redraw()
			#print("Toggle show grid. Now: ", _show_grid)
#			var destination: Vector2 = get_global_mouse_position()
#			EventBus.destination_set.emit(destination)
	pass
