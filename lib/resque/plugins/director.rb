module Resque
  module Plugins
    module Director
      
      def self.included(base)
        base.extend ClassMethods
        base.overwrite_perform
        base.instance_eval do
          def singleton_method_added(name)
            return if name != :perform
            overwrite_perform
          end
        end
      end
      
      module ClassMethods
        def direct(options={})
          Config.setup(options)
        end
        
        def overwrite_perform
          class_eval do |klass|
            if klass.respond_to?('perform') && !klass.respond_to?('custom_perform')
              klass.instance_eval do
                def custom_perform(*args)
                  args.pop unless retrieve_timestamp(args.last).nil?
                  original_perform(*args)
                end
              end

              class << klass
                alias_method :original_perform, :perform
                alias_method :perform, :custom_perform
              end
            end
          end
        end
      
        def after_enqueue_scale_workers(*args)
          Config.queue = @queue.to_s
          Scaler.scale_within_requirements
        end
      
        def before_perform_direct_workers(*args)
          return unless scaling_config_set?
          Config.queue = @queue.to_s
          time_stamp = retrieve_timestamp(args.pop)
          start_time = time_stamp.nil? ? Time.now.utc : Time.at(time_stamp.to_i).utc 
        
          time_through_queue = Time.now.utc - start_time
          jobs_in_queue = Resque.size(@queue.to_s)
        
          if scale_up?(time_through_queue, jobs_in_queue)
            Scaler.scale_up
          elsif scale_down?(time_through_queue, jobs_in_queue)
            Scaler.scale_down
          end
        end
      
        def after_perform_direct_workers(*args)
          jobs_in_queue = Resque.size(@queue.to_s)
          Scaler.scale_down_to_minimum if jobs_in_queue == 0
        end
      
        def on_failure_direct_workers(*args)
          jobs_in_queue = Resque.size(@queue.to_s)
          Scaler.scale_down_to_minimum if jobs_in_queue == 0
        end
      
        private
        
        def retrieve_timestamp(timestamp)
          return nil unless timestamp.class.to_s == "Hash"
          timestamp['resdirecttime'] || timestamp[:resdirecttime]
        end
      
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
end