@tool
extends Control

signal inspect(object)

const QuestGraphNodeScene := preload("res://addons/tmc_quest/editor/quest_graph_node.tscn")
const QuestGraphNode := preload("res://addons/tmc_quest/editor/quest_graph_node.gd")
const ConditionGraphNodeScene := preload("res://addons/tmc_quest/editor/condition_graph_node.tscn")
const ConditionGraphNode := preload("res://addons/tmc_quest/editor/condition_graph_node.gd")
const ActionGraphNodeScene := preload("res://addons/tmc_quest/editor/action_graph_node.tscn")
const ActionGraphNode := preload("res://addons/tmc_quest/editor/action_graph_node.gd")

const DefaultConditionIcon := preload("res://addons/tmc_quest/assets/condition_icon.svg")
const DefaultActionIcon := preload("res://addons/tmc_quest/assets/action_icon.svg")

enum SlotType {
    SubQuest = 1,
    Condition = 2,
    Action = 3,
}

enum QuestInputPort {
    Parent = 0,
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

@export var quest: Quest: set = set_quest

@onready var breadcrumb := %Breadcrumb
@onready var graph_edit := %GraphEdit
@onready var type_select_menu := %TypeSelectMenu

var nodes_by_object = {}
var selected_nodes = {}
var simulating = false

func _process(delta):
    if not quest or not simulating:
        return
    quest.advance()

func breadcrumb_string(q) -> String:
    var accum = ''
    if q.parent:
        accum += '[url="%s"]%s[/url] > ' % [q.parent.name, breadcrumb_string(q.parent)]
    accum += q.name
    return accum

func clear_all():
    graph_edit.clear_connections()
    selected_nodes.clear()
    var children = graph_edit.get_children().duplicate()
    for node in children:
        graph_edit.remove_child(node)
    nodes_by_object.clear()

func set_quest(new_quest: Quest):
    quest = new_quest
    if not quest:
        return

    %SimulateButton.button_pressed = false
    _on_simulate_button_toggled(false)

    clear_all()
    breadcrumb.text = breadcrumb_string(quest)
    var quest_node = create_quest_graph_nodes(quest)

func _on_node_dragged(from: Vector2, to: Vector2, node: GraphNode):
    node.get_meta("object").editor_pos = to

func create_graph_node(type, object) -> GraphNode:
    var node = type.instantiate() as GraphNode
    nodes_by_object[object] = node

    node.dragged.connect(_on_node_dragged.bind(node))
    node.set_meta("object", object)
    node.position_offset = object.editor_pos
    return node

func create_quest_graph_nodes(quest: Quest) -> QuestGraphNode:
    var quest_node = create_quest_node(quest)
    graph_edit.add_child(quest_node)

    if quest.parent:
        graph_edit.connect_node(
            nodes_by_object[quest.parent].name,
            QuestOutputPort.Subquests,
            quest_node.name,
            QuestInputPort.Parent,
        )

    for subquest in quest.subquests:
        create_quest_graph_nodes(subquest)

    for condition in quest.conditions:
        create_condition_node(condition, quest)

    return quest_node

func create_condition_node(condition: QuestCondition, quest: Quest):
    var node := create_graph_node(ConditionGraphNodeScene, condition) as ConditionGraphNode
    node.condition = condition
    node.set_meta("quest", quest)
    node.set_meta("condition", condition)
    graph_edit.add_child(node)

    graph_edit.connect_node(
        nodes_by_object[quest].name,
        QuestOutputPort.Conditions,
        node.name,
        ConditionInputPort.Quest
    )

    for action in condition.actions:
        create_action_node(action, condition)

    return node

func create_action_node(action: QuestAction, trigger):
    var node := create_graph_node(ActionGraphNodeScene, action) as ActionGraphNode
    node.action = action
    node.set_meta("action", action)
    graph_edit.add_child(node)

