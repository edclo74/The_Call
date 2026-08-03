extends Node


# --- Battery system ---
signal battery_charge_changed(new_charge: float)
signal battery_depleted

var flashlight_on: bool = false

@export var battery_max_charge: float = 100.0
@export var battery_drain_rate: float = 5.0    # charge per second while on
@export var battery_recharge_rate: float = 10.0

var battery_current_charge: float = 100.0

func battery_drain(delta: float) -> void:
	if battery_current_charge <= 0.0:
		return
	battery_current_charge = max(0.0, battery_current_charge - battery_drain_rate * delta)
	battery_charge_changed.emit(battery_current_charge)
	if battery_current_charge == 0.0:
		battery_depleted.emit()

func battery_recharge(delta: float) -> void:
	if battery_current_charge >= battery_max_charge:
		return
	battery_current_charge = min(battery_max_charge, battery_current_charge + battery_recharge_rate * delta)
	battery_charge_changed.emit(battery_current_charge)

func battery_get_percent() -> float:
	return battery_current_charge / battery_max_charge
