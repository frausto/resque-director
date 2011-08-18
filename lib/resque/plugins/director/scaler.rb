module Resque
  module Plugins
    module Director
      class Scaler
        class << self
        
          def scale_up(number_of_workers=1)
            number_of_workers = workers_to_scale_up(current_workers.size, number_of_workers)
            
            scaling(number_of_workers) do
              number_of_workers.times { system(start_command) }
            end
          end
        
          def scale_down(number_of_workers=1)
            workers = current_workers
            number_of_workers = workers_to_scale_down(workers.size, number_of_workers)

            scaling(number_of_workers) do
              workers[0...number_of_workers].map(&:shutdown)
            end
          end
          
          def scale_within_requirements
            number_working = current_workers.size
            start_number = workers_to_start(number_working)
            stop_number = workers_to_stop(number_working)
            
            if start_number > 0
              scale_up(start_number)
            elsif stop_number > 0
              scale_down(stop_number)
            end
          end
          
          def scaling(number_of_workers=1)
            return unless time_to_scale? && number_of_workers > 0
            yield
            Resque.redis.set("last_scaled_#{Config.queue}", Time.now.utc.to_i)
          end
        
          private
          
          def workers_to_scale_up(number_working, number_to_start)
            return number_to_start if Config.max_workers <= 0
            scale_limit = Config.max_workers - current_workers.size 
            number_to_start > scale_limit ? scale_limit : number_to_start
          end
          
          def workers_to_scale_down(number_working, number_to_stop)
            scale_limit = number_working - Config.min_workers
            number_to_stop > scale_limit ? scale_limit : number_to_stop
          end
          
          def workers_to_start(number_working)
            min_workers = Config.min_workers <= 0 ? 1 : Config.min_workers
            workers_to_start = min_workers - number_working
          end
          
          def workers_to_stop(number_working)
            return 0 if Config.max_workers <= 0
            workers_to_stop = number_working - Config.max_workers
          end
          
          def current_workers
            Resque.workers.select {|w| w.queues == [Config.queue] }
          end
                    
          def start_command
            default_command = "QUEUE=#{Config.queue} rake environment resque:work &"
            Config.command_override || default_command
          end
         
          def time_to_scale?
            last_time = Resque.redis.get("last_scaled_#{Config.queue}")
            last_time.nil? || (Time.now.utc - Time.at(last_time.to_i).utc) >= Config.wait_time
          end
        end
      end
    end
  end
end