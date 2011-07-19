module Resque
  module Plugins
    module Director
      module Config
        extend self
        
        DEFAULT_OPTIONS = {
          :min_workers  => 1,
          :max_workers  => 0,
          :max_time     => 0,
          :max_queue    => 0,
          :wait_time    => 60
        }
        
        DEFAULT_OPTIONS.each do |key, default|
          attr_reader key
          define_method key do
            instance_variable_get("@#{key.to_s}") || default
          end
        end

        
        def setup(options={})
          DEFAULT_OPTIONS.each do |key, value|
            self.instance_variable_set("@#{key.to_s}", options[key] || value)
          end
          
          @max_workers = DEFAULT_OPTIONS[:max_workers] if @max_workers < @min_workers
        end
      end
    end
  end
end