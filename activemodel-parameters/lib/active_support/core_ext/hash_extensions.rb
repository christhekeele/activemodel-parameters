require 'active_support/core_ext/hash'

class ActiveSupport::HashWithIndifferentAccess < Hash

  def deep_trigger_values!(method_name)
    each_pair do |key, value|
      if value.respond_to? method_name
        self[key] = value.to_hash!
      elsif value.is_a? Array
        self[key] = value.map do |elem|
          if elem.respond_to? method_name
            elem.send method_name
          else
            elem
          end
        end
      end
    end
  end

  def transform_nested!(&transform)
    if value.kind_of? Hash
      self[key] = transform.call(value)
    elsif value.is_a? Array
      value.each do |elem|
        transform.call(elem)
      end
    end
  end

end
