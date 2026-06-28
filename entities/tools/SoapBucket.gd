extends RigidBody3D

@export var soap_capacity: float = 1.0
@export var spill_drain_rate: float = 0.15

var soap_amount: float

func _ready() -> void:
	add_to_group("soap_source")
	soap_amount = soap_capacity
	mass = 3.0

func _physics_process(delta: float) -> void:
	# Spill soap when tipped (bucket's local up points away from world up)
	if soap_amount > 0.0 and global_basis.y.dot(Vector3.UP) < 0.3:
		soap_amount = maxf(soap_amount - spill_drain_rate * delta, 0.0)

func get_soap_ratio() -> float:
	return soap_amount / soap_capacity

func drain(amount: float) -> void:
	soap_amount = maxf(soap_amount - amount, 0.0)
