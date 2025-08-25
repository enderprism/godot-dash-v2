extends Marker
class_name SingleUsageComponent


func _ready() -> void:
	super()
	parent.interacted.connect(disable)


func disable(_body: Node2D) -> void:
	for shape_owner in parent.get_shape_owners():
		parent.shape_owner_set_disabled(shape_owner, true)
