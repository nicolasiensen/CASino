# The TwoFactorAuthenticatorOverview processor lists registered two factor devices for the currently signed in user.
#
# This feature is not described in the CAS specification so it's completly optional
# to implement this on the web application side.
class CASino::TwoFactorAuthenticatorOverviewProcessor < CASino::Processor
  include CASino::ProcessorConcern::CurrentUser

  # This method will call `#user_not_logged_in` or `#two_factor_authenticators_found(Enumerable)` on the listener.
  # @param [Object] user A previously initializer User instance
  # @param [String] user_agent user-agent delivered by the client
  def process(user = nil, user_agent = nil)
    @user = user || current_user

    if @user.ticket(user_agent:user_agent)
      @listener.two_factor_authenticators_found(authenticators)
    else
      @listener.user_not_logged_in
    end
  end

  private
  def authenticators
    @user.two_factor_authenticators.where(active: true)
  end

end
