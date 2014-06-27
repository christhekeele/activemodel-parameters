require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/class/attribute'
require 'active_support/inflector'

module ActiveModel
  class Parameters < HashWithIndifferentAccess
    module DSL

      class << self

        def extended(base)
          base.class_attribute :permitted_attributes, instance_predicate: false
          base.permitted_attributes ||= []
          base.class_attribute :required_attributes, instance_predicate: false
          base.required_attributes ||= []
          base.class_attribute :wrap_attributes
          base.wrap_attributes = false
          base.class_attribute :wrapped_attributes, instance_predicate: false
          base.wrapped_attributes ||= []
          base.class_attribute :transforms
          base.transforms ||= []
          base.class_attribute :associations
          base.associations ||= {}.with_indifferent_access
        end

      end

      def attribute(name, opts={}, &block)
        attr_name   = name.to_s
        required    = opts.fetch(:required, false)
        method_name = opts.fetch(:from, name).to_sym
        aliases     = Array(opts.fetch(:aliases, [])).map(&:to_s)# | [method_name.to_s],
        wrappers    = [attr_name] | aliases

        define_attribute(attr_name, wrappers, required, method_name, aliases, &block)
      end

      def attributes(*args, &block)
        opts = args.extract_options!
        args.each do |name|
          attribute name, opts, &block
        end
      end

      def transform(&block)
        self.transforms += [block]
      end

      def has_many(name, opts={})
        if opts.key? :through
          has_and_belongs_to_many(name, opts)
        else
          attr_name   = "#{name}_attributes"
          required    = opts.fetch(:required, false)
          method_name = opts.fetch(:from, name).to_sym
          aliases     = Array(opts.fetch(:aliases, [])).map(&:to_s)# | [method_name.to_s]
          wrappers    = [attr_name] | aliases

          define_attribute(attr_name, wrappers, required, method_name, aliases)

          klass_name  = opts.fetch(:parameters_class, name.to_s.singularize)

          factory = -> relations do
            relations.map do |related|
              Parameters.class_for(klass_name).new(related, @scope, associated: true, listed: true)
            end
          end

          self.associations = self.associations.merge(method_name.to_s => factory)
        end
      end

      def has_one(name, opts={})
        attr_name   = "#{name}_attributes"
        required    = opts.fetch(:required, false)
        method_name = opts.fetch(:from, name).to_sym
        aliases     = Array(opts.fetch(:aliases, [])).map(&:to_s)# | [method_name.to_s]
        wrappers    = [attr_name] | aliases

        define_attribute(attr_name, wrappers, required, method_name, aliases)

        klass_name  = opts.fetch(:parameters_class, name.to_s.singularize)

        factory = -> related do
          Parameters.class_for(klass_name).new(related, @scope, associated: true)
        end

        self.associations = self.associations.merge(method_name.to_s => factory)
      end

      def has_and_belongs_to_many(name, opts={})
        attr_name   = "#{name.to_s.singularize}_ids"
        required    = opts.fetch(:required, false)
        method_name = opts.fetch(:from, name).to_sym
        aliases     = Array(opts.fetch(:aliases, [])).map(&:to_s)# | [method_name.to_s]
        wrappers    = [name.to_s, attr_name] | aliases

        primary_key  = opts.fetch(:primary_key, "id")

        define_attribute(attr_name, wrappers, required, method_name, aliases)

        klass_name  = opts.fetch(:parameters_class, name.to_s.singularize)

        factory = -> relations do
          relations.map do |related|
            coerce_to_primary_key(related, attr_name, primary_key)
          end.compact
        end

        self.associations = self.associations.merge(method_name.to_s => factory)
      end

      def belongs_to(name, opts={})
        attr_name    = opts.fetch(:foreign_key, "#{name}_id")
        required     = opts.fetch(:required, false)
        method_name  = opts.fetch(:from, name).to_sym
        aliases      = Array(opts.fetch(:aliases, [])).map(&:to_s).flat_map{ |a| [a, "#{a}_id"] } << attr_name
        wrappers     = [name.to_s, attr_name] | aliases

        primary_key  = opts.fetch(:primary_key, "id")

        define_attribute(attr_name, wrappers, required, method_name, aliases) do |related|
          self.class.coerce_to_primary_key(related, attr_name, primary_key)
        end
      end

    # protected

      def coerce_to_primary_key(related, attr_name, primary_key)
        if related.respond_to? primary_key
          [ attr_name, related.send(primary_key) ]
        elsif related.respond_to? :key? and (related.key? primary_key.to_sym or related.key? primary_key.to_s)
          [ attr_name, related[primary_key.to_sym] || related[primary_key.to_s] ]
        else
          nil
        end
      end

    private

      def define_attribute(attr_name, wrappers, required, method_name, aliases, &block)
        update_attributes attr_name, wrappers, required
        define_method method_name, block_given? ? block : -> value do
          [ attr_name, value ]
        end
        alias_attributes method_name, aliases
      end

      def update_attributes(attr_name, wrappers, required=false)
        self.permitted_attributes |= (wrappers << attr_name)
        self.required_attributes  |= (wrappers << attr_name) if required
        self.wrapped_attributes   |= wrappers if self.wrap_attributes?
      end

      def alias_attributes(method_name, aliases)
        aliases.each do |alias_name|
          alias_method alias_name, method_name
        end
      end

    end
  end
end
