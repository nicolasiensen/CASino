# The TwoFactorAuthenticatorDestroyer processor can be used to deactivate a previously activated two-factor authenticator.
#
# This feature is not described in the CAS specification so it's completly optional
# to implement this on the web application side.
class CASino::TwoFactorAuthenticatorDestroyerProcessor < CASino::Processor
  include CASino::ProcessorConcern::CurrentUser
  include CASino::ProcessorConcern::TwoFactorAuthenticators

  # The method will call one of the following methods on the listener:
  # * `#user_not_logged_in`: The user is not logged in and should be redirected to /login.
  # * `#two_factor_authenticator_destroyed`: The two-factor authenticator was successfully destroyed.
  # * `#invalid_two_factor_authenticator`: The two-factor authenticator is not valid.
  #
  # @param [Hash] params parameters supplied by user. The processor will look for key :id.
  # @param [Object] user A previously initializer User instance
  # @param [String] user_agent user-agent delivered by the client
  def process(params = nil, user = nil, user_agent = nil)
    @params = params || {}
    @user = user || current_user

    if @user.ticket(user_agent:user_agent)
      if authenticator
        authenticator.destroy
        @listener.two_factor_authenticator_destroyed
      else
        @listener.invalid_two_factor_authenticator
      end
    else
      @listener.user_not_logged_in
    end
  end

  private
  def authenticator
    authenticator ||= @user.two_factor_authenticators.where(id: @params[:id]).first
  end
end
