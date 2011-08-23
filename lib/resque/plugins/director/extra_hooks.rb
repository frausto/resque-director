module Resque
  module Plugins
    module Director
      module ExtraHooks

        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method :original_pop, :pop
            alias_method :original_push, :push
            extend ClassMethods
          end
        end

        module ClassMethods 
          def push(queue, item)
            item[:start_time] = Time.now.utc.to_i if item.respond_to?(:[]=)
            original_push queue, item
          end
          
          def pop(queue)
            job = original_pop(queue)
            begin 
              timestamp = job['start_time']
              start_time = timestamp.nil? ? Time.now.utc : Time.at(timestamp.to_i).utc
              job_class = constantize(job['class'])
              if job_class && job_class.respond_to?(:after_pop_direct_workers) && job_class.respond_to?(:direct)
                job_class.after_pop_direct_workers(start_time)
              end
            rescue
            end
            job
          end
        end
      end
    end
  end
end

module Resque
  include Resque::Plugins::Director::ExtraHooks
end