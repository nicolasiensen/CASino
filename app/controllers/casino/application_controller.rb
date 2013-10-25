require 'casino'
require 'http_accept_language'

class CASino::ApplicationController < ::ApplicationController
  include CASino::ApplicationHelper

  layout 'application'
  before_filter :set_locale

  protected
  def set_locale
    I18n.locale = extract_locale_from_accept_language_header || I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    if request.env['HTTP_ACCEPT_LANGUAGE']
      http_accept_language.preferred_language_from(I18n.available_locales)
    end
  end

  def http_accept_language
    HttpAcceptLanguage::Parser.new request.env['HTTP_ACCEPT_LANGUAGE']
  end
end
