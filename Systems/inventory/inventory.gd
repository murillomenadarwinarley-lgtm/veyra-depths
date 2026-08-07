extends Node
## Inventario del jugador (autoload "Inventory").
## Almacén simple de item_id -> cantidad.

signal inventory_changed(item_id: String, count: int)

var items: Dictionary = {}  # item_id -> cantidad

func add(item_id: String, amount: int = 1) -> void:
	items[item_id] = items.get(item_id, 0) + amount
	inventory_changed.emit(item_id, items[item_id])

func remove(item_id: String, amount: int = 1) -> bool:
	if count(item_id) < amount:
		return false
	items[item_id] = items[item_id] - amount
	if items[item_id] <= 0:
		items.erase(item_id)
	inventory_changed.emit(item_id, count(item_id))
	return true

func count(item_id: String) -> int:
	return items.get(item_id, 0)

func has(item_id: String) -> bool:
	return count(item_id) > 0

func clear() -> void:
	items.clear()
