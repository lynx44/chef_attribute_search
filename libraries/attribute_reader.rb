module ChefAttributeSearch
  module AttributeReader
    def read_attribute(hash, required, var_name, *keys)
      value = hash
      enumerated_keys = Array.new
      keys.each do |key|
        value = value[key]
        enumerated_keys.push(key)
        if value == nil
          if !required
            break
          else
            message = "Value for #{format(var_name, enumerated_keys)} returned nil"
            message += " while attempting to retrieve #{format(var_name, keys)}" unless enumerated_keys.length == keys.length
            raise message
          end
        end
      end

      log_message = "#{format(var_name, keys)} = #{(value || 'nil')}"
      logger.debug(log_message)

      value
    end

    def logger
      @@logger ||= Chef::Log
    end

    private
    def format_keys(keys)
      keys.map { |k| "['#{k}']" }.join()
    end

    def format(var_name, keys)
      "#{var_name}#{format_keys(keys)}"
    end
  end
end