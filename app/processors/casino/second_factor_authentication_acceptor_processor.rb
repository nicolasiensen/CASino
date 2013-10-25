# The SecondFactorAuthenticationAcceptor processor can be used to activate a previously generated ticket-granting ticket with pending two-factor authentication.
#
# This feature is not described in the CAS specification so it's completly optional
# to implement this on the web application side.
class CASino::SecondFactorAuthenticationAcceptorProcessor < CASino::Processor
  include CASino::ProcessorConcern::ServiceTickets
  include CASino::ProcessorConcern::CurrentUser
  include CASino::ProcessorConcern::TwoFactorAuthenticators

  # The method will call one of the following methods on the listener:
  # * `#user_not_logged_in`: The user should be redirected to /login.
  # * `#user_logged_in`: The first argument (String) is the URL (if any), the user should be redirected to.
  #   The second argument (String) is the ticket-granting ticket. It should be stored in a cookie named "tgt".
  # * `#invalid_one_time_password`: The user should be asked for a new OTP.
  #
  # @param [Hash] params parameters supplied by user. The processor will look for keys :otp and :service.
  # @param [Object] user A previously initializer User instance
  # @param [String] user_agent user-agent delivered by the client
  def process(params = nil, user = nil, user_agent = nil)
    @user = user || current_user
    @params = params || {}

    if tgt = @user.ticket({ user_agent:user_agent, ticket:@params[:tgt] })
      if validation_result.success?
        tgt.update_attributes!(awaiting_two_factor_authentication:false)
        begin
          handle_logged_in_user(tgt)
        rescue ServiceNotAllowedError
          @listener.service_not_allowed(clean_service_url @params[:service])
        end
      else
        @listener.invalid_one_time_password
      end
    else
      @listener.user_not_logged_in
    end
  end

  private
  def validation_result
    @validation_result ||= begin
      validate_one_time_password(@params[:otp], @user.active_two_factor_authenticator)
    end
  end

  def service_url(tgt)
    return if @params[:service].blank?

    acquire_service_ticket(tgt, @params[:service], true).service_with_ticket_url
  end

  def expiry_time(tgt)
    return unless tgt.long_term?

    CASino.config.ticket_granting_ticket[:lifetime_long_term].seconds.from_now
  end

  def handle_logged_in_user(tgt)
    @listener.user_logged_in(service_url(tgt), tgt.ticket, expiry_time(tgt))
  end

end