    graph_edit.connect_node(
        nodes_by_object[trigger].name,
        QuestOutputPort.Conditions,
        node.name,
        ConditionInputPort.Quest
    )
    return node

func create_quest_node(quest: Quest) -> QuestGraphNode:
    var node := create_graph_node(QuestGraphNodeScene, quest) as QuestGraphNode
    node.quest = quest
    node.set_meta("quest", quest)
    return node

func _on_graph_edit_node_selected(node:Node):
    node.overlay = GraphNode.OVERLAY_BREAKPOINT
    selected_nodes[node] = true
    if selected_nodes.size() != 1:
        return

    var object = node.get_meta("object")
    inspect.emit(object)

func _on_graph_edit_node_deselected(node:Node):
    node.overlay = GraphNode.OVERLAY_DISABLED
    selected_nodes.erase(node)
    if selected_nodes.size() ==  1:
        var sel_node = selected_nodes.keys()[0]
        inspect.emit(sel_node.get_meta("object"))
        return

    if not selected_nodes.size():
        inspect.emit(quest)

func _on_graph_edit_connection_request(from_node_name:StringName, from_port:int, to_node_name:StringName, to_port:int):
    var from_node = graph_edit.get_node(str(from_node_name))
    var to_node = graph_edit.get_node(str(to_node_name))

    if from_node is QuestGraphNode:
        var from_quest = from_node.get_meta("quest") as Quest
        if to_node is QuestGraphNode:
            var to_quest = to_node.get_meta("quest") as Quest
            if to_quest.parent:
                return
            from_quest.add_subquest(to_quest)
        elif to_node is ConditionGraphNode:
            var to_condition = to_node.get_meta("condition") as QuestCondition
            from_quest.add_condition(to_condition)
    elif from_node is ConditionGraphNode:
        var from_condition = from_node.get_meta("condition") as QuestCondition
        if to_node is ActionGraphNode:
            var to_action = to_node.get_meta("action") as QuestAction
            from_condition.add_action(to_action)
    elif from_node is ActionGraphNode:
        var from_action = from_node.get_meta("action") as QuestAction
        if to_node is ActionGraphNode:
            var to_action = to_node.get_meta("action") as QuestAction
            # TODO:: connect this action to the other action
        if to_node is QuestGraphNode:
            var to_quest = to_node.get_meta("quest") as Quest
            # TODO:: connect this action to the quest

    graph_edit.connect_node(from_node_name, from_port, to_node_name, to_port)

func _on_graph_edit_disconnection_request(from_node_name:StringName, from_port:int, to_node_name:StringName, to_port:int):
    var parent_node = graph_edit.get_node(str(from_node_name))
    var to_node = graph_edit.get_node(str(to_node_name))

    if parent_node is QuestGraphNode:
        var from_quest = parent_node.get_meta("quest") as Quest
        if from_port == QuestOutputPort.Subquests:
            var to_quest = to_node.get_meta("quest") as Quest
            from_quest.remove_subquest(to_quest)
        elif from_port == QuestOutputPort.Conditions:
            var to_condition = to_node.get_meta("condition")
            from_quest.remove_condition(to_condition)

    elif parent_node is ConditionGraphNode:
        var from_condition = parent_node.get_meta("condition") as QuestCondition
        var to_action = to_node.get_meta("action") as QuestAction
        from_condition.remove_action(to_action)
    # elif parent_node is ActionGraphNodeClass:
    #     pass # disconnect a quest from this action

    graph_edit.disconnect_node(from_node_name, from_port, to_node_name, to_port)

func _on_graph_edit_connection_to_empty(from_node_name:StringName, from_port:int, release_position:Vector2):
    var parent_node = graph_edit.get_node(str(from_node_name))
    var grid_position = release_position_to_grid_position(release_position)

