extends Control


func _on_target_group_component_changed(target_group: String) -> void:
	$Label.text = target_group.trim_prefix(GroupEditor.GROUP_PREFIX)
	var update_width := func(): $Label.position.x = -$Label.size.x/2
	update_width.call_deferred()

