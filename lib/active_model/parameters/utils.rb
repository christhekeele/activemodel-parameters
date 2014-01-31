module ActiveModel
  class Parameters < HashWithIndifferentAccess
    module Utils
      module SubclassTracker

        def self.extended base
          super
          class << base

            attr_reader :subclasses unless defined? :subclasses
            attr_reader :types, :kinds

            def inherited subclass
              super
              @subclasses ||= []
              @subclasses << subclass
              @types ||= []
              @types << type_name(subclass)
              @kinds ||= {}.with_indifferent_access
              @kinds[type_name subclass] = subclass
            end

          private

            def type_name(subclass)
              subclass.name.split('::').last[/^(?<type>.*?)(Parameters)?$/, :type].underscore
            end

          end
        end

        def class_for(lookup)
          if lookup.ancestors.include? Parameters
            lookup
          else
            @kinds.fetch(lookup.to_s.singularize, @kinds.fetch(lookup.to_s.singularize.gsub(/_parameters$/, ''), Parameters::Default))
          end
        end

      end
    end
  end
end
