@tool
extends GraphEdit

signal inspect(object)

const QuestGraphNode := preload("res://addons/tmc_quest/editor/quest_graph_node.tscn")
const ConditionGraphNode := preload("res://addons/tmc_quest/editor/condition_graph_node.tscn")
const ActionGraphNode := preload("res://addons/tmc_quest/editor/action_graph_node.tscn")
const DefaultConditionIcon := preload("res://addons/tmc_quest/assets/condition_icon.svg")

const QuestGraphNodeClass := preload("res://addons/tmc_quest/editor/quest_graph_node.gd")
const ConditionGraphNodeClass := preload("res://addons/tmc_quest/editor/condition_graph_node.gd")
const ActionGraphNodeClass := preload("res://addons/tmc_quest/editor/action_graph_node.gd")

enum SlotType {
    ParentChild = 1,
    QuestCondition = 2,
    Action = 3,
}

enum QuestSlot {
    Parent = 0,
    Events = 2,
    Conditions = 3,
    Subquests = 4,
}

enum ConditionSlot {
    Quest = 0,
    Actions = 2,
}

enum QuestInputPort {
    Parent = 0,
    Events = 1,
}

enum QuestOutputPort {
    Conditions = 0,
    Subquests = 1,
}

enum ConditionInputPort {
    Quest = 0,
}

enum ConditionOutputPort {
    Actions = 0,
}

enum ActionInputPort {
    Trigger = 0,
}

enum ActionOutputPort {
    Target = 0,
}

enum ContextMenuItems {
    Rename = 0,
    Delete = 2,
}

@export var quest: Quest: set = set_quest

@onready var context_menu := %ContextMenu
@onready var type_select_menu := %TypeSelectMenu
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
    var root = quest
    while root.parent:
        root = root.parent

    if not root.resource_path.length():
        save_dialog.popup_centered()
        return
    ResourceSaver.save(root)

func _on_save_dialog_file_selected(path):
    var root = quest
    while root.parent:
        root = root.parent

    root.resource_path = path
    ResourceSaver.save(root)

func _on_new_quest_button_pressed():
    var new_quest = Quest.new()
    set_quest(new_quest)

func _on_save_button_pressed():
    save()

func clear_graph_nodes():
    for child in get_children():
        if child is GraphNode:
            remove_child(child)
            child.queue_free()

func set_quest(new_quest):
    if not new_quest:
        return

    quest = new_quest
    quest.set_subquest_parents()
    clear_graph_nodes()
    clear_connections()
    create_quest_graph_nodes(quest)
    selected_nodes.clear()
    call_deferred("arrange_nodes")

func create_quest_graph_nodes(quest: Quest, parent_node: GraphNode = null):
    var position = Vector2(120, 120)
    var quest_node = create_quest_graph_node(quest, position)
    add_child(quest_node)

    if parent_node:
        connect_node(
            parent_node.name,
            QuestOutputPort.Subquests,
            quest_node.name,
            QuestInputPort.Parent
        )

    create_condition_graph_nodes(quest, quest_node, position)

    for subquest in quest.subquests:
        create_quest_graph_nodes(subquest, quest_node)

func create_quest_graph_node(quest: Quest, position: Vector2 = Vector2(100, 100)) -> GraphNode:
    var quest_node = QuestGraphNode.instantiate()
    quest_node.context_requested.connect(_on_graph_node_context_requested.bind(quest_node))
    quest_node.quest = quest
    quest_node.set_meta("quest", quest)
    if position:
        quest_node.position_offset = position

    return quest_node

func create_condition_graph_nodes(quest: Quest, parent_node: GraphNode, position: Vector2):
    for condition in quest.conditions:
        var condition_node = create_condition_graph_node(quest, condition, position)
        add_child(condition_node)

        connect_node(
            parent_node.name,
            QuestOutputPort.Conditions,
            condition_node.name,
            ConditionInputPort.Quest
        )

        create_action_graph_nodes(condition, condition_node, position)

