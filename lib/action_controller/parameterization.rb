require 'active_support/core_ext/class/attribute'
require 'active_support/inflector'

module ActionController
  module Parameterization
    extend ActiveSupport::Concern

    include ActionController::Renderers

    included do
      class_attribute :_parameterization_scope
      class_attribute :_parameters_class
      self._parameterization_scope = :current_user
    end

    module ClassMethods
      def parameterization_scope(scope)
        self._parameterization_scope = scope
      end
      def parameters_class(klass)
        self._parameters_class = klass
      end
    end

    def params
      @_params ||= parameters_class.new(request.parameters, parameterization_scope)
    end

    def parameterization_scope
      _parameterization_scope = self.class._parameterization_scope
      send(_parameterization_scope) if _parameterization_scope && respond_to?(_parameterization_scope, true)
    end

    def parameters_class
      self.class._parameters_class || self.class.name.demodulize.sub(/Controller$/, "Parameters").constantize
    end
  end
end
