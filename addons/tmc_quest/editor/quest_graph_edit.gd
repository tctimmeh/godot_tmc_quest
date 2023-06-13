@tool
extends Control

signal inspect(object)

const QuestGraphNodeScene := preload("res://addons/tmc_quest/editor/quest_graph_node.tscn")
const QuestGraphNode := preload("res://addons/tmc_quest/editor/quest_graph_node.gd")
const ConditionGraphNodeScene := preload("res://addons/tmc_quest/editor/condition_graph_node.tscn")
const ConditionGraphNode := preload("res://addons/tmc_quest/editor/condition_graph_node.gd")
const ActionGraphNodeScene := preload("res://addons/tmc_quest/editor/action_graph_node.tscn")
const ActionGraphNode := preload("res://addons/tmc_quest/editor/action_graph_node.gd")

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

var nodes_by_object = {}
var selected_nodes = {}

func breadcrumb_string(q) -> String:
    var accum = ''
    if q.parent:
        accum += '[url="%s"]%s[/url] > ' % [q.parent.name, breadcrumb_string(q.parent)]
    accum += q.name
    return accum

func save():
    pass

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
        breadcrumb.text = ""
        return

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

    create_condition_nodes(quest)

    return quest_node

func create_condition_node(condition: QuestCondition, quest: Quest):
    var node := create_graph_node(ConditionGraphNodeScene, condition) as ConditionGraphNode
    node.condition = condition
    node.set_meta("quest", quest)
    node.set_meta("condition", condition)
    return node

func create_condition_nodes(quest: Quest):
    for condition in quest.conditions:
        var node = create_condition_node(condition, quest)
        graph_edit.add_child(node)

        graph_edit.connect_node(
            nodes_by_object[quest].name,
            QuestOutputPort.Conditions,
            node.name,
            ConditionInputPort.Quest
        )

        create_action_nodes(condition)

func create_action_node(action: QuestAction, trigger):
    var node := create_graph_node(ActionGraphNodeScene, action) as ActionGraphNode
    node.action = action
    node.set_meta("action", action)
    return node

func create_action_nodes(trigger):
    for action in trigger.actions:
        var node = create_action_node(action, trigger)
        graph_edit.add_child(node)

        graph_edit.connect_node(
            nodes_by_object[trigger].name,
            QuestOutputPort.Conditions,
            node.name,
            ConditionInputPort.Quest
        )

func create_quest_node(quest: Quest) -> QuestGraphNode:
    var node := create_graph_node(QuestGraphNodeScene, quest) as QuestGraphNode
    node.quest = quest
    node.set_meta("quest", quest)
    return node

func _on_graph_edit_node_selected(node:Node):
    selected_nodes[node] = true
    if selected_nodes.size() != 1:
        return

    var object = node.get_meta("object")
    inspect.emit(object)

func _on_graph_edit_node_deselected(node:Node):
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
