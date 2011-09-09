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
            tracker = WorkerTracker.new
            number_of_workers = tracker.total_for_requirements
            if number_of_workers > 0
              set_last_scaled unless start(number_of_workers) == false
            elsif number_of_workers < 0
              set_last_scaled unless stop(tracker, number_of_workers * -1) == false
            end
          end
          
          def scaling(number_of_workers=1)
            return unless time_to_scale? && number_of_workers > 0
            set_last_scaled unless yield == false
          end
        
          private
          
          def set_last_scaled
            Resque.redis.set("last_scaled_#{[Config.queue].flatten.join('')}", Time.now.utc.to_i)
          end
         
          def time_to_scale?
            last_time = Resque.redis.get("last_scaled_#{[Config.queue].flatten.join('')}")
            return true if last_time.nil?
            time_passed = (Time.now.utc - Time.at(last_time.to_i).utc)
            time_passed >= Config.wait_time
          end
          
          def start(number_of_workers)
            Config.log("starting #{number_of_workers} workers on queue:#{Config.queue}") if number_of_workers > 0
            return override(number_of_workers, Config.start_override) if Config.start_override
            start_default(number_of_workers)
          end
          
          def stop(tracker, number_of_workers)
            Config.log("stopping #{number_of_workers} workers on queue:#{Config.queue}") if number_of_workers > 0
            return override(number_of_workers, Config.stop_override) if Config.stop_override
            stop_default(tracker, number_of_workers)
          end
          
          def override(number_of_workers, override_block)
            number_of_workers.times {override_block.call(Config.queue) }
          end
          
          def start_default(number_of_workers)
            number_of_workers.times { system("QUEUE=#{[Config.queue].flatten.join(",")} rake resque:work &") }
          end

          def stop_default(tracker, number_of_workers)
            worker_pids = tracker.valid_worker_pids[0...number_of_workers]
            worker_pids.each do |pid| 
              Process.kill("QUIT", pid) rescue nil
            end
          end
        end
      end
    end
  end
end