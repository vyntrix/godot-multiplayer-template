class_name MapManager extends Node

@export var menu_scene: Node
@export var lobby_map: PackedScene
@export var lobby_scene_path: String = "res://Scenes/level.tscn"
var current_map: Node

func _ready() -> void:
	current_map = menu_scene

# Spawns a map based on the provided data.
# The data parameter is expected to be a string representing the path to the map scene.
# If a current map exists, it is freed before spawning the new one.
# Returns the newly spawned map instance.
func spawn_map(data):
	if current_map != null:
		current_map.queue_free()
	var map = (load(data) as PackedScene).instantiate()
	print_rich("Map ", data, " [b]Loaded[/b]")
	current_map = map
	return map
