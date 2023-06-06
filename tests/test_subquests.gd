extends GutTest

var quest: Quest

func before_each():
    quest = Quest.new()

func test_activate_quest_does_not_activate_subquests():
    var t = Quest.new()
    assert_false(t.active)

    quest.add_subquest(t)
    quest.activate()
    assert_false(t.active)

func test_activate_quest_doest_not_activate_conditions_on_subquests():
    var t = Quest.new()
    var c = QuestCondition.new()
    t.add_condition(c)
    assert_false(c.active)

    self.quest.add_subquest(t)
    self.quest.activate()
    assert_false(c.active)
