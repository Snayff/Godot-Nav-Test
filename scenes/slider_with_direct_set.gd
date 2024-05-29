class_name SliderWithDirectSet
extends MarginContainer

@onready var slider: HSlider = $VBoxContainer/HBoxContainer/HSlider
@onready var spin_box: SpinBox = $VBoxContainer/HBoxContainer/SpinBox
@onready var label: Label = $VBoxContainer/Label

@export var parameter: String = "cohesion"
@export var target_group: String = "actor"
@export var initial_value: float = 1
@export var min_value: float = 1
@export var max_value: float = 100
@export var scale_factor: float = 1  ## FIXME: not sure what this is for

var _value : float

func _ready() -> void:
	slider.min_value = min_value
	slider.max_value = max_value

	spin_box.min_value = min_value
	spin_box.max_value = max_value

	label.text = parameter.capitalize()

	_update_value_to_initial_values()


func _update_value_to_initial_values() -> void:
	_value = initial_value * scale_factor
	slider.value = initial_value
	spin_box.value = initial_value


func reset() -> void:
	_update_value_to_initial_values()


func get_value() -> float:
	return _value


func _on_slider_value_changed(value: float) -> void:
	_update_actors_steering_parameter(value)
	spin_box.value = value


func _on_spin_box_value_changed(value: float) -> void:
	_update_actors_steering_parameter(value)
	slider.value = value

	# prevent further keyboard input from being placed inside spinbox
	slider.grab_focus()


func _update_actors_steering_parameter(value: float) -> void:
	_value = value * scale_factor
	get_tree().call_group(target_group, "set_steering_param", parameter, value)
	print(parameter, " set to ", value, " for all nodes in group '", target_group)
