class CASino::CurrentUserListener < CASino::Listener
  def user_not_logged_in
    # NO-OP
  end

  def user_not_logged_in!
    @controller.redirect_to login_path
  end

  def current_user_found(user)
    assign(:current_user, user)
  end
end
