class SimpleSurvey < Survey
  def self.model_name
    Survey.model_name
  end

  has_many :survey_questions, foreign_key: 'survey_id'
  accepts_nested_attributes_for :survey_questions,
    allow_destroy: true,
    reject_if: ->(attributes) { attributes[:question_text].blank? }


  def question_chooser
    RandomNoReplacementRecordChooser
  end

  def schedule_participant! participant
    create_participant_state participant
    participant.requests_new_schedule = false
    question = current_question_or_new participant
    return nil unless question
    # We know question is not delivered; we can set its scheduled_at
    question.scheduled_at = question.schedule_day.random_time_for_next_question
    question.save!
    participant.save!
    logger.debug("Scheduled #{question.inspect}")
    ParticipantTexter.delay(run_at: question.scheduled_at).deliver_scheduled_message!(question.id)
    return question
  end

  def current_question_or_new participant
    # Returns a question or new -- unsaved.
    day = self.advance_to_day_with_time_for_message! participant
    logger.debug("Day is #{day}")
    return nil unless day
    question = day.current_question
    if question.nil?
      survey_question = choose_question participant
      question = day.scheduled_messages.build(survey_question: survey_question)
    end
    question
  end

  def choose_question participant
    chooser = question_chooser.from_serializer(survey_questions, participant.state["question_chooser_state"])
    chooser.choose.tap {
      participant.state["question_chooser_state"] = chooser.serialize_state
      logger.debug("New question chooser state: #{participant.state['question_chooser_state']}")
    }
  end

end

