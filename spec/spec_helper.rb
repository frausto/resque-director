$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'resque'
Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].each {|f| require f}

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

#
# make sure we can run redis
#
if !system("which redis-server")
  puts '', "** can't find `redis-server` in your path"
  puts "** try running `sudo rake install`"
  abort ''
end

dir = File.dirname(__FILE__)
#
# start our own redis when the tests start,
# kill it when they end
#

at_exit do
  pid = `ps -e -o pid,command | grep [r]edis-test`.split(" ")[0]
  puts "Killing test redis server [#{pid}]..."
  `rm -f #{dir}/dump.rdb`
  Process.kill("KILL", pid.to_i)
end

puts "Starting redis for testing at localhost:9736..."
`redis-server #{dir}/redis-test.conf`
Resque.redis = 'localhost:9736'
ENV['VERBOSE'] = 'true'

RSpec.configure do |config|
  config.before(:each) do
    Resque::Plugins::Director::Scaler.stub!(:system) 
    Resque.redis.flushall
  end
end
