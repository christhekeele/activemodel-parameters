require 'active_support/core_ext/class/attribute'
require 'active_support/inflector'

module ActionController
  module Parameterization
    extend ActiveSupport::Concern

    # include ActionController::Renderers

    class << self
      def included(base)
        base.class_attribute :_parameterization_scope
        base.class_attribute :_parameters_class
        base._parameterization_scope = :current_user
        super
      end
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
      params = parameters_class.new(request.parameters, parameterization_scope)
      @_params ||= params.wrap_attributes? ? params.wrap! : params
    end

    def parameterization_scope
      _parameterization_scope = self.class._parameterization_scope
      send(_parameterization_scope) if _parameterization_scope && respond_to?(_parameterization_scope, true)
    end

    def parameters_class
      self.class._parameters_class || ActiveModel::Parameters.class_for(self.class.name.demodulize.sub(/Controller$/, '').underscore)
    end
  end
end
