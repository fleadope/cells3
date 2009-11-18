module Cell::RequestForgeryProtection
  extend ActiveSupport::Concern

  include AbstractController::Helpers
  
  included do
    include InstanceMethods
    helper_method :protect_against_forgery?, :form_authenticity_token
  end

  module InstanceMethods
    attr_accessor :form_authenticity_token
    
    delegate :request_forgery_protection_token, :allow_forgery_protection, :to => "ActionController::Base"
    
    def initialize(controller, options = {})
      self.form_authenticity_token = options.delete(:form_authenticity_token) if options.respond_to?(:delete)
    end

    def protect_against_forgery?
      allow_forgery_protection && request_forgery_protection_token
    end

  end

end
