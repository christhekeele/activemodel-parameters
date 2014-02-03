require 'active_support/core_ext/hash'

require 'active_model/parameters/dsl'
require 'active_model/parameters/utils'
require 'active_model/parameters/default'
require 'active_model/parameters/exceptions'

module ActiveModel
  class Parameters < HashWithIndifferentAccess

    ALWAYS_PERMITTED_ATTRIBUTES = %w[controller action format]

    class_attribute :wrap
    class_attribute :root
    class_attribute :filter_unpermitted

    attr_reader :scope, :permitted, :associated, :listed, :nested
    alias_method :permitted?,  :permitted
    alias_method :associated?, :associated
    alias_method :listed?,     :listed
    alias_method :nested?,     :nested

    def initialize(hashlike={}, scope=nil, opts={})
      super(hashlike.to_hash)
      @scope      = scope
      @associated = opts.fetch(:associated, false)
      @listed     = opts.fetch(:listed, false)
      @nested     = @associated or @listed
      @permitted  = false
    end

    extend DSL
    extend Utils::SubclassTracker

    def require(*keys)
      require_attributes *keys
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
    end

    def permit!
      @permitted = true
      each_pair do |key, value|
        if value.respond_to? :permit!
          self[key] = value.permit!
        elsif value.is_a? Array
          self[key] = value.map do |elem|
            if elem.respond_to? :permit!
              elem.permit!
            else
              elem
            end
          end
        end
      end
      self
    end

    def to_hash
      Hash[
        map do |key, value|
          send *transform(key.to_s, value)
        end.compact
      ].with_indifferent_access.tap do |hash|
        assert_required!(hash)
        wrap!(hash) if wrap? and not nested?
      end
    end

    def to_hash!
      to_hash.tap do |hash|
        hash.each_pair do |key, value|
          if value.respond_to? :to_hash!
            hash[key] = value.to_hash!
          elsif value.is_a? Array
            hash[key] = value.map do |elem|
              if elem.respond_to? :to_hash!
                elem.to_hash!
              else
                elem
              end
            end
          end
        end
      end
    end

    def method_missing(key, *args, &block)
      if args.length == 1
        value = args.first
        if permitted? or permitted_attributes.include? key.to_s
          [key, value]
        else
          if filter_unpermitted?
            nil
          else
            raise(Exceptions::UnpermittedParameters.new(unpermitted_attributes))
          end
        end
      else
        super
      end
    end

    def dup
      super.tap do |duplicate|
        p.instance_variables.each do |instance_variable|
          duplicate.instance_variable_set instance_variable, instance_variable_get(instance_variable)
        end
        duplicate.permitted_attributes = permitted_attributes
        duplicate.required_attributes  = required_attributes
        duplicate.transforms           = transforms
      end
    end

  protected

    def wrap!(hash)
      hash[root!] = root = {}.with_indifferent_access
      attributes = if wrap == true
        permitted_attributes
      elsif wrap.kind_of? Array
        wrap
      end
      attributes.each do |attribute|
        root[attribute] = hash.delete(attribute)
      end
    end

    def root!
      unless root
        self.class.name.split('::').last.underscore.gsub('_parameters', '')
      else
        root
      end
    end

    def recognized_attributes
      self.class.instance_methods - Parameters.class.instance_methods
    end

    def permit_attributes(*keys)
      self.permitted_attributes |= keys.map(&:to_s)
      self
    end
    alias_method :permit_attribute, :permit_attributes

    def unpermitted_attributes
      keys - permitted_attributes - ALWAYS_PERMITTED_ATTRIBUTES
    end

    def require_attributes(*keys)
      permit_attributes(*keys)
      self.required_attributes |= keys.map(&:to_s)
      self
    end
    alias_method :require_attribute, :require_attributes

    def transform(key, value)
      transforms.reduce [key, value] do |args, transform|
        transform.call(*args)
      end
    end

    def assert_required!(hash)
      missing_attributes = required_attributes.reject do |key|
        hash[key].presence
      end
      raise Exceptions::MissingParameters.new(missing_attributes) unless missing_attributes.empty?
    end

  end
end
