require 'test_helper'

module ActiveModel
  class Parameters < HashWithIndifferentAccess
    class Test < Minitest::Test

      class TestParameters < Parameters; self.filter_unpermitted = true; end

      def setup
        @parameters = TestParameters.new
      end

      def teardown
        TestParameters.permitted_attributes = []
        TestParameters.required_attributes = []
        TestParameters.transforms = []
      end

      def test_permit_adds_new_permitted_attribute
        @parameters.permit("foo")
        assert_equal @parameters.permitted_attributes.length, 1
      end

      def test_require_adds_new_required_attribute
        @parameters.require("foo")
        assert_equal @parameters.required_attributes.length, 1
      end

    end
  end
end
