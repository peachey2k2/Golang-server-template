extends CanvasLayer

@onready var list:ItemList = $"Lobby Select/VBoxContainer/ItemList"
@onready var join_button:Button = $"Lobby Select/VBoxContainer/HBoxContainer/Join"
@onready var loading_screen:Panel = $"Loading Screen"
@onready var refresh_button: Button = $"Lobby Select/VBoxContainer/HBoxContainer2/Refresh"

var selected_lobby:int
var lobbies:Array[Global.Lobby]

var lock = false
var active_menu:Panel:
	set(val):
		if active_menu == null:
			active_menu = val
			return
		
		if lock: return
		lock = true
		val.show()
		
		var mul = 1
		if val.position.x > 0: mul = -1
		
		var tw := create_tween()
		tw.tween_property(
			active_menu,
			"position",
			Vector2(active_menu.position.x + get_viewport().size.x * mul, active_menu.position.y),
			0.5
		).set_trans(Tween.TRANS_BACK)
		
		tw = create_tween()
		tw.tween_property(
			val,
			"position",
			Vector2(get_viewport().size / 2) - val.size / 2,
			0.5
		).set_trans(Tween.TRANS_BACK)
		
		await tw.finished
		active_menu.hide()
		active_menu = val
		
		lock = false

func _fetch_lobbies() -> void:
	list.deselect_all()
	list.clear()
	lobbies.clear()
	join_button.disabled = true
	
	var res := await GameSocket.get_lobby_list()
	var dict:Dictionary = res["lobbies"]
	for id in dict.keys():
		var lobby:Dictionary = dict[id]
		var room_name:String = "(%d/2) " % lobby["players"].size()
		var players:Array[Global.User] = []
		if lobby["players"].size() >= 1:
			players.append(GameSocket.dict_to_user(lobby["players"][0]))
			room_name += players[0].name
		if lobby["players"].size() >= 2:
			players.append(GameSocket.dict_to_user(lobby["players"][1]))
			room_name += players[1].name
		lobbies.append(Global.Lobby.new(room_name, players, int(id)))
	
	for i in lobbies.size():
		var item = lobbies[i]
		list.add_item(item.name)
		if item.players.size() >= 2:
			list.set_item_disabled(i, true)
		list.set_item_tooltip(i, item.tooltip())

func _ready() -> void:
	list.item_selected.connect(Callable(self, "_on_item_selected"))
	list.item_activated.connect(Callable(self, "_on_item_activated"))
	Global.main_menu = self
	
	for panel in get_children():
		if panel is not Panel: continue
		if panel.name != "Player Info" && panel.name != "Loading Screen":
			if panel.name != "Main Menu":
				panel.position.x += get_viewport().size.x
				panel.hide()
			else:
				active_menu = panel
				panel.show()
		for boxcon in panel.get_children():
			if boxcon is BoxContainer:
				_connect_signal(boxcon, panel)

func _on_item_selected(i:int):
	selected_lobby = i
	join_button.disabled = lobbies[i].players.size() >= 2

func _on_item_activated(i:int):
	Global.load_lobby(lobbies[i])

func _connect_signal(boxcon:BoxContainer, panel:Panel) -> void:
	for button in boxcon.get_children():
		if button is BoxContainer:
			_connect_signal(button, panel)
		if button is Button:
			button.pressed.connect(Callable(self, "_" + _str_normalize(panel.name))
				.bind(button.name)
			)

func _str_normalize(s:String) -> String:
	return s.replace(" ", "_").to_lower()

func switch_menu(menu:String) -> void:
	for panel in get_children():
		if panel is not Panel: continue
		if panel.name == menu:
			active_menu = panel
			return
	assert(false, "Menu \"%s\" not found." % menu)

func _main_menu(button:String) -> void:
	match button:
		"Play":
			switch_menu("Lobby Select")
			await _fetch_lobbies()
		"Settings":
			print("settings pressed")
		"Credits":
			switch_menu("Credits")

func _lobby_select(button:String) -> void:
	match button:
		"Back":
			switch_menu("Main Menu")
		"Join":
			var items = list.get_selected_items()
			if not items.is_empty():
				Global.load_lobby(lobbies[selected_lobby])
		"New Room":
			#switch_menu("Create Room")
			#var line:LineEdit = $"Create Room/VBoxContainer/LineEdit"
			#line.clear()
			#line.grab_focus()
			var lobby := await Global.create_lobby()
			Global.load_lobby(lobby, true)
		"Refresh":
			refresh_button.disabled = true
			await _fetch_lobbies()
			refresh_button.disabled = false
		"Debug":
			pass

func _loading_screen(button:String) -> void:
	match button:
		"Cancel":
			Global.load_cancel_flag = true
			Global.lobby_loaded.emit()

func _credits(button:String) -> void:
	match button:
		"Back":
			switch_menu("Main Menu")

func _create_room(_button:String) -> void:
	#match button:
		#"Back":
			#switch_menu("Lobby Select")
		#"Create":
			#var line:LineEdit = $"Create Room/VBoxContainer/LineEdit"
			#var lobby:Global.Lobby = await Global.create_lobby(line.text)
			#Global.load_lobby(lobby)
	pass
