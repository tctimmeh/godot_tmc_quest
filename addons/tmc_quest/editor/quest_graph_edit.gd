@tool
extends Control

signal inspect(object)

const QuestGraphNodeScene := preload("res://addons/tmc_quest/editor/quest_graph_node.tscn")
const QuestGraphNode := preload("res://addons/tmc_quest/editor/quest_graph_node.gd")

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
    node.dragged.connect(_on_node_dragged.bind(node))
    node.set_meta("object", object)
    node.position_offset = object.editor_pos
    return node

func create_quest_graph_nodes(quest: Quest) -> QuestGraphNode:
    var quest_node = create_quest_node(quest)
    graph_edit.add_child(quest_node)
    nodes_by_object[quest] = quest_node

    if quest.parent:
        graph_edit.connect_node(
            nodes_by_object[quest.parent].name,
            QuestOutputPort.Subquests,
            quest_node.name,
            QuestInputPort.Parent,
        )

    for subquest in quest.subquests:
        create_quest_graph_nodes(subquest)

    return quest_node

func create_quest_node(quest) -> QuestGraphNode:
    var quest_node := create_graph_node(QuestGraphNodeScene, quest) as QuestGraphNode
    # quest_node.context_requested.connect(_on_graph_node_context_requested.bind(quest_node))
    quest_node.quest = quest
    quest_node.set_meta("quest", quest)
    return quest_node


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
