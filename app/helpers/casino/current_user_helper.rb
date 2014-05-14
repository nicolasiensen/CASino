module CASino::CurrentUserHelper
  include CASino::ProcessorHelper

  def self.included(base)
    return unless base.ancestors.include? ActionController::Base

    base.helper_method :current_user, :user_signed_in?
    base.before_filter :set_current_user
  end

  def set_current_user
    params[:tgt] ||= cookies[:tgt]
    processor(:CurrentUser).process(params, request.user_agent)
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    !!current_user
  end
end
