extends PanelContainer

@export var line_edit: LineEdit
@export var confirm_button: Button
@export var group_container: Container

var selected_objects: Array[Node2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_line_edit_text_submitted(new_text:String) -> void:
	pass # Replace with function body.



func _on_button_pressed() -> void:
	line_edit.get_text()