func create_condition_graph_node(quest: Quest, condition: QuestCondition, position: Vector2 = Vector2(100, 100)):
    var condition_node = ConditionGraphNode.instantiate()
    condition_node.context_requested.connect(_on_graph_node_context_requested.bind(condition_node))
    condition_node.condition = condition

    condition_node.set_meta("quest", quest)
    condition_node.set_meta("condition", condition)
    if position:
        condition_node.position_offset = position
    return condition_node

func create_action_graph_nodes(parentObject, parent_node: GraphNode, position: Vector2):
    # TODO:: parent obj may be a condition or an action...
    for action in parentObject.actions:
        var action_node = create_action_graph_node(action, position)
        add_child(action_node)

        # TODO:: same here
        connect_node(
            parent_node.name,
            ConditionOutputPort.Actions,
            action_node.name,
            ActionInputPort.Trigger
        )

    # TODO:: create target actions if any
    # for subquest in quest.subquests:
    #     create_quest_graph_nodes(subquest, quest_node)

func create_action_graph_node(action: QuestAction, position: Vector2 = Vector2(100, 100)):
    var action_node = ActionGraphNode.instantiate()
    action_node.context_requested.connect(_on_graph_node_context_requested.bind(action_node))
    action_node.action = action

    action_node.set_meta("action", action)
    if position:
        action_node.position_offset = position
    return action_node

func _on_graph_node_context_requested(node: GraphNode):
    if selected_nodes.size() < 2:
        set_selected(node)

func _on_connection_request(from_node_name, from_port, to_node_name, to_port):
    var from_node = get_node(str(from_node_name))
    var to_node = get_node(str(to_node_name))

    if from_node is QuestGraphNodeClass:
        var from_quest = from_node.get_meta("quest") as Quest
        if to_node is QuestGraphNodeClass:
            var to_quest = to_node.get_meta("quest") as Quest
            if to_quest.parent:
                return
            from_quest.add_subquest(to_quest)
        elif to_node is ConditionGraphNodeClass:
            var to_condition = to_node.get_meta("condition") as QuestCondition
            from_quest.add_condition(to_condition)

    connect_node(from_node_name, from_port, to_node_name, to_port)

func release_position_to_grid_position(release_position: Vector2):
    var grid_pos = release_position / zoom
    grid_pos += scroll_offset / zoom
    grid_pos.y -= 55 # small bump so that mouse cursor is over Parent port
    return grid_pos

func _on_connection_to_empty(from_node_name, from_port, release_position: Vector2):
    var parent_node = get_node(str(from_node_name))
    var grid_position = release_position_to_grid_position(release_position)

    if parent_node is QuestGraphNodeClass:
        match from_port:
            QuestOutputPort.Subquests:
                new_subquest(parent_node, grid_position)
            QuestOutputPort.Conditions:
                new_condition(parent_node, grid_position)
    elif parent_node is ConditionGraphNodeClass:
        pass # new_action(parent_node, grid_position)

func new_condition(parent_node: GraphNode, position: Vector2):
    var by_base = func(x): return x.base == &"QuestCondition"
    var by_name = func(x): return x["class"]

    var class_info = ProjectSettings.get_global_class_list()
    var condition_classes = class_info.filter(by_base)
    condition_classes.sort_custom(by_name)

    type_select_menu.clear()
    type_select_menu.set_meta("position", position)
    type_select_menu.set_meta("parent_node", parent_node)
    var index = 0
    for cls_info in condition_classes:
        type_select_menu.add_item(cls_info["class"])
        type_select_menu.set_item_icon(
            index,
            load(cls_info["icon"]) if cls_info["icon"] else DefaultConditionIcon
        )
        type_select_menu.set_item_metadata(index, cls_info)
        index += 1

    popup_menu_at_mouse(type_select_menu)

