class_name MapManager extends Node

@export var menu_scene: Node
@export var lobby_map: PackedScene
@export var lobby_scene_path: String = "res://Scenes/level.tscn"
var current_map: Node

func _ready() -> void:
	current_map = menu_scene

func spawn_map(data):
	if current_map != null:
		current_map.queue_free()
	var map = (load(data) as PackedScene).instantiate()
	print_rich("Map ", data, " [b]Loaded[/b]")
	current_map = map
	return map
