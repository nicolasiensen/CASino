# The SessionOverview processor to list all open session for the currently signed in user.
#
# This feature is not described in the CAS specification so it's completly optional
# to implement this on the web application side.
class CASino::SessionOverviewProcessor < CASino::Processor
  include CASino::ProcessorConcern::CurrentUser

  # This method will call `#user_not_logged_in` or `#ticket_granting_tickets_found(Enumerable)` on the listener.
  # @param [Object] user A previously initializer User instance
  # @param [String] user_agent user-agent delivered by the client
  def process(user = nil, user_agent = nil)
    @user ||= current_user

    if @user.ticket(user_agent:user_agent)
      @listener.ticket_granting_tickets_found(ticket_granting_tickets)
    else
      @listener.user_not_logged_in
    end
  end

  private
  def ticket_granting_tickets
    @user.ticket_granting_tickets.where(awaiting_two_factor_authentication: false).order('updated_at DESC')
  end

end
