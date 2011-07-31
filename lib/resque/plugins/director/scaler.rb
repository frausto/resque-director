module Resque
  module Plugins
    module Director
      class Scaler
        class << self
        
          def scale_up(number_of_workers=1)
            scaling do
              number_of_workers.times { system(start_command) }
            end
          end
        
          def scale_down(number_of_workers=1)
            scaling do
              current_workers[0..number_of_workers].map(&:shutdown)
            end
          end
          
          def scale_within_requirements
            number_working = current_workers.size
            min_workers = Config.min_workers <= 0 ? 1 : Config.min_workers
            workers_to_start = min_workers - number_working
            return scale_up(workers_to_start) if workers_to_start > 0

            workers_to_stop = number_working - Config.max_workers
            scale_down(workers_to_stop) if workers_to_stop > 0
          end
          
          def scaling
            return unless time_to_scale?
            yield
            Resque.redis.set("last_scaled_#{Config.queue}", Time.now)
          end
        
          private
          
          def current_workers
            Resque.workers.select {|w| w.queues == [Config.queue] }
          end
                    
          def start_command
            return Config.command_override unless Config.command_override.nil?
            navigate = Config.run_path ? "cd #{Config.run_path} && " : ""
            "#{navigate}#{Config.vars} QUEUE=#{Config.queue} #{Config.rake_path} #{Config.environment} resque:work &"
          end
         
          def time_to_scale?
            last_time = Resque.redis.get("last_scaled_#{Config.queue}")
            last_time.nil? || (Time.now - Time.parse(last_time)) >= Config.wait_time
          end
        end
      end
    end
  end
end