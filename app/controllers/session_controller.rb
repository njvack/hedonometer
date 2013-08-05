# -*- encoding : utf-8 -*-

class SessionController < SurveyedController
  skip_before_action :require_participant_login!

  def new
    @participant = Participant.new(login_form_params)
  end

  def destroy
    reset_session
    redirect_to survey_login_path current_survey
  end

  def create
    if params[:send_code]
      send_login_code and return
    end
    @participant = current_survey.participants.authenticate(
      login_params[:phone_number],
      login_params[:login_code]) || Participant.new(login_params)
    unless @participant.new_record?
      session[:participant_id] = @participant.id
      redirect_to survey_path(current_survey) and return
    end
    # login failed, fall through
    render action: 'new'
  end

  def send_login_code
    number = PhoneNumber.new(params[:participant][:phone_number])
    participant = current_survey.participants.where(phone_number: number.to_e164).first
    status = participant ? :ok : :not_found
    if participant
      message = ParticipantTexter.login_code_message(participant)
      message.deliver_and_save!
    end
    redirect_to survey_login_path current_survey, {participant: {phone_number: number.to_s}}
  end


  protected
  def login_params
    params.require(:participant).
      permit(:phone_number, :login_code)
  end
  def login_form_params
    params.fetch(:participant, {}).permit(:phone_number)
  end
end
