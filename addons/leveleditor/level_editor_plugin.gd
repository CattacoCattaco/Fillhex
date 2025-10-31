@tool
class_name LevelEditorPlugin
extends EditorPlugin

const MAIN_PANEL: PackedScene = preload("res://addons/leveleditor/editor/level_editor.tscn")

var main_panel_instance: LevelEditor


func _enter_tree():
	main_panel_instance = MAIN_PANEL.instantiate()
	# Add the main panel to the editor's main viewport.
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	# Hide the main panel. Very much required.
	_make_visible(false)
	
	InputMap.load_from_project_settings()


func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()


func _has_main_screen():
	return true


func _edit(object: Object) -> void:
	if object is LevelData:
		main_panel_instance.hex_grid.level = object


func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func _get_plugin_name():
	return "Level Editor"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("TileMapLayer", "EditorIcons")


func _handles(object: Object) -> bool:
	return object is LevelData
