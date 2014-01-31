require 'test_helper'

module ActiveModel
  class Parameters < HashWithIndifferentAccess
    class RequirementsTest < Minitest::Test

      class TestParameters < Parameters; end

      def setup
        @parameters = TestParameters.new(foo: 1, bar: 2).permit!
      end

      def teardown
        TestParameters.permitted_attributes = []
        TestParameters.required_attributes = []
        TestParameters.transforms = []
      end

      def test_missing_required_raises_on_to_hash
        @parameters.require("baz")
        assert_raises Exceptions::ParameterMissing do
          @parameters.to_hash
        end
      end

      def test_satisfied_required_doesnt_raise_on_to_hash
        @parameters.require("foo")
        assert_equal @parameters.to_hash, {"foo" => 1, "bar" => 2}
      end

    end
  end
end
