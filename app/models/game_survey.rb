class GameSurvey < Survey
  def self.model_name
    Survey.model_name
  end

  def url_game_survey
    configuration['url_game_survey']
  end

  def url_game_survey= x
    configuration['url_game_survey'] = x
  end

  def url_for_participant participant
    # Different survey urls depending on participant state
    s = participant.state
    if s['game'] == 'gather_data' then
      url_game_survey
    else
      url
    end
  end

  def game_result_pool
    # 10 results, half wins. Do not allow 3 losses in a row.
    available = [true, true, true, true, true, false, false, false, false, false]
    pool = nil
    def pool_is_fair pool
      return false unless pool
      loss_streak = 0
      last = true
      pool.each do |x| 
        if not x and x == last then
          loss_streak += 1
        end
        last = x
      end
      loss_streak < 2
    end
    while not (pool_is_fair pool)
      pool = available.sample(available.length)
    end
    pool
  end

  def prepare_games participant
    s = participant.state
    return if s['game_initialized']
    s['game_initialized'] = true
    s['game_count'] = 0
    s['game_time'] = {}
    s['game_measure_with_link'] = true
    s['game_result_pool'] = game_result_pool
    s['game_result'] = []
    s['game_balance'] = 0
    # Current schedule day id
    s['game_current_day'] = nil
    # Hash of schedule_day ids that contains if they won or lost
    s['game_completed'] = {}
  end

  def game_time_for participant, day
    # Does participant have a game start time for this day?
    # If not, decide when game prompt should start today
    time = participant.state['game_time'][day.id.to_s]
    if time.nil? then
      # pick a time in first 80% of time range 
      time = day.starts_at + (day.day_length * 0.8 * rand)
      participant.state['game_time'][day.id] = time
    end
    time
  end

  def game_timed_out! participant
    case participant.state['game']
    when 'waiting_asked', 'waiting_number' then
      # Just retrigger later today, they didn't respond
      participant.state['game'] = nil
      day_id = participant.state['game_current_day']
      participant.state['game_time'][day_id] = Time.now + 30.minutes
      schedule_participant! participant
    end
  end

  def game_could_start! participant
    # Ask the participant if they want to play
    participant.state['game'] = 'waiting_asked'
    # TODO: Add a delayed job which will call game_timed_out if no response
    return "Do you have time to play a game? (Reply 'yes' if so, or just ignore us if not)", Time.now
  end

  def game_begin! participant
    # Participant said yes, begin the game
    day_id = participant.state['game_current_day']
    participant.state['game_current_day'] = day_id
    participant.state['game'] = 'waiting_number'
    participant.state['game_count'] += 1
    # TODO: Add a delayed job which will call game_timed_out if no response
    message = "The computer chose the number 5, please guess whether the next number will be higher or lower than 5. Reply 'high' or 'low'."
    return message, Time.now
  end

  def game_send_result! day, participant
    # Participant picked high or low... tell them what they won, Jim!
    s = participant.state
    s['game_survey_count'] = 0

    # store if they won or not
    winner = participant.state['game_result_pool'].shift
    s['game_result'].push winner
    # also store this day as completed
    s['game_completed'][s['game_current_day']] = winner
    s['game_balance'] += winner ? 10 : -5

    # We go into gather data mode
    game_gather_data! day, participant

    # TODO: Better message?
    message = winner ? "Correct! You won $10!" : "Incorrect! You lose $5."
    return "#{message} Your balance is $#{s['game_balance']}", Time.now
  end

  def game_gather_data! day, participant
    s = participant.state
    s['game'] = 'gather_data'
    s['game_survey_count'] += 1
    if s['game_survey_count'] >= 8 then
      s['game'] = nil
    end
    # sample time should be 10-15 minutes from now
    time = Time.now + 10.minutes + rand(5).minutes

    # TODO: Add a delayed job to timeout and re-ask
    if s['game_measure_with_link'] then
      return "Please take this short survey now (sent at {{sent_time}}): {{redirect_link}}", time
    else
      return "How do you feel on a scale of 1 to 10?", time
    end
  end

  def schedule_participant! participant
    participant.requests_new_schedule = false
    day = participant.schedule_days.advance_to_day_with_time_for_message!
    unless day
      logger.info("Participant has no more available days")
      return false
    end
    
    prepare_games participant
    today_game_time = game_time_for(participant, day)
    state_game = participant.state['game'] 

    if state_game =~ /^waiting/ then
      # Don't start any new actions if waiting for response
      return false
    end

    message_text, scheduled_at = 
      if state_game.nil? and
        Time.now > today_game_time and
        not participant.state['game_completed'].include? day then
        # TODO: This should trigger on a postback from Qualtrics,
        # when we know they finished a default survey
        # ... otherwise, this gets called too often after a timeout
        game_could_start! participant
      else
        case state_game
        when 'send_result'
        when 'gather_data'
          game_gather_data! day, participant
        else
          # The default question
          [ "Please take this survey now (sent at {{sent_time}}): {{redirect_link}}",
            day.random_time_for_next_question ]
        end
      end

    participant.save!
    return do_message day, message_text, scheduled_at
  end

  def do_message day, message_text, scheduled_at
    message = day.scheduled_messages.build(message_text: message_text, scheduled_at: scheduled_at)
    message.save!
    return message
  end

  def participant_message participant, message
    day = participant.schedule_days.running_day
    s = participant.state
    game_state = s['game'] 
    if game_state =~ /^waiting_asked/ then
      # We asked if they wanted to start a game
      if message =~ /yes/i then
        do_message(day, *game_begin!(participant))
        participant.save!
      elsif message =~ /no/i then
        day_id = s['game_current_day']
        s['game_time'][day_id] = Time.now + 30.minutes
        participant.save!
      end
    elsif game_state =~ /^waiting_number/ then
      if message =~ /high|low/ then
        do_message(day, *game_send_result!(day, participant))
        participant.save!
      else
        do_message(day, "You need to pick 'high' or 'low'", Time.now)
      end
    elsif game_state =~ /^gather_data/ then
      if message =~ /\d+/ then
        s['game_response'][day_id] ||= []
        s['game_response'][day_id].push message
      end
    else
      logger.debug("Got unexpected participant message #{message} from participant #{participant.id} in game state #{game_state}")
    end
  end
end
