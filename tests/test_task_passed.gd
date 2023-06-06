extends GutTest

var quest: Task

func before_each():
    quest = Task.new()
    quest.activate()

func test_task_with_no_subs_and_no_conditions_auto_passes():
    assert_false(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Incomplete)

    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Passed)

func test_task_deactivates_when_passed():
    assert_true(quest.active)
    quest.advance()
    assert_eq(quest.outcome, Task.outcomes().Passed)
    assert_false(quest.active)

func test_task_stops_tracking_when_passed():
    quest.tracking = true
    quest.advance()
    assert_false(quest.tracking)

func test_task_not_passed_if_any_required_condition_not_passed():
    var c = TaskCondition.new()
    quest.add_condition(c)

    quest.advance()
    assert_false(c.passed)
    assert_false(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Incomplete)

func test_task_passed_if_only_required_conditions_passed():
    var req_cond = TaskCondition.new()
    req_cond.passed = true
    quest.add_condition(req_cond)

    var optional_cond = TaskCondition.new()
    optional_cond.required = false
    optional_cond.passed = false
    quest.add_condition(optional_cond)

    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Passed)

func test_task_passed_if_all_required_subs_passed():
    var t1 = Task.new()
    t1.activate()
    quest.add_subtask(t1)

    var t2 = Task.new()
    t2.activate()
    quest.add_subtask(t2)

    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Passed)

func test_task_passed_if_only_required_subs_passed():
    var t1 = Task.new()
    t1.activate()
    quest.add_subtask(t1)

    var t2 = Task.new()
    t2.activate()
    t2.add_condition(TaskCondition.new())
    t2.required = false
    quest.add_subtask(t2)

    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Passed)

func test_task_not_passed_if_any_required_sub_not_passed():
    var t1 = Task.new()
    quest.add_subtask(t1)

    var t2 = Task.new()
    var c = TaskCondition.new()
    t2.add_condition(c)
    quest.add_subtask(t2)

    quest.advance()
    assert_false(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Incomplete)

func test_task_passed_if_conditions_and_subs_passed():
    var t1 = Task.new()
    t1.activate()
    quest.add_subtask(t1)

    var c = TaskCondition.new()
    c.passed = true
    quest.add_condition(c)

    quest.advance()
    assert_true(t1.complete)
    assert_eq(t1.outcome, Task.outcomes().Passed)
    assert_true(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Passed)

func test_task_passed_if_deactivated_after_passing():
    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Passed)

    quest.deactivate()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Passed)

func test_task_not_passed_if_subs_pass_but_conditions_not_passed():
    var t1 = Task.new()
    t1.activate()
    quest.add_subtask(t1)

    var c = TaskCondition.new()
    quest.add_condition(c)

    quest.advance()
    assert_false(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Incomplete)

func test_task_not_passed_if_conditions_passed_but_subs_fail():
    var t1 = Task.new()
    t1.activate()
    t1.add_condition(TaskCondition.new())
    quest.add_subtask(t1)

    var c = TaskCondition.new()
    c.passed = true
    quest.add_condition(c)

    quest.advance()
    assert_false(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Incomplete)
