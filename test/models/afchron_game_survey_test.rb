require 'test_helper'

class AfchronGameSurveyTest < ActiveSupport::TestCase
  def setup
    @survey = surveys(:game)
    @ppt = participants(:ppt3)
  end

  test "schedule works" do
    q = @survey.schedule_participant! @ppt
    assert_match(/Please take this survey now|Do you have time to play a game/, q.message_text)
  end

  test "schedule initializes game state" do
    @survey.schedule_participant! @ppt
    assert_kind_of(AfchronGameState, @ppt.participant_state)
    assert_equal(0, @ppt.state['game_balance'])
  end

  test "prepare game state returns an AfchronGameState" do
    state = @survey.prepare_game_state @ppt
    assert_kind_of(AfchronGameState, state)
  end

  test "prepared game state does not have a game_time" do
    state = @survey.prepare_game_state @ppt
    assert_nil(state['game_time'])
  end


  test "participant state persists balance" do
    @survey.schedule_participant! @ppt
    @ppt.state["game_balance"] = 10
    assert_equal(10, @ppt.state["game_balance"])
    @ppt.save!
    assert_equal(10, @ppt.state["game_balance"])

    db_state = ParticipantState.find(@ppt.participant_state.id)
    assert_kind_of(AfchronGameState, db_state)
    assert_equal(10, db_state.state["game_balance"])

    db_ppt = Participant.find(@ppt.id)
    assert_equal(10, db_ppt.state["game_balance"])
  end

  test "participant state can retrieve time correctly" do
    @survey.schedule_participant! @ppt
    @ppt.state["game_time"] = Time.now + 30.minutes
    @ppt.save!

    db_state = ParticipantState.find(@ppt.participant_state.id)
    assert_kind_of(AfchronGameState, db_state)
    assert(db_state.get_game_time > Time.now)
  end

  test "participant state aasm persists" do
    @survey.prepare_game_state @ppt
    @ppt.participant_state.ask_to_play!
    @ppt.save!
    db_ppt = Participant.find(@ppt.id)
    assert_equal("waiting_asked", db_ppt.aasm_state)
  end

  test "first message of the day is within plus/minus * 2" do
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now + 2.hours
    @ppt.save!
    assert_equal("none", @ppt.aasm_state)
    q = @survey.schedule_participant! @ppt

    duration = q.scheduled_at - Time.now
    assert_operator duration, :<=, (@survey.sample_minutes_plusminus * 2).minutes
  end

  test "when it is not yet time TO GAME, just sends survey" do
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now + 1.hours
    @ppt.save!
    assert_equal("none", @ppt.aasm_state)
    q = @survey.schedule_participant! @ppt

    assert_equal("none", @ppt.aasm_state)
    assert_match(/Please take this survey now/, q.message_text)
  end

  test "participant link in state is preserved" do
    @survey.prepare_game_state @ppt
    assert_equal(@ppt.participant_state.participant, @ppt)
    @ppt.state["hooray"] = "YES"
    @ppt.save!
    assert_equal("YES", @ppt.state["hooray"])
    assert_equal(@ppt, @ppt.participant_state.participant)
  end

  test "when game time is ready prompts participant to play" do
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now - 1.hours
    @ppt.save!
    assert_equal("none", @ppt.aasm_state)
    scheduled = @survey.schedule_participant! @ppt
    assert_not_equal(false, scheduled)

    assert_equal("waiting_asked", @ppt.aasm_state)
    assert_equal(@ppt.participant_state.participant, @ppt)
    assert_match(/Do you have time to play/, scheduled.message_text)
  end

  test "participant responds in time to play" do
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now - 1.hours
    @ppt.save!
    scheduled = @survey.schedule_participant! @ppt
    assert_not_equal(false, scheduled)
    assert_equal("waiting_asked", @ppt.aasm_state)
    @ppt.participant_state.incoming_message "yes"
    assert_equal("waiting_number", @ppt.aasm_state)
  end

  test "participant does not want to play" do
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now - 1.hours
    @ppt.save!
    scheduled = @survey.schedule_participant! @ppt
    assert_not_equal(false, scheduled)
    assert_equal("waiting_asked", @ppt.aasm_state)
    @ppt.participant_state.incoming_message "NO"
    assert_equal("none", @ppt.aasm_state)
    assert(@ppt.state["game_time"] > Time.now)
  end

  test "participant times out play request" do
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now - 1.hours
    @ppt.save!
    scheduled = @survey.schedule_participant! @ppt
    assert_not_equal(false, scheduled)
    assert_equal("waiting_asked", @ppt.aasm_state)
    @ppt.participant_state.do_timeout!
    assert_equal("none", @ppt.aasm_state)
    assert(@ppt.state["game_time"] > Time.now)
  end

  test "participant plays game and wins" do
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now - 1.hours
    @ppt.state["result_pool"] = [true]
    @ppt.save!
    @survey.schedule_participant! @ppt
    assert_equal("waiting_asked", @ppt.aasm_state)
    @ppt.participant_state.incoming_message "yes"
    assert_equal("waiting_number", @ppt.aasm_state)
    q = @ppt.participant_state.incoming_message "high"
    assert_match(/You guessed right!/, q.message_text)
    assert_equal(10, @ppt.state["game_balance"])
    assert(@ppt.participant_state.game_surveying?)
  end

  test "participant plays game and loses" do
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now - 1.hours
    @ppt.state["result_pool"] = [false]
    @ppt.save!
    @survey.schedule_participant! @ppt
    assert_equal("waiting_asked", @ppt.aasm_state)
    @ppt.participant_state.incoming_message "yes"
    assert_equal("waiting_number", @ppt.aasm_state)
    q = @ppt.participant_state.incoming_message "high"
    assert_match(/You guessed wrong!/, q.message_text)
    assert_equal(-5, @ppt.state["game_balance"])
  end

  test "survey url changes to short during game survey" do
    twilio_mock(TwilioResponses.create_sms)
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now - 1.hours
    @ppt.state["result_pool"] = [true]
    @ppt.save!

    q = @survey.schedule_participant! @ppt
    ParticipantTexter.deliver_scheduled_message!(q.id)
    r = ScheduledMessage.find(q.id)
    assert_match(/long/, r.destination_url)

    @ppt.participant_state.incoming_message "yes"
    q = @ppt.participant_state.incoming_message "high"
    ParticipantTexter.deliver_scheduled_message!(q.id)
    r = ScheduledMessage.find(q.id)
    assert_match(/short/, r.destination_url)
  end

  test "creates one delayed job when scheduling questions" do
    assert_equal(0, Delayed::Job.count)
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now + 3.hours
    @ppt.save!
    @survey.schedule_participant! @ppt
    assert_equal(1, Delayed::Job.count)
  end

  test "creates two delayed jobs when heading into game (one for timeout)" do
    assert_equal(0, Delayed::Job.count)
    @survey.prepare_game_state @ppt
    @ppt.state["game_time"] = Time.now - 1.hours
    @ppt.state["result_pool"] = [true]
    @ppt.save!
    @survey.schedule_participant! @ppt
    assert_equal(2, Delayed::Job.count)
  end
end

