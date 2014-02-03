module ActiveModel
  class Parameters < HashWithIndifferentAccess
    module Exceptions

      class MissingParameters < KeyError
        attr_reader :param # :nodoc:

        def initialize(params) # :nodoc:
          @param = params
          super("required parameters not found: #{params.join(", ")}")
        end
      end

      # Raised when a supplied parameter is not expected.
      #
      #   params = ActiveModel::Parameters.new(a: "123", b: "456")
      #   params.permit(:c)
      #   # => ActiveModel::UnpermittedParameters: found unexpected keys: a, b
      class UnpermittedParameters < IndexError
        attr_reader :params # :nodoc:

        def initialize(params) # :nodoc:
          @params = params
          super("found unpermitted parameters: #{params.join(", ")}")
        end
      end

    end
  end
end
