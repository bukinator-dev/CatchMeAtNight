class_name Interactable
extends StaticBody3D
## Anything the crosshair can use. Sits on physics layer 2, which only the
## player's look-ray checks, so it never blocks walking.

signal used

@export var prompt := "Use"
@export var enabled := true


func _init() -> void:
	collision_layer = 2
	collision_mask = 0


static func create(parent: Node, prompt_text: String, size: Vector3, pos: Vector3, rot_deg := Vector3.ZERO) -> Interactable:
	var it := Interactable.new()
	it.prompt = prompt_text
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	it.add_child(cs)
	it.position = pos
	it.rotation_degrees = rot_deg
	parent.add_child(it)
	return it


func interact() -> void:
	if enabled:
		used.emit()
