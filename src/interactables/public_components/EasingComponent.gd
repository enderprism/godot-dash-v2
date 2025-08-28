extends Component
class_name EasingComponent

signal progressed(weight_delta: float)
signal finished(player: Player)

@export_range(0.0, 10.0, 0.0001, "or_more", "suffix:s") var duration: float = 1.0
@export var keep_active: bool ## Keep the easing active after it completes.
@export var easing_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var easing_transition: Tween.TransitionType

var tweens: Dictionary[Player, Tween]
var weights: Dictionary[Player, float]
var _previous_weights: Dictionary[Player, float]


func _ready() -> void:
	super()
	parent.interacted.connect(start)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for player in tweens.keys():
		if not is_inactive(player):
			progressed.emit(player, get_weight_delta(player))


func start(player: Player) -> void:
	tweens.set(player, create_tween())
	reset(player)
	tweens[player].tween_property(self, ^"weights", 1.0, duration) \
		.set_trans(easing_transition) \
		.set_ease(easing_type).from(0.0)
	tweens[player].finished.connect(func(): finished.emit(player))


func get_weight_delta(player: Player) -> float:
	var result = weights[player] - _previous_weights[player]
	_previous_weights[player] = weights[player]
	return result


func is_inactive(player: Player) -> bool:
	return weights[player] == 0.0 or (_previous_weights[player] == 1.0 and not keep_active)


func reset(player: Player) -> void:
	weights[player] = 0.0
	_previous_weights[player] = 0.0
