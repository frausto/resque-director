module Resque
  module Plugins
    module Director
      class Config
        
        DEFAULT_OPTIONS = {
          :min_workers  => 1,
          :max_workers  => 0,
          :max_time     => 0,
          :max_queue    => 0,
          :wait_time    => 60
        }
        
        attr_accessor *(DEFAULT_OPTIONS.keys)
        
        def initialize(options={})
          DEFAULT_OPTIONS.each do |key, value|
            self.instance_variable_set("@#{key}", options[key] || value)          
          end
          
          ensure_validity
        end
        
        private
        
        def ensure_validity
          @max_workers = DEFAULT_OPTIONS[:max_workers] if @max_workers < @min_workers
        end
      end
    end
  end
end