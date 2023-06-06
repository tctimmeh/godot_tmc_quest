extends GutTest

var quest: Task

func before_each():
    quest = Task.new()

func test_activate_task_does_not_activate_subtasks():
    var t = Task.new()
    assert_false(t.active)

    quest.add_subtask(t)
    quest.activate()
    assert_false(t.active)

func test_activate_task_doest_not_activate_conditions_on_subtasks():
    var t = Task.new()
    var c = TaskCondition.new()
    t.add_condition(c)
    assert_false(c.active)

    self.quest.add_subtask(t)
    self.quest.activate()
    assert_false(c.active)
