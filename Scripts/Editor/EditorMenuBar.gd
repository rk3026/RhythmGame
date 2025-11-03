extends MenuBar
class_name EditorMenuBar
## Editor Menu Bar Component
## Handles all menu actions with signal-based communication

# File menu signals
signal new_chart_requested()
signal open_chart_requested()
signal save_requested()
signal save_as_requested()
signal import_chart_requested()
signal export_chart_requested()

# Edit menu signals
signal undo_requested()
signal redo_requested()
signal cut_requested()
signal copy_requested()
signal paste_requested()
signal delete_requested()

# View menu signals
signal zoom_in_requested()
signal zoom_out_requested()
signal reset_zoom_requested()
signal toggle_grid_requested()

# Playback menu signals
signal play_pause_requested()
signal stop_requested()
signal test_play_requested()

@onready var file_menu: PopupMenu = $FileMenu
@onready var edit_menu: PopupMenu = $EditMenu
@onready var view_menu: PopupMenu = $ViewMenu
@onready var playback_menu: PopupMenu = $PlaybackMenu

# Menu item IDs
enum FileMenuItems {
	NEW_CHART,
	OPEN_CHART,
	SEPARATOR_1,
	SAVE,
	SAVE_AS,
	SEPARATOR_2,
	IMPORT_CHART,
	EXPORT_CHART
}

enum EditMenuItems {
	UNDO,
	REDO,
	SEPARATOR_1,
	CUT,
	COPY,
	PASTE,
	DELETE,
	SEPARATOR_2
}

enum ViewMenuItems {
	ZOOM_IN,
	ZOOM_OUT,
	RESET_ZOOM,
	SEPARATOR_1,
	TOGGLE_GRID
}

enum PlaybackMenuItems {
	PLAY_PAUSE,
	STOP,
	TEST_PLAY
}

func _ready():
	_connect_menu_signals()

func _connect_menu_signals():
	file_menu.id_pressed.connect(_on_file_menu_id_pressed)
	edit_menu.id_pressed.connect(_on_edit_menu_id_pressed)
	view_menu.id_pressed.connect(_on_view_menu_id_pressed)
	playback_menu.id_pressed.connect(_on_playback_menu_id_pressed)

func _on_file_menu_id_pressed(id: int):
	match id:
		FileMenuItems.NEW_CHART:
			new_chart_requested.emit()
		FileMenuItems.OPEN_CHART:
			open_chart_requested.emit()
		FileMenuItems.SAVE:
			save_requested.emit()
		FileMenuItems.SAVE_AS:
			save_as_requested.emit()
		FileMenuItems.IMPORT_CHART:
			import_chart_requested.emit()
		FileMenuItems.EXPORT_CHART:
			export_chart_requested.emit()

func _on_edit_menu_id_pressed(id: int):
	match id:
		EditMenuItems.UNDO:
			undo_requested.emit()
		EditMenuItems.REDO:
			redo_requested.emit()
		EditMenuItems.CUT:
			cut_requested.emit()
		EditMenuItems.COPY:
			copy_requested.emit()
		EditMenuItems.PASTE:
			paste_requested.emit()
		EditMenuItems.DELETE:
			delete_requested.emit()

func _on_view_menu_id_pressed(id: int):
	match id:
		ViewMenuItems.ZOOM_IN:
			zoom_in_requested.emit()
		ViewMenuItems.ZOOM_OUT:
			zoom_out_requested.emit()
		ViewMenuItems.RESET_ZOOM:
			reset_zoom_requested.emit()
		ViewMenuItems.TOGGLE_GRID:
			toggle_grid_requested.emit()

func _on_playback_menu_id_pressed(id: int):
	match id:
		PlaybackMenuItems.PLAY_PAUSE:
			play_pause_requested.emit()
		PlaybackMenuItems.STOP:
			stop_requested.emit()
		PlaybackMenuItems.TEST_PLAY:
			test_play_requested.emit()

func set_undo_enabled(enabled: bool):
	edit_menu.set_item_disabled(EditMenuItems.UNDO, not enabled)

func set_redo_enabled(enabled: bool):
	edit_menu.set_item_disabled(EditMenuItems.REDO, not enabled)

func set_grid_checked(checked: bool):
	view_menu.set_item_checked(ViewMenuItems.TOGGLE_GRID, checked)
