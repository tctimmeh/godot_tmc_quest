@tool
extends EditorPlugin

const QuestGraphEdit = preload("res://addons/tmc_quest/editor/quest_graph_edit.tscn")
var graph_edit

func _enter_tree():
    graph_edit = QuestGraphEdit.instantiate()
    get_editor_interface().get_editor_main_screen().add_child(graph_edit)
    _make_visible(false)

func _exit_tree():
    if graph_edit:
        graph_edit.queue_free()

func _has_main_screen():
    return true

func _make_visible(visible):
    if graph_edit:
        graph_edit.visible = visible

func _get_plugin_name():
    return "Quest"

func _get_plugin_icon():
    return preload("res://addons/tmc_quest/assets/quest_icon.svg")

func _apply_changes():
    graph_edit.save()

func _clear():
    graph_edit.set_quest(null)

func _edit(quest):
    if not quest:
        _clear()
        return

    graph_edit.set_quest(quest)

func _handles(object):
    return object is Quest
