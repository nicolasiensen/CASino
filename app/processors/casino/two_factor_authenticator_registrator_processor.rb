require 'rotp'

# The TwoFactorAuthenticatorRegistrator processor can be used as the first step to register a new two-factor authenticator.
# It is inactive until activated using TwoFactorAuthenticatorActivator.
#
# This feature is not described in the CAS specification so it's completly optional
# to implement this on the web application side.
class CASino::TwoFactorAuthenticatorRegistratorProcessor < CASino::Processor
  include CASino::ProcessorConcern::CurrentUser

  # This method will call `#user_not_logged_in` or `#two_factor_authenticator_registered(two_factor_authenticator)` on the listener.
  # @param [Object] user A previously initializer User instance
  # @param [String] user_agent user-agent delivered by the client
  def process(user = nil, user_agent = nil)
    @user = user || current_user

    if @user.ticket(user_agent:user_agent)
      @listener.two_factor_authenticator_registered(two_factor_authenticator)
    else
      @listener.user_not_logged_in
    end
  end

  private
  def two_factor_authenticator
    @two_factor_authenticator ||= @user.two_factor_authenticators.create! secret: ROTP::Base32.random_base32
  end

end
