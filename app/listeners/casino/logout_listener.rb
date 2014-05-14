require_relative 'listener'

class CASino::LogoutListener < CASino::Listener
  def user_logged_out(url, redirect_immediately = false)
    assign(:current_user, nil)
    if redirect_immediately
      @controller.redirect_to url, status: :see_other
    else
      assign(:url, url)
    end
    cookies.delete :tgt
  end
end
