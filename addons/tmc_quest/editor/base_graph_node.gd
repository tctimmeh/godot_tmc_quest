@tool
extends GraphNode

# const action_port_color := Color("#dd2020")
# const condition_port_color := Color("0099ff")
# const quest_port_color := Color("#22bb11")

func set_node_active(active):
    if active:
        self_modulate = Color.WHITE
    else:
        self_modulate = Color("#ffffff99")
