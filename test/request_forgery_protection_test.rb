# encoding: utf-8
require File.join(File.dirname(__FILE__), 'test_helper')

class RequestForgeryProtectionTest < ActionController::TestCase
  include Cells::AssertionsHelper

  context "Controller with protection against request forgery enabled" do

    setup do
      @cell = cell(:test)
      @cell.controller.session = {}
      @cell.controller.class.protect_from_forgery
    end

    should "cell protect against forgery as well" do 
      assert @cell.protect_against_forgery?
    end

    should "provide authenticity param" do
      assert_equal @cell.controller.send(:form_authenticity_token), @cell.render_state(:authenticity_token).strip
    end

  end
end
