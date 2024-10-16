extends Area2D
class_name EditorSelectionCollider

enum Type {
	BLOCK,
	SPIKE,
	SPIKE_FLAT,
	SPIKE_MEDIUM,
	SPIKE_SMALL,
	SLOPE,
	SLOPE_LARGE,
	INTERACTABLE,
	TRIGGER,
}

@export var type: Type
@export var id: int