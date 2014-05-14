class CASino::TwoFactorAuthenticatorsController < CASino::ApplicationController
  include CASino::SessionsHelper

  def new
    processor(:TwoFactorAuthenticatorRegistrator).process(current_user, request.user_agent)
  end

  def create
    processor(:TwoFactorAuthenticatorActivator).process(params, current_user, request.user_agent)
  end

  def destroy
    processor(:TwoFactorAuthenticatorDestroyer).process(params, current_user, request.user_agent)
  end
end