func _on_type_select_menu_index_pressed(index):
    var parent_node = type_select_menu.get_meta("parent_node")
    var position = type_select_menu.get_meta("position")
    var cls_info = type_select_menu.get_item_metadata(index)
    var cls = load(cls_info["path"])
    var new_object = cls.new()
    var new_object_node

    if new_object is QuestCondition:
        var parent_quest = parent_node.get_meta("quest") as Quest
        parent_quest.add_condition(new_object)
        new_object_node = create_condition_graph_node(quest, new_object, position)
    if new_object is QuestAction:
        var parent_condition = parent_node.get_meta("condition") as QuestCondition
        parent_condition.add_action(new_object)
        # new_object_node = create_action_graph_node(condition, new_object, position)

    add_child(new_object_node)
    connect_node(
        parent_node.name,
        QuestOutputPort.Conditions,
        new_object_node.name,
        ConditionInputPort.Quest,
    )

func new_subquest(parent_node: GraphNode, position: Vector2):
    var parent_quest = parent_node.get_meta("quest") as Quest

    var new_quest = Quest.new()
    parent_quest.add_subquest(new_quest)

    var quest_node = create_quest_graph_node(new_quest, position)
    add_child(quest_node)
    connect_node(
        parent_node.name,
        QuestOutputPort.Subquests,
        quest_node.name,
        QuestInputPort.Parent
    )

func _on_disconnection_request(from_node_name, from_port, to_node_name, to_port):
    var parent_node = get_node(str(from_node_name))
    var to_node = get_node(str(to_node_name))

    if parent_node is QuestGraphNodeClass:
        var from_quest = parent_node.get_meta("quest") as Quest
        if from_port == QuestOutputPort.Subquests:
            var to_quest = to_node.get_meta("quest") as Quest
            from_quest.remove_subquest(to_quest)
        elif from_port == QuestOutputPort.Conditions:
            var to_condition = to_node.get_meta("condition")
            from_quest.remove_condition(to_condition)

    elif parent_node is ConditionGraphNodeClass:
        pass # disconnect an action from this condition
    # elif parent_node is ActionGraphNodeClass:
    #     pass # disconnect a quest from this action

    disconnect_node(from_node_name, from_port, to_node_name, to_port)

func popup_menu_at_mouse(menu: PopupMenu):
    menu.position = get_screen_position() + get_local_mouse_position()
    menu.reset_size()
    menu.popup()

func _on_popup_request(position:Vector2):
    var can_delete = bool(selected_nodes.size())
    var can_rename = (selected_nodes.size() == 1 and selected_nodes.keys()[0] is QuestGraphNodeClass)

    context_menu.set_item_disabled(ContextMenuItems.Rename, not can_rename)
    context_menu.set_item_disabled(ContextMenuItems.Delete, not can_delete)

    popup_menu_at_mouse(context_menu)

func _on_popup_menu_id_pressed(id:int):
    match id:
        ContextMenuItems.Rename:
            if not selected_nodes.size():
                return
            if selected_nodes.size() > 1:
                %RenameTooManyDialog.popup_centered()
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
    if node is QuestGraphNodeClass:
        if quest.parent:
            quest.parent.get_ref().remove_subquest(quest)
        for subquest in quest.subquests:
            subquest.parent = null
    elif node is ConditionGraphNodeClass:
        var condition = node.get_meta("condition")
        quest.remove_condition(condition)

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
        var object
        if node is QuestGraphNodeClass:
            object = node.get_meta("quest")
        elif node is ConditionGraphNodeClass:
            object = node.get_meta("condition")

        inspect.emit(object)

    selected_nodes[node] = true

func _on_node_deselected(node:Node):
    selected_nodes.erase(node)
    if selected_nodes.size() ==  1:
        var sel_node = selected_nodes.keys()[0]
        if sel_node is QuestGraphNodeClass:
            inspect.emit(selected_nodes.keys()[0].get_meta("quest"))
        elif sel_node is ConditionGraphNodeClass:
            inspect.emit(selected_nodes.keys()[0].get_meta("condition"))
        # elif sel_node is ActionGraphNodeClass:
        #     inspect.emit(selected_nodes.keys()[0].get_meta("action"))
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
