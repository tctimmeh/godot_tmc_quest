extends GutTest

var quest: Quest

func before_each():
    quest = Quest.new()
    quest.activate()

func test_quest_with_no_subs_and_no_conditions_auto_passes():
    assert_false(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Incomplete)

    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Passed)

func test_quest_deactivates_when_passed():
    assert_true(quest.active)
    quest.advance()
    assert_eq(quest.outcome, Quest.outcomes().Passed)
    assert_false(quest.active)

func test_quest_stops_tracking_when_passed():
    quest.tracking = true
    quest.advance()
    assert_false(quest.tracking)

func test_quest_not_passed_if_any_required_condition_not_passed():
    var c = QuestCondition.new()
    quest.add_condition(c)

    quest.advance()
    assert_false(c.passed)
    assert_false(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Incomplete)

func test_quest_passed_if_only_required_conditions_passed():
    var req_cond = QuestCondition.new()
    req_cond.passed = true
    quest.add_condition(req_cond)

    var optional_cond = QuestCondition.new()
    optional_cond.required = false
    optional_cond.passed = false
    quest.add_condition(optional_cond)

    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Passed)

func test_quest_passed_if_all_required_subs_passed():
    var t1 = Quest.new()
    t1.activate()
    quest.add_subquest(t1)

    var t2 = Quest.new()
    t2.activate()
    quest.add_subquest(t2)

    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Passed)

func test_quest_passed_if_only_required_subs_passed():
    var t1 = Quest.new()
    t1.activate()
    quest.add_subquest(t1)

    var t2 = Quest.new()
    t2.activate()
    t2.add_condition(QuestCondition.new())
    t2.required = false
    quest.add_subquest(t2)

    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Passed)

func test_quest_not_passed_if_any_required_sub_not_passed():
    var t1 = Quest.new()
    quest.add_subquest(t1)

    var t2 = Quest.new()
    var c = QuestCondition.new()
    t2.add_condition(c)
    quest.add_subquest(t2)

    quest.advance()
    assert_false(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Incomplete)

func test_quest_passed_if_conditions_and_subs_passed():
    var t1 = Quest.new()
    t1.activate()
    quest.add_subquest(t1)

    var c = QuestCondition.new()
    c.passed = true
    quest.add_condition(c)

    quest.advance()
    assert_true(t1.complete)
    assert_eq(t1.outcome, Quest.outcomes().Passed)
    assert_true(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Passed)

func test_quest_passed_if_deactivated_after_passing():
    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Passed)

    quest.deactivate()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Passed)

func test_quest_not_passed_if_subs_pass_but_conditions_not_passed():
    var t1 = Quest.new()
    t1.activate()
    quest.add_subquest(t1)

    var c = QuestCondition.new()
    quest.add_condition(c)

    quest.advance()
    assert_false(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Incomplete)

func test_quest_not_passed_if_conditions_passed_but_subs_fail():
    var t1 = Quest.new()
    t1.activate()
    t1.add_condition(QuestCondition.new())
    quest.add_subquest(t1)

    var c = QuestCondition.new()
    c.passed = true
    quest.add_condition(c)

    quest.advance()
    assert_false(quest.complete)
    assert_eq(quest.outcome, Quest.outcomes().Incomplete)
