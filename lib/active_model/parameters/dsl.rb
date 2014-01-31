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
          base.class_attribute :transforms
          base.transforms ||= []
        end

      end

      def attribute(name, opts={}, &block)
        handler = if block_given?
          -> value { [name.to_s, block.call(value)] }
        else
          -> value { [name.to_s, value] }
        end
        method_name = opts.fetch(:from, name)
        define_attribute method_name, name, opts, &handler
      end

      def attributes(*args, &block)
        opts = args.extract_options!
        args.each do |name|
          attribute name, opts, &block
        end
      end

      def transform(func)
        self.transforms = self.transforms + [func]
      end

      def has_many(name, opts={}, &block)
        handler = if block_given?
          -> value { [name.to_s, block.call(value)] }
        else
          -> related { Parameters.class_for(opts.fetch(:parameter_class, name)).new(related, @scope, opts.merge(associated: true, listed: true)) }
        end
        method_name = opts.fetch(:from, name)
        define_attribute method_name, name, opts, &(
          -> relations do
            [ name, relations.map(&handler) ]
          end
        )
      end

      def has_one(name, opts={}, &block)
        handler = if block_given?
          -> value { [name.to_s, block.call(value)] }
        else
          -> related { [name, Parameters.class_for(opts.fetch(:parameter_class, name)).new(related, @scope, opts.merge(associated: true))] }
        end
        method_name = opts.fetch(:from, name)
        define_attribute method_name, name, opts, &handler
      end

      def belongs_to(name, opts={}, &block)
        method_name = opts.fetch(:from, name)
        foreign_key = opts.fetch(:foreign_key, "#{name}_id")
        key         = opts.fetch(:key, "id")
        handler = if block_given?
          -> value { [foreign_key.to_s, block.call(value)] }
        else
          -> related {
            if related.respond_to? key
              [foreign_key, related.send(key)]
            elsif related.respond_to? :has_key? and (related.has_key? key.to_sym or related.has_key? key.to_s)
              [foreign_key, related[key.to_sym] || related[key.to_s] ]
            else
              nil
            end
          }
        end
        define_attribute method_name, foreign_key, opts, &handler
      end

    private

      def define_attribute(method_name, attr_name, opts, &block)
        self.permitted_attributes |= [attr_name.to_s]
        self.required_attributes  |= [attr_name.to_s] if opts.fetch(:required, false)
        define_method method_name, &block
        opts.fetch(:aliases, []).each do |alias_name|
          alias_method alias_name, method_name
        end
      end

    end
  end
end
