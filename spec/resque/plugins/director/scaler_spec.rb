require 'spec_helper'

describe Resque::Plugins::Director::Scaler do
  subject { Resque::Plugins::Director::Scaler }
  
  before do
    Resque::Plugins::Director::Config.queue = "test"
  end
  
  describe "#scale_up" do
    it "should start a worker on a specific queue" do
      subject.should_receive(:system).with("QUEUE=test rake resque:work &")
      subject.scale_up
    end
    
    it "should start the specified number of workers on a specific queue" do
      subject.should_receive(:system).twice.with("QUEUE=test rake resque:work &")
      subject.scale_up(2)
    end
    
    it "should not start more workers than the maximum allowed" do
      Resque::Plugins::Director::Config.setup :max_workers => 1
      subject.should_receive(:system).once.with("QUEUE=test rake resque:work &")
      subject.scale_up(2)
    end
    
    it "should override the entire comand" do
      test_block = lambda {|queue| }
      Resque::Plugins::Director::Config.setup :start_override => test_block
      test_block.should_receive(:call).with("test")
      subject.scale_up
    end
  end
  
  describe "#scaling" do
    before do
      @times_scaled = 0
    end
    
    it "should not scale workers if last time scaled is too soon" do
      Resque::Plugins::Director::Config.setup(:wait_time => 60)
      2.times { subject.scaling { @times_scaled += 1 } }
      @times_scaled.should == 1
    end
    
    it "should scale workers if wait time has passed" do
      Resque::Plugins::Director::Config.setup(:wait_time => 0)
      2.times { subject.scaling { @times_scaled += 1 } }
      @times_scaled.should == 2
    end
  end
  
  describe "#scale_down_to_minimum" do
    before do
      @worker = Resque::Worker.new(:test)
      Resque::Plugins::Director::Config.setup :min_workers => 1
    end
    
    it "should scale workers down to the minimum" do
      Resque.should_receive(:workers).and_return [@worker, @worker, @worker]
      Process.should_receive(:kill).twice
      subject.scale_down_to_minimum
    end
    
    it "should not scale if the workers are already at the minimum" do
      Resque.should_receive(:workers).and_return [@worker]
      Process.should_not_receive(:kill)
      subject.scale_down_to_minimum
    end
    
    it "forces scaling by ignoring wait_time" do
      Resque::Plugins::Director::Config.setup(:wait_time => 60, :min_workers => 2)
      subject.scaling {}
      Resque.should_receive(:workers).and_return [@worker, @worker, @worker]
      Process.should_receive(:kill)
      subject.scale_down_to_minimum
    end
  end
  
  describe "#scale_down" do
    before do
      @worker = Resque::Worker.new(:test)
      Resque::Plugins::Director::Config.setup :min_workers => 0
    end
    
    it "should scale down a single worker by default" do
      Resque.should_receive(:workers).and_return [@worker, @worker]
      
      Process.should_receive(:kill).once
      subject.scale_down
    end
    
    it "should scale down multiple workers" do
      Resque.should_receive(:workers).and_return [@worker, @worker, @worker]
      Process.should_receive(:kill).with("QUIT", @worker.pid)
      subject.scale_down(2)
    end
    
    it "should not scale down more than the minimum allowed workers" do
      Resque::Plugins::Director::Config.setup :min_workers => 1
      
      Resque.should_receive(:workers).and_return [@worker, @worker]
      Process.should_receive(:kill).once
      subject.scale_down(2)
    end
    
    it "should not throw exceptions when process throws exception" do
      Resque.should_receive(:workers).and_return [@worker, @worker]
      Process.should_receive(:kill).and_throw(:Exception)
      lambda { subject.scale_down }.should_not raise_error
    end
    
    it "should not scale down workers on different queues" do
      worker2 = Resque::Worker.new(:not_test)
      @worker.stub(:pid => 1) 
      worker2.stub(:pid => 2)
      Resque.should_receive(:workers).and_return [worker2, @worker, @worker, worker2]
      
      Process.should_not_receive(:kill).with("QUIT", worker2.pid)
      Process.should_receive(:kill).with("QUIT", @worker.pid)
      subject.scale_down
    end
  end
  
  describe "#stop" do
    before do
      @worker = Resque::Worker.new(:test)
      Resque::Plugins::Director::Config.setup :min_workers => 0
    end
    
    it "should kill worker by sending the QUIT signal to the workers pid" do
      Resque.should_receive(:workers).and_return [@worker]
      tracker = Resque::Plugins::Director::WorkerTracker.new
      
      Process.should_receive(:kill).with("QUIT", @worker.pid)
      subject.send(:stop, tracker, 1)
    end
    
    it "should use the stop block to stop a worker if set" do
      test_block = lambda {|queue| }
      Resque::Plugins::Director::Config.setup :stop_override => test_block, :min_workers => 0
      
      Resque.should_receive(:workers).and_return [@worker]
      tracker = Resque::Plugins::Director::WorkerTracker.new
      
      test_block.should_receive(:call).with("test")
      Process.should_not_receive(:kill)
      subject.send(:stop, tracker, 1)
    end
    
    it "does not stop workers already set to be shutdown" do
      @worker.should_receive(:shutdown?).and_return(true)
      Resque.should_receive(:workers).and_return [@worker]
      tracker = Resque::Plugins::Director::WorkerTracker.new
      
      Process.should_not_receive(:kill).with("QUIT", @worker.pid)
      subject.send(:stop, tracker, 1)
    end
    
    it "does not kill worker processes on different machines" do
      @worker.stub!(:hostname => "different_machine")
      Resque.should_receive(:workers).and_return [@worker]
      tracker = Resque::Plugins::Director::WorkerTracker.new
      
      Process.should_not_receive(:kill).with("QUIT", @worker.pid)
      subject.send(:stop, tracker, 1)
    end
    
    it "stops workers on the same host if possible" do
      @worker.stub!(:hostname => "different_machine")
      worker2 = Resque::Worker.new(:test)
      Resque.should_receive(:workers).and_return [@worker, worker2]
      tracker = Resque::Plugins::Director::WorkerTracker.new
      
      Process.should_receive(:kill).with("QUIT", worker2.pid)
      subject.send(:stop, tracker, 1)
    end
    
    it "ignores hostname if using custom stop script" do
      test_block = lambda {|queue| }
      Resque::Plugins::Director::Config.setup :stop_override => test_block, :min_workers => 0
      
      @worker.stub!(:hostname => "different_machine")
      Resque.should_receive(:workers).and_return [@worker]
      tracker = Resque::Plugins::Director::WorkerTracker.new
      
      test_block.should_receive(:call).with("test")
      Process.should_not_receive(:kill)
      subject.send(:stop, tracker, 1)
    end
  end
  
  describe "#scale_within_requirements" do
    it "should not scale up workers if the minumum number or greater are already running" do
      Resque::Worker.new(:test).register_worker
      subject.should_not_receive(:scale_up)
      subject.scale_within_requirements
    end
    
    it "should scale up the minimum number of workers if non are running" do
      Resque::Plugins::Director::Config.setup :min_workers => 2
      subject.should_receive(:scale_up).with(2)
      subject.scale_within_requirements
    end
    
    it "should ensure at least one worker is running if min_workers is less than zero" do
      Resque::Plugins::Director::Config.setup :min_workers => -10
      subject.should_receive(:scale_up).with(1)
      subject.scale_within_requirements
    end
    
    it "should ensure at least one worker is running if min_workers is zero" do
      Resque::Plugins::Director::Config.setup :min_workers => 0
      subject.should_receive(:scale_up).with(1)
      subject.scale_within_requirements
    end
    
    it "should scale up the minimum number of workers if less than the minimum are running" do
      Resque::Plugins::Director::Config.setup :min_workers => 2
      Resque::Worker.new(:test).register_worker
      subject.should_receive(:scale_up).with(1)
      subject.scale_within_requirements
    end
    
    it "should scale down the max number of workers if more than max" do
      Resque::Plugins::Director::Config.setup :max_workers => 1
      workers = 2.times.map { Resque::Worker.new(:test) }
      Resque.should_receive(:workers).and_return(workers)
      
      subject.should_receive(:scale_down).with(1)
      subject.scale_within_requirements
    end
    
    it "should not scale down if max_workers is zero" do
      Resque::Plugins::Director::Config.setup :max_workers => 0
      workers = 1.times.map { Resque::Worker.new(:test) }
      Resque.should_receive(:workers).and_return(workers)
      
      subject.should_not_receive(:scale_down)
      subject.scale_within_requirements
    end
    
    it "should ignore workers from other queues" do
      Resque::Worker.new(:other).register_worker
      subject.should_receive(:scale_up).with(1)
      subject.scale_within_requirements
    end
    
    it "should ignore workers on multiple queues" do
      Resque::Worker.new(:test, :other).register_worker
      subject.should_receive(:scale_up).with(1)
      subject.scale_within_requirements
    end
  end
end