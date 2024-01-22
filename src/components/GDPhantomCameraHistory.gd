extends Node

class_name GDPhantomCameraHistory

enum PhantomCameraStatus {
	INACTIVE,
	PREVIOUS_ACTIVE,
	CURRENT_ACTIVE,
}

var _phantomcamera_history: Array[PhantomCamera2D]

func _change_phantomcamera(current_phantomcamera: PhantomCamera2D, new_phantomcamera: PhantomCamera2D):
	if len(_phantomcamera_history) >= 1:
		_phantomcamera_history[-1].set_priority(PhantomCameraStatus.INACTIVE)
	current_phantomcamera.set_priority(PhantomCameraStatus.PREVIOUS_ACTIVE)
	_phantomcamera_history.push_back(current_phantomcamera)
	new_phantomcamera.set_priority(PhantomCameraStatus.CURRENT_ACTIVE)

func _previous_phantomcamera(current_phantomcamera: PhantomCamera2D):
	current_phantomcamera.set_priority(PhantomCameraStatus.INACTIVE)
	_phantomcamera_history.pop_back().set_priority(PhantomCameraStatus.CURRENT_ACTIVE)
