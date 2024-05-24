extends Node2D

@onready var _tile_map: TileMap = $TileMap

@export var _show_grid: bool = true  ## whether to show the grid lines
@export var _grid_scale: int = 4 ## ratio of map to grid

var _grid: Array = []  ## Array[Array[Array[Node2D]]]
var grid_size: Vector2i
var map_size: Vector2


func _ready() -> void:
	map_size = _tile_map.get_used_rect().size
	grid_size = Vector2(_scale_axis_to_grid(map_size.x), _scale_axis_to_grid(map_size.y))
	print("Map size: ", map_size, " | Grid Size: ", grid_size)

	# populate empty grid
	_grid.resize(grid_size.x)
	for x in range(grid_size.x):
		_grid[x] = []
		_grid[x].resize(grid_size.y)

		for y in range(grid_size.y):
			_grid[x][y] = []

func _draw() -> void:
	print("hit draw")
	if _show_grid:
		_draw_grid()

func _draw_grid() -> void:
	print("draw_grid called")
	var start: Vector2i = Vector2i.ZERO
	var end: Vector2i = Vector2i.ZERO
	var colour: Color = Color.PINK

	for x in range(0, grid_size.x + 1):
		start = Vector2i(x * _grid_scale, 0)
		end = Vector2i(x * _grid_scale, grid_size.y * _grid_scale)
		print("Draw horizontal (", start, end, ")")
		draw_line(start, end, colour, 2)
		#draw_dashed_line(start, end, colour)

	for y in range(0, grid_size.y + 1):
		start = Vector2i(0, y * _grid_scale)
		end = Vector2i(grid_size.x * _grid_scale, y * _grid_scale)
		print("Draw vertical (", start, end, ")")
		draw_line(start, end, colour, 2)
		#draw_dashed_line(start, end, colour)

## scale an axis (i.e. single value) to a position in the grid
func _scale_axis_to_grid(point: float) -> int:
	return int(floor(point / _grid_scale))

## scale a map position to a position on the grid
func _scale_pos_to_grid(pos: Vector2) -> Vector2i:
	var scaled_pos: Vector2 = (pos / _grid_scale).floor()
	scaled_pos.x = clamp(scaled_pos.x, 0, grid_size.x) # min(max(scaled_pos.x, 0), grid_size.x)
	scaled_pos.y = clamp(scaled_pos.y, 0, grid_size.y) # min(max(scaled_pos.y, 0), grid_size.y)
	return scaled_pos

func add_body_to_grid(body: Node2D, grid_pos: Vector2) -> void:
	_grid[grid_pos.x][grid_pos.y].append(body)

## get all bodies from neighbouring grid cells
func get_grid_neighbours(grid_pos: Vector2) -> Array:
	# ensure in bounds
	var x: int = clamp(grid_pos.x, 0, grid_size.x)
	var y: int = clamp(grid_pos.y, 0, grid_size.y)

	var bodies: Array = [_grid[x][y]]

	var up: int   = y - 1
	var down: int = y + 1
	var left: int  = x - 1
	var right: int = x + 1

	# up
	if up > 0:
		bodies.append(_grid[x][up])
		if left > 0:
			bodies.append(_grid[left][up])
		if right <= grid_size.x:
			bodies.append(_grid[right][up])
	# down
	if down <= grid_size.y:
		bodies.append(_grid[x][down])
		if left > 0:
			bodies.append(_grid[left][down])
		if right <= grid_size.x:
			bodies.append(_grid[right][down])

	# left and right
	if left > 0:
		bodies.append(_grid[left][y])
	if right <= grid_size.x:
		bodies.append(_grid[right][y])

	return bodies


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_grid = !_show_grid
			queue_redraw()
			print("Toggle show grid. Now: ", _show_grid)
#			var destination: Vector2 = get_global_mouse_position()
#			EventBus.destination_set.emit(destination)
	pass
