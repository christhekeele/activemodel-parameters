require 'active_support/core_ext/hash_extensions'
require 'active_model/parameters/dsl'
require 'active_model/parameters/utils'
require 'active_model/parameters/default'
require 'active_model/parameters/exceptions'

module ActiveModel
  class Parameters < HashWithIndifferentAccess

    ALWAYS_PERMITTED_ATTRIBUTES = %w[controller action format authenticity_token utf8 _method]

    class_attribute :root
    class_attribute :filter_unpermitted

    extend Utils::SubclassTracker
    extend DSL

    attr_reader :scope, :permitted, :associated, :listed, :nested
    alias_method :permitted?,  :permitted
    alias_method :associated?, :associated
    alias_method :listed?,     :listed
    alias_method :nested?,     :nested

    def initialize(hash={}, scope=nil, opts={})
      @scope      = scope
      @associated = opts.fetch(:associated, false)
      @listed     = opts.fetch(:listed, false)
      @nested     = @associated or @listed
      @permitted  = false
      hash = Hash[
        hash.map do |key, value|
          transform key, value
        end
      ]
      super(
        Hash[
          hash.map do |key, value|
            transform key, value
          end
        ]
      ).each_pair do |key, value|
        hydrate_association(key, value)
      end
      self
    end

    def wrap!
      wrapper = if keys.include? get_root
        wrapper_from(wrapped_attributes + [get_root])
      elsif keys.include? get_root.pluralize
        plural_wrapper
      else
        new_wrapper_from(wrapped_attributes)
      end
      wrapper.filter_unpermitted = filter_unpermitted
      wrapper
    end

    def require(*keys)
      require_attributes *keys
      self
    end
    alias_method :required, :require

    def require!(*keys)
      require *keys
      assert_required!(*to_hash.keys)
      self
    end
    alias_method :required!, :require!

    def permit(*keys)
      permit_attributes *keys
      self
    end

    def permit!
      @permitted = true
      deep_trigger_values! :permit!
      self
    end

    def to_hash
      Hash[
        map do |key, value|
          send key, value unless key.to_s == 'format'
        end.compact
      ].with_indifferent_access.tap do |hash|
        assert_required!(hash)
      end
    end

    def to_hash!
      to_hash.tap do |hash|
        hash.deep_trigger_values! :to_hash!
      end
    end

    def [](key)
      hydrate_association(key, super)
    end

    def fetch(key, *args)
      hydrate_association(key, super)
    end

    def slice(*keys)
      self.class.new(super).confer_settings_from(self)
    end

    def dup
      super.confer_settings_from(self)
    end

  protected

    def method_missing(key, *args, &block)
      if args.length == 1
        value = args.first
        if permitted? or (permitted_attributes | ALWAYS_PERMITTED_ATTRIBUTES).include? key.to_s
          [key, value]
        elsif wrap_attributes? and not nested? and key.to_s == root
          [key, value]
        else
          if filter_unpermitted?
            nil
          else
            raise(Exceptions::UnpermittedParameters.new(self.class, unpermitted_attributes))
          end
        end
      else
        super
      end
    end

    def get_root
      (root.present? ? root : self.class.name.split('::').last.underscore.gsub('_parameters', '')).to_s
    end

    def recognized_attributes
      self.class.instance_methods - Parameters.class.instance_methods
    end

    def permit_attributes(*keys)
      self.permitted_attributes |= keys.map(&:to_s)
    end
    alias_method :permit_attribute, :permit_attributes

    def unpermitted_attributes
      keys - permitted_attributes - ALWAYS_PERMITTED_ATTRIBUTES
    end

    def require_attributes(*keys)
      permit_attributes(*keys)
      self.required_attributes |= keys.map(&:to_s)
    end
    alias_method :require_attribute, :require_attributes

    def assert_required!(hash)
      missing_attributes = required_attributes.reject do |key|
        hash[key].presence
      end
      raise Exceptions::MissingParameters.new(self.class, missing_attributes) unless missing_attributes.empty?
    end

    def transform(key, value)
      transforms.reduce [key, value] do |args, transform|
        transform.call(*args)
      end
    end

    def wrapper_from(attributes)
      Default.new(get_root => self.class.new(self[get_root])).tap do |wrapper|
        each_pair do |key, value|
          wrapper[key] = value
        end
        wrapper.permit(get_root)
      end
    end

    def new_wrapper_from(attributes)
      Default.new(get_root => wrapped = self.dup).tap do |wrapper|
        keys.each do |attribute|
          wrapper[attribute] = wrapped[attribute]
          wrapped.delete(attribute) if (keys - attributes).include? attribute
        end
        wrapper.permit(get_root)
      end
    end

    def plural_wrapper
      Default.new.tap do |wrapper|
        each_pair do |key, value|
          wrapper[key] = value
        end
        wrapper[get_root.pluralize] = (self[get_root.pluralize] || {}).map do |params|
          self.class.new(params)
        end
        wrapper.permit(get_root.pluralize)
      end
    end

    def hydrate_association(association, value)
      if associations.keys.include? association
        self[association] = associations[association].call(value)
      else
        value
      end
    end

    def confer_settings_from(params)
      params.instance_variables.each do |instance_variable|
        instance_variable_set instance_variable, params.instance_variable_get(instance_variable)
      end
      self.permitted_attributes = params.permitted_attributes
      self.required_attributes  = params.required_attributes
      self.transforms           = params.transforms
      self
    end

  end
end
