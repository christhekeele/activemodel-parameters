require 'test_helper'

module ActiveModel
  class Parameters < HashWithIndifferentAccess
    module DSL
      class Test < Minitest::Test

        def setup
          @parameters = Class.new.extend(DSL)
        end

        def test_intial_permitted_attributes
          assert @parameters.permitted_attributes.kind_of? Array
        end

        def test_intial_required_attributes
          assert @parameters.required_attributes.kind_of? Array
        end

        def test_attribute_directive
          @parameters.attribute "foo"
          assert_equal @parameters.permitted_attributes.length, 1
        end

        def test_attributes_directive
          @parameters.attributes "foo", "bar"
          assert_equal @parameters.permitted_attributes.length, 2
        end

        def test_attributes_are_preserved_on_subclassing
          @parameters.attribute "foo"
          subclass = Class.new(@parameters)
          assert_equal subclass.permitted_attributes.length, 1
        end

        def test_attributes_arent_overriden_by_subclasses
          subclass = Class.new(@parameters)
          subclass.attribute "foo"
          refute_equal @parameters.permitted_attributes.length, 1
        end

        def test_intial_transforms
          assert @parameters.transforms.kind_of? Array
        end

        def test_transform_directive
          hash = { "baz" => "buzz" }
          @parameters.transform -> hash { hash }
          assert_equal @parameters.transforms.length, 1
          assert_same @parameters.transforms.first.call(hash), hash
        end

        def test_transforms_are_preserved_on_subclassing
          @parameters.transform -> hash { hash }
          subclass = Class.new(@parameters)
          assert_equal subclass.transforms.length, 1
        end

        def test_transforms_arent_overriden_by_subclasses
          subclass = Class.new(@parameters)
          subclass.transform -> hash { hash }
          refute_equal @parameters.transforms.length, 1
        end

      end
    end
  end
end
