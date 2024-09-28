extends Component
class_name SpiderDashComponent


func set_dash_flip_state(player: Player) -> void:
	var gravity_to_rotation: float = 0.0 if player.gravity_multiplier > 0 else 180.0
	if is_equal_approx(fmod((abs(get_parent().rotation_degrees) - gravity_to_rotation)/180, 2), 1):
		player.get_node("Icon/Spider/SpiderCast").scale.y = -1
	else:
		player.get_node("Icon/Spider/SpiderCast").scale.y = 1