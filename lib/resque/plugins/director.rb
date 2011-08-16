module Resque
  module Plugins
    module Director
      
      def direct(options={})
        Config.setup(options)
      end
      
      def after_enqueue_scale_workers(*args)
        Config.queue = @queue.to_s
        @start_time = Time.now
        
        Scaler.scale_within_requirements
      end
      
      def before_perform_direct_workers(*args)
        return unless scaling_config_set?
        
        time_through_queue = Time.now - (@start_time || Time.now)
        jobs_in_queue = Resque.size(@queue.to_s)
        
        if scale_up?(time_through_queue, jobs_in_queue)
          Scaler.scale_up
        elsif scale_down?(time_through_queue, jobs_in_queue)
          Scaler.scale_down
        end
      end
      
      private
      
      def scaling_config_set?
        Config.max_time > 0 || Config.max_queue > 0
      end
      
      def scale_up?(time_through_queue, jobs_in_queue)
        time_limits_exceeded =  Config.max_time > 0 && time_through_queue > Config.max_time 
        queue_limits_exceeded = Config.max_queue > 0 && jobs_in_queue > Config.max_queue
        time_limits_exceeded || queue_limits_exceeded
      end
      
      def scale_down?(time_through_queue, jobs_in_queue)
        time_limits =  Config.max_time > 0 && time_through_queue < (Config.max_time/2)
        queue_limits = Config.max_queue > 0 && jobs_in_queue < (Config.max_queue/2) 
        (Config.max_time <= 0 || time_limits) && (Config.max_queue <= 0 || queue_limits)
      end
    end
  end
end