# The OtherSessionsDestroyer processor should be used to process GET requests to /destroy-other-sessions.
#
# It is usefule to redirect users to this action after a password change.
#
# This feature is not described in the CAS specification so it's completly optional
# to implement this on the web application side.
class CASino::OtherSessionsDestroyerProcessor < CASino::Processor
  include CASino::ProcessorConcern::CurrentUser

  # This method will call `#other_sessions_destroyed` and may supply an URL that should be presented to the user.
  # The user should be redirected to this URL immediately.
  #
  # @param [Hash] params parameters supplied by user
  # @param [Object] user A previously initializer User instance
  # @param [String] user_agent user-agent delivered by the client
  def process(params = nil, user = nil, user_agent = nil)
    params ||= {}
    user ||= current_user

    user.other_tickets(user_agent).destroy_all

    @listener.other_sessions_destroyed(params[:service])
  end
end
