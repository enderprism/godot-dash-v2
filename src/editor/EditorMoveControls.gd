@tool
class_name EditorMoveControls
extends VBoxContainer

signal direction_pressed(direction: Vector2, step: float)

enum StepVariant {
	FULL,
	FIVE,
	TEN,
	HALF,
	QUARTER,
	EIGTH,
}

@export var button_size: float = 16.0:
	set(value):
		button_size = value
		if not is_node_ready():
			return
		for direction_button in [%Up, %Down, %CenterPadding, %Left, %Right]:
			direction_button.custom_minimum_size = Vector2.ONE * value

@export var step_variant: StepVariant:
	set(value):
		step_variant = value
		if not is_node_ready():
			set_icon(value)


func _ready() -> void:
	for direction_button in [%Up, %Down, %Left, %Right]:
		direction_button.pressed.connect(on_pressed)
	set_icon(step_variant)


func _process(_delta: float) -> void:
	for direction_button in [%Up, %Down, %Left, %Right]:
		direction_button.pivot_offset = direction_button.size/2
	%Left.rotation = -PI/2
	%Right.rotation = PI/2
	%Down.rotation = PI


func set_icon(value: StepVariant) -> void:
	for direction_button in [%Up, %Down, %Left, %Right]:
		match value:
			StepVariant.FULL:
				direction_button.icon = preload("res://assets/textures/guis/editor/edit_panel/MoveObjectFullStep.svg")
			StepVariant.FIVE:
				direction_button.icon = preload("res://assets/textures/guis/editor/edit_panel/MoveObjectFiveSteps.svg")
			StepVariant.TEN:
				direction_button.icon = preload("res://assets/textures/guis/editor/edit_panel/MoveObjectTenSteps.svg")
			StepVariant.HALF:
				direction_button.icon = preload("res://assets/textures/guis/editor/edit_panel/MoveObjectHalfStep.svg")
			StepVariant.QUARTER:
				direction_button.icon = preload("res://assets/textures/guis/editor/edit_panel/MoveObjectQuarterStep.svg")
			StepVariant.EIGTH:
				direction_button.icon = preload("res://assets/textures/guis/editor/edit_panel/MoveObjectEigthStep.svg")


func on_pressed() -> void:
	var step: float
	match step_variant:
		StepVariant.FULL:
			step = 1.0
		StepVariant.FIVE:
			step = 5.0
		StepVariant.TEN:
			step = 10.0
		StepVariant.HALF:
			step = 0.5
		StepVariant.QUARTER:
			step = 0.25
		StepVariant.EIGTH:
			step = 0.125
	direction_pressed.emit(Vector2.UP.rotated(get_viewport().gui_get_focus_owner().rotation), step)
