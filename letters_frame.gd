extends Control

@onready var grid = $GridContainer

func _ready():
	if grid == null:
		push_error("GridContainer not found!")
		return

	for slot in grid.get_children():
		if slot.has_signal("pressed"):
			slot.pressed.connect(_on_slot_pressed.bind(slot))
		else:
			print("Node is not a Button:", slot)

func _on_slot_pressed(slot):
	print("Pressed:", slot.name)
