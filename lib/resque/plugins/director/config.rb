module Resque
  module Plugins
    module Director
      module Config
        extend self
        
        attr_accessor :queue
        
        DEFAULT_OPTIONS = {
          :min_workers        => 1,
          :max_workers        => 0,
          :max_time           => 0,
          :max_queue          => 0,
          :wait_time          => 60,
          :start_override     => nil,
          :stop_override      => nil,
          :logger             => nil,
          :log_level          => :debug,
          :no_enqueue_scale   => false
        }
        
        def reset!
          DEFAULT_OPTIONS.each do |key, default|
            attr_reader key
            self.instance_variable_set("@#{key.to_s}", default)
          end
        end
        
        def log(message)
          @logger.send(@log_level, "DIRECTORS LOG: #{message}") if @logger
        end

        def setup(options={})
          DEFAULT_OPTIONS.each do |key, value|
            self.instance_variable_set("@#{key.to_s}", options[key] || value)
          end
          
          @min_workers = 0 if @min_workers < 0
          @max_workers = DEFAULT_OPTIONS[:max_workers] if @max_workers < @min_workers
        end
        
        reset!
      end
    end
  end
end