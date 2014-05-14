# The Logout processor should be used to process GET requests to /logout.
class CASino::LogoutProcessor < CASino::Processor
  include CASino::ProcessorConcern::CurrentUser

  # This method will call `#user_logged_out` and may supply an URL that should be presented to the user.
  # As per specification, the URL specified by "url" SHOULD be on the logout page with descriptive text.
  # For example, "The application you just logged out of has provided a link it would like you to follow.
  # Please click here to access http://www.go-back.edu/."
  #
  # @param [Hash] params parameters supplied by user
  # @param [Object] user A previously initializer User instance
  # @param [String] user_agent user-agent delivered by the client
  def process(params = nil, user = nil, user_agent = nil)
    params ||= {}
    user ||= current_user
    user.ticket(user_agent:user_agent).try(:destroy)
    if params[:service] && CASino::ServiceRule.allowed?(params[:service])
      @listener.user_logged_out(params[:service], true)
    else
      @listener.user_logged_out(params[:url])
    end
  end
end
