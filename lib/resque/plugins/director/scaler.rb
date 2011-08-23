module Resque
  module Plugins
    module Director
      class Scaler
        class << self
        
          def scale_up(number_of_workers=1)
            number_of_workers = WorkerTracker.new.total_to_add(number_of_workers)
            scaling(number_of_workers) do
              start(number_of_workers)
            end
          end
        
          def scale_down(number_of_workers=1)
            tracker = WorkerTracker.new
            number_of_workers = tracker.total_to_remove(number_of_workers)
            
            scaling(number_of_workers) do
              stop(tracker, number_of_workers)
            end
          end
          
          def scale_down_to_minimum
            tracker = WorkerTracker.new
            number_of_workers = tracker.total_to_go_to_minimum
            stop(tracker, number_of_workers)
          end
          
          def scale_within_requirements
            number_of_workers = WorkerTracker.new.total_for_requirements
            
            if number_of_workers > 0
              scale_up(number_of_workers)
            elsif number_of_workers < 0
              scale_down(number_of_workers * -1)
            end
          end
          
          def scaling(number_of_workers=1)
            return unless time_to_scale? && number_of_workers > 0
            yield
            Resque.redis.set("last_scaled_#{Config.queue}", Time.now.utc.to_i)
          end
        
          private
         
          def time_to_scale?
            last_time = Resque.redis.get("last_scaled_#{Config.queue}")
            return true if last_time.nil?
            time_passed = (Time.now.utc - Time.at(last_time.to_i).utc)
            time_passed >= Config.wait_time
          end
          
          def start(number_of_workers)
            Config.log("starting #{number_of_workers} workers on queue #{Config.queue}")
            default_command = "QUEUE=#{Config.queue} rake resque:work &"
            number_of_workers.times { system(Config.start_override || default_command) }
          end
          
          def stop(tracker, number_of_workers)
            Config.log("stopping #{number_of_workers} workers on #{Config.queue}")
            if Config.stop_override
              number_of_workers.times { system(Config.stop_override) }
            else
              valid_workers = tracker.workers.select{|w| w.hostname == `hostname`.chomp}
              worker_pids = valid_workers[0...number_of_workers].map(&:pid)
              worker_pids.each {|pid| Process.kill("QUIT", pid)}
            end
          end
        end
      end
    end
  end
end