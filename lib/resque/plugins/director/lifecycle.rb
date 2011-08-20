module Resque
  module Plugins
    module Director
      module Lifecycle

        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method :push_without_lifecycle, :push
            extend ClassMethods
          end
        end

        module ClassMethods 
          def push(queue, item)
            begin
              if item.respond_to?(:[]=)
                job_class =  constantize(item[:class] || item['class'])
                if job_class && job_class.ancestors.include?(Resque::Plugins::Director)
                  timestamp = {'resdirecttime' => Time.now.utc.to_i}
                  item[:args] = item[:args].push(timestamp)
                end
              end
            rescue
            end
            push_without_lifecycle queue, item
          end
        end
      end
    end
  end
end

module Resque
  include Resque::Plugins::Director::Lifecycle
end