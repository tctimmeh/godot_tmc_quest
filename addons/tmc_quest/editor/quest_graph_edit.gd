@tool
extends GraphEdit

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

@export var quest: Quest: set = set_quest

var quest_name_label := Label.new()

func _ready():
    setup_toolbar()

func setup_toolbar():
    var toolbar_hbox = get_zoom_hbox()

    var new_button := Button.new()
    new_button.name = "NewQuestButton"
    new_button.text = "New Quest"
    new_button.pressed.connect(_on_new_quest_button_pressed)
    toolbar_hbox.add_child(new_button)

    toolbar_hbox.add_child(quest_name_label)

func _on_new_quest_button_pressed():
    var new_quest = Quest.new()
    set_quest(new_quest)

func remove_graph_nodes():
    for child in get_children():
        if child is GraphNode:
            child.queue_free()

func set_quest(new_quest):
    remove_graph_nodes()
    clear_connections()
    quest = new_quest
    if not quest:
        return

    quest_name_label.text = new_quest.name
    create_graph_nodes(quest)
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

func create_graph_node(quest: Quest, position: Vector2 = Vector2(0, 0)) -> GraphNode:
    var quest_node = QuestGraphNode.instantiate()
    quest_node.quest = quest
    quest_node.set_meta("quest", quest)
    if position:
        quest_node.position_offset = position
    return quest_node

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
    if from_port == OutputPort.Subquests:
        new_subquest(parent_node, release_position_to_grid_position(release_position))

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
