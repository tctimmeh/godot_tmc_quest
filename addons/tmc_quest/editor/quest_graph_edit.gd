@tool
extends GraphEdit

signal inspect(object)

const QuestGraphNode := preload("res://addons/tmc_quest/editor/quest_graph_node.tscn")

enum SlotType {
    Child = 1,
    Event = 2,
    Condition = 3,
}

enum Slot {
    Parent = 0,
    Events = 2,
    Conditions = 3,
    Subquests = 4,
}

enum InputPort {
    Parent = 0,
    Events = 1,
}

enum OutputPort {
    Conditions = 0,
    Subquests = 1,
}

enum ContextMenuItems {
    Rename = 0,
    Delete = 2,
}

@export var quest: Quest: set = set_quest

@onready var context_menu := %ContextMenu
@onready var rename_dialog := %RenameDialog
@onready var new_name_edit := %NewNameEdit

var selected_nodes = {}
var save_dialog: EditorFileDialog

func _ready():
    setup_toolbar()
    create_save_dialog()

func setup_toolbar():
    var toolbar_hbox = get_zoom_hbox()

    var new_button := Button.new()
    new_button.name = "NewQuestButton"
    new_button.text = "New Quest"
    new_button.pressed.connect(_on_new_quest_button_pressed)
    toolbar_hbox.add_child(new_button)

    var save_button := Button.new()
    save_button.name = "SaveButton"
    save_button.text = "Save"
    save_button.pressed.connect(_on_save_button_pressed)
    toolbar_hbox.add_child(save_button)

func create_save_dialog():
    save_dialog = EditorFileDialog.new()
    save_dialog.name = "SaveDialog"
    save_dialog.title = "Save Quest"
    save_dialog.dialog_hide_on_ok = true
    save_dialog.display_mode = EditorFileDialog.DISPLAY_LIST
    save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
    save_dialog.add_filter("*.tres", "Resources")
    save_dialog.size = Vector2(800, 600)
    save_dialog.file_selected.connect(_on_save_dialog_file_selected)
    add_child(save_dialog)

func save():
    if not quest.resource_path.length():
        save_dialog.popup_centered()
        return
    ResourceSaver.save(quest)

func _on_save_dialog_file_selected(path):
    quest.resource_path = path
    ResourceSaver.save(quest)

func _on_new_quest_button_pressed():
    var new_quest = Quest.new()
    set_quest(new_quest)

func _on_save_button_pressed():
    save()

func remove_graph_nodes():
    for child in get_children():
        if child is GraphNode:
            remove_child(child)
            child.queue_free()

func set_quest(new_quest):
    if not new_quest:
        return

    quest = new_quest
    quest.set_subquest_parents()
    remove_graph_nodes()
    clear_connections()
    create_graph_nodes(quest)
    selected_nodes.clear()
    call_deferred("arrange_nodes")

func create_graph_nodes(quest: Quest, parent_node: GraphNode = null):
    var quest_node = create_graph_node(quest, Vector2(120, 120))
    add_child(quest_node)

    if parent_node:
        connect_node(
            parent_node.name,
            OutputPort.Subquests,
            quest_node.name,
            InputPort.Parent
        )

    for subquest in quest.subquests:
        create_graph_nodes(subquest, quest_node)

func create_graph_node(quest: Quest, position: Vector2 = Vector2(100, 100)) -> GraphNode:
    var quest_node = QuestGraphNode.instantiate()
    quest_node.context_requested.connect(_on_graph_node_context_requested.bind(quest_node))
    quest_node.quest = quest
    quest_node.set_meta("quest", quest)
    if position:
        quest_node.position_offset = position
    return quest_node

func _on_graph_node_context_requested(node: GraphNode):
    if not selected_nodes.size():
        set_selected(node)

func _on_connection_request(from_node_name, from_port, to_node_name, to_port):
    if to_port == InputPort.Parent:
        var from_node = get_node(str(from_node_name))
        var from_quest = from_node.get_meta("quest") as Quest
        var to_node = get_node(str(to_node_name))
        var to_quest = to_node.get_meta("quest") as Quest
        if to_quest.parent:
            return
        from_quest.add_subquest(to_quest)

    connect_node(from_node_name, from_port, to_node_name, to_port)

