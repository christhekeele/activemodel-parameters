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
              @types << subclass.type
              @kinds ||= {}.with_indifferent_access
              @kinds[subclass.type] = subclass
            end

            def type
              name.split('::').last[/^(?<type>.*?)(Parameters)?$/, :type].underscore
            end

          end
        end

        def class_for(lookup)
          if lookup.is_a? Class
            lookup.ancestors.include?(Parameters) ? lookup : Parameters::Default
          else
            @kinds.fetch(lookup.to_s.singularize, @kinds.fetch(lookup.to_s.singularize.gsub(/_parameters$/, ''), Parameters::Default))
          end
        end

      end
    end
  end
end
