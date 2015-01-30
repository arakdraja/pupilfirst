class MentorMeetingsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :meeting_started, only: [:feedback]
  before_filter :meeting_completed, only: [:feedbacksave]
  
  def live
    @mentor_meeting = MentorMeeting.find(params[:id])
  end

  def new
    if current_user.startup.agreement_live?
  	 mentor = Mentor.find params[:mentor_id]
  	 @mentor_meeting = mentor.mentor_meetings.new
    else 
      flash[:alert]="Please sign/renew your agreement with SV to meet our mentors!"
      redirect_to mentoring_url
    end
  end

  def create
    raise_not_found unless current_user.startup.present?
  	mentor = Mentor.find params[:mentor_id]
  	@mentor_meeting = mentor.mentor_meetings.new(meeting_params)
  	@mentor_meeting.user = current_user
  	if @mentor_meeting.save
  		UserMailer.meeting_request_to_mentor(@mentor_meeting).deliver
      flash[:notice]="Meeting request sent"
  		redirect_to mentoring_path(current_user)
  	else
  		flash[:alert]="Failed to create new meeting request"
  		render 'new'
  	end
  end

  def index
  	@mentor_meetings = MentorMeeting.all
  end

  # TODO: Refactor this method. It does two database update calls for the same entry.
  def update
    @mentor_meeting = MentorMeeting.find(params[:id])
    if params[:commit] == 'started'
      @mentor_meeting.status_to_started
      head :ok
    else
      if @mentor_meeting.update(mentorupdate_params)
        params[:commit] == 'Accept' ? @mentor_meeting.status_to_accepted : @mentor_meeting.status_to_rejected
        flash[:notice] = 'Meeting status has been updated'
        email_mentor_response(@mentor_meeting)
      else
        flash[:alert] = 'Could not update meeting'
      end

      redirect_to mentoring_url
    end 
  end

  def feedback
    @mentor_meeting = MentorMeeting.find(params[:id])
    @role = role(@mentor_meeting)
    flash.now[:notice] = "Your meeting with #{guest(@mentor_meeting).fullname} has ended"
    @mentor_meeting.status_to_completed
  end

  def feedbacksave
    @mentor_meeting = MentorMeeting.find(params[:id])

    if @mentor_meeting.update(feedback_params)
      flash[:notice] = 'Thank you for your feedback!'
      redirect_to mentoring_path
    else
      flash[:error] = 'Could not save your feedback. Please try again.'
      render 'feedback'
    end
  end

  def reminder
    @mentor_meeting = MentorMeeting.find(params[:id])
    phone_number = current_user == @mentor_meeting.user ? current_user.phone : @mentor_meeting.mentor.user.phone
    RestClient.post(APP_CONFIG[:sms_provider_url], text: "#{guest(@mentor_meeting).fullname} is ready and waiting for todays mentoring session", msisdn: phone_number)
    head :ok
  end

  private
  	def meeting_params
  		params.require(:mentor_meeting).permit(:purpose,:suggested_meeting_at,:suggested_meeting_time,:duration)
  	end

    def feedback_params
      params.require(:mentor_meeting).permit(:user_rating,:mentor_rating,:user_comments,:mentor_comments)
    end

    def mentorupdate_params
      params.require(:mentor_meeting).permit(:mentor_comments,:meeting_at)
    end

    def meeting_started
      raise_not_found if !(MentorMeeting.find(params[:id]).status == MentorMeeting::STATUS_STARTED || MentorMeeting.find(params[:id]).status == MentorMeeting::STATUS_COMPLETED)
    end

    def meeting_completed
      raise_not_found if MentorMeeting.find(params[:id]).status != MentorMeeting::STATUS_COMPLETED
    end

    def role(mentormeeting)
      current_user == mentormeeting.user ? "user" : "mentor"
    end

    def guest(mentormeeting)
      current_user == mentormeeting.user ? mentormeeting.mentor.user : mentormeeting.user 
    end

    def guest_rating?(mentormeeting)
      guest(mentormeeting) == mentormeeting.user ? mentormeeting.user_rating? : mentormeeting.mentor_rating?
    end

    def email_mentor_response(mentormeeting)
      if mentormeeting.rejected?
        UserMailer.meeting_request_rejected(mentormeeting).deliver
      elsif mentormeeting.accepted?
        mentormeeting.rescheduled? ? UserMailer.meeting_request_rescheduled(mentormeeting).deliver : UserMailer.meeting_request_accepted(mentormeeting).deliver
      end
    end
end
