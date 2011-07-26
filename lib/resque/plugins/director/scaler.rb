module Resque
  module Plugins
    module Director
      class Scaler
        class << self
        
          def scale_up(number_of_workers=1)
            scaling do
              number_of_workers.times { system("QUEUE=#{Config.queue} rake resque:work &") }
            end
          end
        
          def scale_down(worker)
            scaling do
              worker.shutdown
            end
          end
        
          private
        
          def scaling
            return unless time_to_scale?
            yield
            Resque.redis.set("last_scaled_#{Config.queue}", Time.now)
          end
         
          def time_to_scale?
            last_time = Resque.redis.get("last_scaled_#{Config.queue}")
            last_time.nil? || (Time.now - Time.parse(last_time)) > Config.wait_time
          end
        end
      end
    end
  end
end