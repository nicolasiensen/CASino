module CASino
  module ProcessorConcern
    module CurrentUser
      def user_signed_in?
        !!assigned_user
      end

      def current_user
        assigned_user || CASino::User.new
      end

      private
      def assigned_user
        @listener.assigned :current_user
      end
    end
  end
end
