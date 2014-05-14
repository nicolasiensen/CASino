# The SessionDestroyer processor is used to destroy a ticket-granting ticket.
#
# This feature is not described in the CAS specification so it's completly optional
# to implement this on the web application side. It is especially useful in
# combination with the {CASino::SessionOverviewProcessor} processor.
class CASino::SessionDestroyerProcessor < CASino::Processor
  include CASino::ProcessorConcern::CurrentUser

  # This method will call `#ticket_not_found` or `#ticket_deleted` on the listener.
  # @param [Hash] params parameters supplied by user (ID of ticket-granting ticket to delete should by in params[:id])
  # @param [Object] user A previously initializer User instance
  # @param [String] user_agent user-agent delivered by the client
  def process(params = nil, user = nil, user_agent = nil)
    params ||= {}
    user ||= current_user
    ticket = CASino::TicketGrantingTicket.where(id: params[:id]).first
    owner_ticket = user.ticket(user_agent:user_agent)
    if ticket && ticket.same_user?(owner_ticket)
      Rails.logger.info "Destroying ticket-granting ticket '#{ticket.ticket}'"
      ticket.destroy
      @listener.ticket_deleted
    else
      @listener.ticket_not_found
    end
  end
end
