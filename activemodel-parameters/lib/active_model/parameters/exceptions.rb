module ActiveModel
  class Parameters < HashWithIndifferentAccess
    module Exceptions

      class MissingParameters < KeyError
        attr_reader :param # :nodoc:

        def initialize(klass, params) # :nodoc:
          @klass = klass
          @param = params
          super("required parameters for #{klass} not found: #{params.join(", ")}")
        end
      end

      # Raised when a supplied parameter is not expected.
      #
      #   params = ActiveModel::Parameters.new(a: "123", b: "456")
      #   params.permit(:c)
      #   # => ActiveModel::UnpermittedParameters: found unexpected keys: a, b
      class UnpermittedParameters < IndexError
        attr_reader :params # :nodoc:

        def initialize(klass, params) # :nodoc:
          @klass = klass
          @params = params
          super("found unpermitted parameters for #{klass}: #{params.join(", ")}")
        end
      end

    end
  end
end
