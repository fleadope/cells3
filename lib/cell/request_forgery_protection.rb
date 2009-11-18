module Cell
  module RequestForgeryProtection
    extend ActiveSupport::Concern

    include AbstractController::Helpers

    included do
      helper_method :protect_against_forgery?, :form_authenticity_token
      delegate :request_forgery_protection_token, :allow_forgery_protection, 
        :form_authenticity_token, :protect_against_forgery?, :to => :parent_controller
    end
  end
end
