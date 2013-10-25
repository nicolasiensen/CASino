class CASino::CurrentUserProcessor < CASino::Processor
  include CASino::ProcessorConcern::LoginTickets
  include CASino::ProcessorConcern::TicketGrantingTickets

  # This method will call `#user_not_logged_in` or `#current_user_found(User)` on the listener.
  # @param [Hash] params A Hash delivered by the client used to located the User's Ticket Granting Ticket
  # @param [String] user_agent user-agent delivered by the client
  def process(params = nil, user_agent = nil, options = {})
    options ||= {}
    if user = handle_process(params, user_agent, options)
      @listener.current_user_found(user)
    else
      @listener.user_not_logged_in
    end
  end

  # This method will call `#user_not_logged_in!` or `#current_user_found(User)` on the listener.
  # @param [Hash] params A Hash delivered by the client used to located the User's Ticket Granting Ticket
  # @param [String] user_agent user-agent delivered by the client
  def process!(params = nil, user_agent = nil, options = {})
    options ||= {}
    if handle_process(params, user_agent, options)
      @listener.current_user_found
    else
      @listener.user_not_logged_in!
    end
  end

  private
  def handle_process(params, user_agent, options)
    return current_user if user_signed_in?

    @params, @user_agent = (params || {}), user_agent

    ticket_granting_ticket(options).try(:user)
  end

  def current_user
    @listener.assigned :current_user
  end

  def user_signed_in?
    current_user
  end

  def ticket_granting_ticket(options)
    @ticket_granting_ticket ||= begin
      find_valid_ticket_granting_ticket(@params[:tgt], @user_agent, options[:ignore_two_factor])
    end
  end

end