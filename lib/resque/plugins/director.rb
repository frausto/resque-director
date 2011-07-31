module Resque
  module Plugins
    module Director
      
      def direct(options={})
        Config.setup(options)
      end
      
      def after_enqueue_start_workers(*args)
        Config.queue = @queue.to_s
        @start_time = Time.now
        
        Scaler.scale_within_requirements
      end
      
      def before_perform_direct_workers(*args)
        time_through_queue = Time.now - (@start_time || Time.now)
        jobs_in_queue = Resque.size(@queue.to_s)
        
        time_limits_exceeded =  time_through_queue > Config.max_time && Config.max_time > 0
        queue_limits_exceeded = jobs_in_queue > Config.max_queue && Config.max_queue > 0
        
        Scaler.scale_up if time_limits_exceeded || queue_limits_exceeded
      end
    end
  end
end