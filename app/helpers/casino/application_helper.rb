module CASino
  module ApplicationHelper
    extend ActiveSupport::Concern

    included do
      include CASino::CurrentUserHelper
    end
  end
end
