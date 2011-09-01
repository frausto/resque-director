module Resque
  module Plugins
    module Director
      def direct(options={})
        Config.setup(options)
      end
    
      def after_enqueue_scale_workers(*args)
        Config.queue = @queue.to_s
        Scaler.scale_within_requirements
      end
    
      def after_pop_direct_workers(start_time=Time.now.utc)
        return unless scaling_config_set?
        Config.queue = @queue.to_s
        
        time_through_queue = Time.now.utc - start_time
        jobs_in_queue = Resque.size(@queue.to_s)
      
        if scale_up?(time_through_queue, jobs_in_queue)
          Scaler.scale_up
        elsif scale_down?(time_through_queue, jobs_in_queue)
          Scaler.scale_down
        end
      end
    
      def after_perform_direct_workers(*args)
        Config.queue = @queue.to_s
        jobs_in_queue = Resque.size(@queue.to_s)
        Scaler.scale_down_to_minimum if jobs_in_queue == 0
      end
    
      def on_failure_direct_workers(*args)
        Config.queue = @queue.to_s
        jobs_in_queue = Resque.size(@queue.to_s)
        Scaler.scale_down_to_minimum if jobs_in_queue == 0
      end
    
      private
    
      def scaling_config_set?
        Config.max_time > 0 || Config.max_queue > 0
      end
    
      def scale_up?(time_through_queue, jobs_in_queue)
        time_limits =  Config.max_time > 0 && time_through_queue > Config.max_time 
        queue_limits = Config.max_queue > 0 && jobs_in_queue > Config.max_queue
        time_limits || queue_limits
      end
    
      def scale_down?(time_through_queue, jobs_in_queue)
        time_limits =  Config.max_time > 0 && time_through_queue < (Config.max_time/2)
        queue_limits = Config.max_queue > 0 && jobs_in_queue < (Config.max_queue/2) 
        (Config.max_time <= 0 || time_limits) && (Config.max_queue <= 0 || queue_limits)
      end
    end
  end
end