    if parent_node is QuestGraphNode:
        var from_quest = parent_node.get_meta("quest")
        match from_port:
            QuestOutputPort.Subquests:
                new_subquest(from_quest, grid_position)
            QuestOutputPort.Conditions:
                new_object_from_type_list(&"QuestCondition", DefaultConditionIcon, from_quest, grid_position)
    elif parent_node is ConditionGraphNode:
        var from_condition = parent_node.get_meta("condition")
        new_object_from_type_list(&"QuestAction", DefaultActionIcon, from_condition, grid_position)

func release_position_to_grid_position(release_position: Vector2):
    var grid_pos = release_position / graph_edit.zoom
    grid_pos += graph_edit.scroll_offset / graph_edit.zoom
    return grid_pos

func new_subquest(parent_quest: Quest, position: Vector2):
    var new_quest = Quest.new()
    new_quest.editor_pos = position
    parent_quest.add_subquest(new_quest)
    var node = create_quest_graph_nodes(new_quest)
    node.position_offset = position

func popup_menu_at_mouse(menu: PopupMenu):
    menu.position = get_screen_position() + get_local_mouse_position()
    menu.reset_size()
    menu.popup()

func new_object_from_type_list(baseType: StringName, defaultIcon: Texture2D, parent_object, position: Vector2):
    var by_base = func(x): return x.base == baseType
    var by_name = func(x): return x["class"]

    var class_info = ProjectSettings.get_global_class_list()
    var classes = class_info.filter(by_base)
    classes.sort_custom(by_name)

    type_select_menu.clear()
    type_select_menu.set_meta("position", position)
    type_select_menu.set_meta("parent_object", parent_object)
    var index = 0
    for cls_info in classes:
        var base_name = str(cls_info["base"])
        var item_name = str(cls_info["class"])
        if item_name.ends_with(base_name):
            item_name = item_name.replace(base_name, "")

        type_select_menu.add_item(item_name)
        type_select_menu.set_item_icon(
            index,
            load(cls_info["icon"]) if cls_info["icon"] else defaultIcon
        )
        type_select_menu.set_item_metadata(index, cls_info)
        index += 1

    popup_menu_at_mouse(type_select_menu)

func _on_type_select_menu_index_pressed(index):
    var parent_object = type_select_menu.get_meta("parent_object")
    var parent_node = nodes_by_object[parent_object]

    var cls_info = type_select_menu.get_item_metadata(index)
    var cls = load(cls_info["path"])

    var new_object = cls.new()
    new_object.editor_pos = type_select_menu.get_meta("position")
    var new_object_node

    if new_object is QuestCondition:
        parent_object.add_condition(new_object)
        create_condition_node(new_object, parent_object)
    if new_object is QuestAction:
        parent_object.add_action(new_object)
        create_action_node(new_object, parent_object)

func _on_graph_edit_delete_nodes_request(nodes:Array):
    var nodes_to_delete = selected_nodes.keys()
    for node in nodes_to_delete:
        delete_node(node)

func delete_node(node):
    var connections = graph_edit.get_connection_list()
    var object = node.get_meta("object")
    selected_nodes.erase(node)

    if object is Quest:
        if object.parent:
            object.parent.remove_subquest(object)
        for subquest in object.subquests:
            subquest.parent = null
    elif object is QuestCondition:
        var quest = node.get_meta("quest")
        quest.remove_condition(object)
    elif object is QuestAction:
        var triggers = connections.filter(func(c): return c["to"] == node.name)
        for trigger in triggers:
            var trigger_node = graph_edit.get_node(str(trigger["from"]))
            var trigger_obj
            if trigger_node is ConditionGraphNode:
                trigger_obj = trigger_node.get_meta("condition")
            elif trigger_node is ActionGraphNode:
                trigger_obj = trigger_node.get_meta("action")
            trigger_obj.remove_action(object)
    else:
        print_debug("Deleting unknown node type")

    for connection in connections:
        if connection['from'] == node.name or connection['to'] == node.name:
            graph_edit.disconnect_node(
                connection['from'],
                connection['from_port'],
                connection['to'],
                connection['to_port'],
            )

    graph_edit.remove_child(node)

func _on_simulate_button_toggled(button_pressed:bool):
    simulating = button_pressed
    if simulating:
        %SimulateButton.text = "Simulating..."
        for child in graph_edit.get_children():
            child.start_simulation()
    else:
        %SimulateButton.text = "Simulate"
        for child in graph_edit.get_children():
            child.end_simulation()
