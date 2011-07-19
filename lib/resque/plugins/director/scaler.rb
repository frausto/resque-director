module Resque
  module Plugins
    module Director
      class Scaler
        class << self
        
          def scale_up(queue, workers)
            scaling do
              workers.times { }
            end
          end
        
          def scale_down(queue, workers)
            scaling do
              workers.times { }
            end
          end
        
          private
        
          def scaling
            return unless time_to_scale?
            yield
            Resque.redis.set('last_scaled', Time.now)
          end
         
          def time_to_scale?(wait_time)
            last_time = Resque.redis.get('last_scaled')
            (Time.now - last_time) > wait_time
          end
        end
      end
    end
  end
end