require 'resque'

require 'resque/plugins/director'
require 'resque/plugins/director/worker_tracker'
require 'resque/plugins/director/config'
require 'resque/plugins/director/scaler'
require 'resque/plugins/director/push_pop'

module Resque
  include Resque::Plugins::Director::PushPop
end
