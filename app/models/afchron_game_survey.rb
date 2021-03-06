class AfchronGameSurvey < Survey
  def self.model_name
    Survey.model_name
  end

  def url
    configuration['url']
  end

  def url= x
    configuration['url'] = x
  end

  def url_game_survey
    configuration['url_game_survey']
  end

  def url_game_survey= x
    configuration['url_game_survey'] = x
  end

  def create_participant_state participant
    # Override the base SimpleParticipantState with a game state
    prepare_game_state participant
  end

  def prepare_game_state participant
    unless participant.participant_state.kind_of? AfchronGameState
      if participant.participant_state and participant.participant_state.id > 0 then
        participant.participant_state.destroy
      end
      s = AfchronGameState.new(:participant => participant)
      participant.participant_state = s
      participant.participant_state.set_defaults!
      s.save!
    end
    participant.participant_state
  end

  def schedule_participant! participant
    participant.requests_new_schedule = false
    state = prepare_game_state participant
    state.take_action!
  end

end
