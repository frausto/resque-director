module Resque
  module Plugins
    module Director
      
      def direct(options={})
        @config = Config.new(options)
      end
      
      def after_enqueue_start_workers(*args)
        @start_time = Time.now
        workers_to_start = config.min_workers - Resque.workers.size 
        Scaler.scale_up(@queue, workers_to_start) if workers_to_start > 0
      end
      
      def before_perform(*args)
        time_through_queue = Time.now - @start_time
      end
      
      private
      
      def config
        @config ||= Config.new
      end
      
    end
  end
end