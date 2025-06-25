class_name MenuManager extends Node

@export var main_canvas: CanvasLayer
@export var main_menu: Control
@export var multiplayer_select_menu: Control
@export var local_multiplayer_menu: Control
@export var public_multiplayer_menu: Control

@export var lobby_manager: Node
@export var network_manager: Node

func _ready():
	hide_all_menus()
	main_menu.show()

func hide_main_canvas():
	main_canvas.hide()

func hide_all_menus():
	main_menu.hide()
	multiplayer_select_menu.hide()
	local_multiplayer_menu.hide()
	public_multiplayer_menu.hide()

func _on_singleplayer_button_pressed():
	hide_all_menus()
	hide_main_canvas()
	lobby_manager.setup_singleplayer_lobby()
	lobby_manager.create_singleplayer_lobby()

func _on_multiplayer_button_pressed():
	hide_all_menus()
	multiplayer_select_menu.show()

func _on_public_multiplayer_button_pressed():
	hide_all_menus()
	lobby_manager.setup_steam_lobbies()
	public_multiplayer_menu.show()

func _on_local_multiplayer_button_pressed():
	hide_all_menus()
	lobby_manager.setup_local_lobbies()
	local_multiplayer_menu.show()

func _on_public_host_button_pressed():
	hide_main_canvas()
	lobby_manager.create_steam_lobby()

func _on_refresh_lobby_button_pressed():
	lobby_manager.refresh_steam_lobby_list()

func _on_local_host_button_pressed():
	hide_main_canvas()
	lobby_manager.create_local_lobby()

func _on_local_join_button_pressed():
	hide_main_canvas()
	lobby_manager.join_local_lobby()

func _on_back_to_menu_button_pressed() -> void:
	hide_all_menus()
	multiplayer_select_menu.show()

func _on_back_to_main_menu_button_pressed() -> void:
	hide_all_menus()
	main_menu.show()
