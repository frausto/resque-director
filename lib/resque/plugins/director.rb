module Resque
  module Plugins
    module Director
      
      def direct(options={})
        Config.setup(options)
        Config.queue = @queue.to_s
      end
      
      def after_enqueue_start_workers(*args)
        @start_time = Time.now
        Scaler.scale_up(workers_to_start_on_enqueue) if workers_to_start_on_enqueue > 0
      end
      
      def before_perform_direct_workers(*args)
        time_through_queue = Time.now - (@start_time || Time.now)
        jobs_in_queue = Resque.size(@queue.to_s)
        
        time_limits_exceeded =  time_through_queue > Config.max_time && Config.max_time > 0 
        queue_limits_exceeded = jobs_in_queue > Config.max_queue && Config.max_queue > 0
        
        Scaler.scale_up if time_limits_exceeded || queue_limits_exceeded
      end
      
      private
      
      def workers_to_start_on_enqueue
        min_workers = Config.min_workers <= 0 ? 1 : Config.min_workers
        workers_to_start = min_workers - current_workers.size
      end
      
      def current_workers
        Resque.workers.select {|w| w.queues.size == 1 && w.queues.first == @queue.to_s }
      end
      
    end
  end
end