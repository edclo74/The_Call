extends AnimatedSprite2D

var thresholds: Array[float] = [0.0, 0.25, 0.5, 0.75]
var current_frame_index: int = -1

func _ready() -> void:
	animation = "battery_levels"
	BatteryScript.battery_charge_changed.connect(_on_charge_changed)
	print("READY - initial percent: ", BatteryScript.battery_get_percent())
	_update_frame(BatteryScript.battery_get_percent())
	print (sprite_frames.get_frame_count("battery_levels"))

func _on_charge_changed(_new_charge: float) -> void:
	print("SIGNAL RECEIVED - new_charge: ", _new_charge)
	_update_frame(BatteryScript.battery_get_percent())

func _update_frame(percent: float) -> void:
	print("UPDATE_FRAME called - percent: ", percent, " current_frame_index: ", current_frame_index)
	var new_index: int = 0
	for i in range(thresholds.size() - 1, -1, -1):
		if percent >= thresholds[i]:
			new_index = i
			break
	print("new_index calculated: ", new_index)
	if new_index != current_frame_index:
		current_frame_index = new_index
		stop()
		frame = current_frame_index
		print("FRAME SET TO: ", frame, " actual .frame property now: ", self.frame)
	else:
		print("Frame unchanged, staying at: ", current_frame_index)