func release_position_to_grid_position(release_position: Vector2):
    var grid_pos = release_position / zoom
    grid_pos += scroll_offset / zoom
    grid_pos.y -= 55 # small bump so that mouse cursor is over Parent port
    return grid_pos

func _on_connection_to_empty(from_node_name, from_port, release_position: Vector2):
    var parent_node = get_node(str(from_node_name))
    var grid_position = release_position_to_grid_position(release_position)
    match from_port:
        OutputPort.Subquests:
            new_subquest(parent_node, grid_position)
        OutputPort.Conditions:
            new_condition(parent_node, grid_position)

func new_condition(parent_node: GraphNode, position: Vector2):
    var class_info = ProjectSettings.get_global_class_list()
    var filter = func(x): return x.base == &"QuestCondition"
    var all_classes = class_info.filter(filter)
    for c in all_classes:
        var cls = load(c["path"])
        prints(cls.name, '-', cls)

func new_subquest(parent_node: GraphNode, position: Vector2):
    var parent_quest = parent_node.get_meta("quest") as Quest

    var new_quest = Quest.new()
    parent_quest.add_subquest(new_quest)

    var quest_node = create_graph_node(new_quest, position)
    add_child(quest_node)
    connect_node(
        parent_node.name,
        OutputPort.Subquests,
        quest_node.name,
        InputPort.Parent
    )

func _on_disconnection_request(from_node_name, from_port, to_node_name, to_port):
    if to_port == InputPort.Parent:
        var from_node = get_node(str(from_node_name))
        var to_node = get_node(str(to_node_name))
        var from_quest = from_node.get_meta("quest") as Quest
        var to_quest = to_node.get_meta("quest") as Quest
        from_quest.remove_subquest(to_quest)

    disconnect_node(from_node_name, from_port, to_node_name, to_port)

func _on_popup_request(position:Vector2):
    context_menu.set_item_disabled(ContextMenuItems.Rename, selected_nodes.size() != 1)
    context_menu.set_item_disabled(ContextMenuItems.Delete, not bool(selected_nodes.size()))

    var screen_position = Vector2(DisplayServer.window_get_position()) + get_viewport().get_mouse_position()

    context_menu.popup()
    context_menu.position = screen_position

func _on_popup_menu_id_pressed(id:int):
    match id:
        ContextMenuItems.Rename:
            if not selected_nodes.size():
                return
            if selected_nodes.size() > 1:
                $RenameTooManyDialog.popup_centered()
                return
            show_rename_dialog(selected_nodes.keys()[0])
        ContextMenuItems.Delete:
            delete_nodes(selected_nodes.keys())

func show_rename_dialog(node):
    var quest = node.get_meta("quest")
    new_name_edit.text = quest.name
    new_name_edit.grab_focus()
    new_name_edit.select_all()
    rename_dialog.position = context_menu.position
    rename_dialog.set_meta("node", node)
    rename_dialog.popup()

func rename_node(node, new_name):
    node.title = new_name
    var quest = node.get_meta("quest")
    quest.name = new_name

func delete_node(node):
    var quest = node.get_meta("quest")
    if quest.parent:
        quest.parent.get_ref().remove_subquest(quest)
    for subquest in quest.subquests:
        subquest.parent = null

    var connections = get_connection_list()
    for connection in connections:
        if connection['from'] == node.name or connection['to'] == node.name:
            disconnect_node(
                connection['from'],
                connection['from_port'],
                connection['to'],
                connection['to_port'],
            )

    selected_nodes.erase(node)
    node.queue_free()

func delete_nodes(nodes):
    for node in nodes:
        delete_node(node)

func _on_node_selected(node:Node):
    if not selected_nodes.size():
        inspect.emit(node.get_meta("quest"))
    selected_nodes[node] = true

func _on_node_deselected(node:Node):
    selected_nodes.erase(node)
    if selected_nodes.size() ==  1:
        inspect.emit(selected_nodes.keys()[0].get_meta("quest"))
    if not selected_nodes.size():
        inspect.emit(quest)

func _on_cancel_rename_button_pressed():
    rename_dialog.hide()

func _on_ok_rename_button_pressed():
    var new_name = new_name_edit.text
    var node = rename_dialog.get_meta("node")
    rename_node(node, new_name)
    rename_dialog.hide()

func _on_new_name_edit_gui_input(event):
    if event is InputEventKey and event.keycode == KEY_ENTER:
        _on_ok_rename_button_pressed()
