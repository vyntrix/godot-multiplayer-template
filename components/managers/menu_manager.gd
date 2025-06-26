class_name MenuManager extends Node

@export var main_canvas: CanvasLayer
@export var main_menu: Control
@export var multiplayer_select_menu: Control
@export var local_multiplayer_menu: Control
@export var public_multiplayer_menu: Control
@export var mic_select: OptionButton
@export var restart_prompt: Label

@export var lobby_manager: Node
@export var network_manager: Node

func _init():
	AudioServer.input_device = Settings.load_microphone()

func _ready():
	restart_prompt.hide()
	hide_all_menus()
	main_menu.show()
	for input in AudioServer.get_input_device_list():
		mic_select.add_item(input)
	var current_mic = AudioServer.get_input_device_list().find(Settings.load_microphone())
	mic_select.select(current_mic)
	print(AudioServer.input_device)

func hide_main_canvas():
	main_canvas.hide()

func show_main_canvas():
	main_canvas.show()

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

func _on_mic_select(index: int) -> void:
	var mic_name = AudioServer.get_input_device_list()[index]
	print_rich("[color=green]Mic selected:[/color] %s" % mic_name)
	print_rich("[shake][b][color=red]Please restart the game to apply the new microphone.[/color][/b][/shake]")
	print_rich("[color=white]See this issue for more info:[/color]")
	print_rich("[u][i]https://github.com/godotengine/godot/issues/75603[/i][/u]")
	print_rich("[color=white]When using Windows, there is currently no way to change the microphone in-game.[/color]")
	restart_prompt.show()
	Settings.save_microphone(mic_name)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
