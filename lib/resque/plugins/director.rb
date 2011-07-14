module Resque
  module Plugins
    module Director
      
      @min_workers = 1
      @max_workers = 0
      @max_time = 0
      @max_queue = 0
      @wait_time = 60
      
      def direct(options={})
        [:min_workers, :max_workers, :max_time, :max_queue, :wait_time].each do |opt|
          self.instance_variable_set("@#{opt.to_s}", options[opt]) if options[opt]
        end
      end
      
    end
  end
end