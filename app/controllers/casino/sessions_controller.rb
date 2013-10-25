class CASino::SessionsController < CASino::ApplicationController
  include CASino::SessionsHelper

  skip_before_filter :set_current_user, only:[:create, :validate_otp]

  def index
    processor(:TwoFactorAuthenticatorOverview).process(current_user, request.user_agent)
    processor(:SessionOverview).process(current_user, request.user_agent)
  end

  def new
    processor(:LoginCredentialRequestor).process(params, current_user, request.user_agent)
  end

  def create
    processor(:LoginCredentialAcceptor).process(params, request.user_agent)
  end

  def destroy
    processor(:SessionDestroyer).process(params, current_user, request.user_agent)
  end

  def destroy_others
    processor(:OtherSessionsDestroyer).process(params, current_user, request.user_agent)
  end

  def logout
    processor(:Logout).process(params, current_user, request.user_agent)
  end

  def validate_otp
    processor(:CurrentUser).process(params, request.user_agent, ignore_two_factor:true)
    processor(:SecondFactorAuthenticationAcceptor).process(params, current_user, request.user_agent)
  end
end
