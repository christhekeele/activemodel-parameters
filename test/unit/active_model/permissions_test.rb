require 'test_helper'

module ActiveModel
  class Parameters < HashWithIndifferentAccess
    class PermissionsTest < Minitest::Test

      class TestParameters < Parameters; end

      def setup
        @parameters = TestParameters.new(foo: 1, bar: 2)
      end

      def teardown
        TestParameters.permitted_attributes = []
        TestParameters.required_attributes = []
        TestParameters.transforms = []
      end

      def test_extra_unpermitted_raises_on_to_hash
        @parameters.permit("foo")
        assert_raises Exceptions::UnpermittedParameters do
          @parameters.to_hash
        end
      end

      def test_all_permitted_doesnt_raise_on_to_hash
        @parameters.permit("foo").permit("bar")
        assert_equal @parameters.to_hash, {"foo" => 1, "bar" => 2}
      end

    end
  end
end
