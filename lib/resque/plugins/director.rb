module Resque
  module Plugins
    module Director
      
      def direct(options={})
        Config.setup(options)
      end
      
      def after_enqueue_start_workers(*args)
        @start_time = Time.now
        workers_to_start = Config.min_workers - current_workers.size 
        Scaler.scale_up(@queue, workers_to_start) if workers_to_start > 0
      end
      
      def before_perform_direct_workers(*args)
        time_through_queue = Time.now - (@start_time || Time.now)
        jobs_in_queue = Resque.size(@queue.to_s)
        
        if time_through_queue > Config.max_time || jobs_in_queue > Config.max_queue
          puts "about to be in scale up"
          Scaler.scale_up(@queue)
          puts "finished in scale up"
        end
      end
      
      private
      
      def current_workers
        Resque.workers.select {|w| w.queues.size == 1 && w.queues.first == @queue.to_s }
      end
      
    end
  end
end