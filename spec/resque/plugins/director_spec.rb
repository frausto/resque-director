require 'spec_helper'

class TestJob
  extend Resque::Plugins::Director
  @queue = :test
  
  def self.start_time=(st)
    @start_time = st
  end

  def self.perform
  end
end

describe Resque::Plugins::Director do
  before do
    TestJob.direct
  end
  
  it "should be a valid resque plugin" do
    Resque::Plugin.lint(Resque::Plugins::Director)
  end
  
  describe "#after_enqueue_start_workers" do
    it "should scale the workers to within the requirments specified" do
      Resque::Worker.new(:test).register_worker
      Resque::Plugins::Director::Scaler.should_receive(:scale_within_requirements)
      Resque.enqueue(TestJob)
    end
    
    it "should set the queue" do
      Resque.enqueue(TestJob)
      Resque::Plugins::Director::Config.queue.should == "test"
    end
  end
  
  describe "#before_perform_direct_workers" do
    describe "with time" do
      before do
        TestJob.start_time = Time.now - 10
      end
    
      it "should not start workers if max_time is not set" do
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        TestJob.before_perform_direct_workers
      end 
    
      it "should not start a worker if the time since it took is less than max_time" do
        TestJob.direct :max_time => 20
      
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        TestJob.before_perform_direct_workers
      end
    
      it "should add a worker if the time it takes the job to go through the queue is too long" do
        TestJob.direct :max_time => 5
        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
      
        TestJob.before_perform_direct_workers
      end
    end
    
    describe "with queue length" do
      it "should not start workers if max_queue is not set" do
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        TestJob.before_perform_direct_workers
      end
      
      it "should not start worker if the queue length is less than max_queue" do
        TestJob.direct :max_queue => 2
        Resque.enqueue(TestJob)
      
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        TestJob.before_perform_direct_workers
      end
      
      it "should start worker if the queue length is greater than max_queue" do
        TestJob.direct :max_queue => 1
        2.times { Resque.enqueue(TestJob) }
      
        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
        TestJob.before_perform_direct_workers
      end
    end
    
    describe "with length and time" do
      it "should add worker if only time constraint fails" do
        TestJob.direct :max_time => 5, :max_queue => 2
        Resque.enqueue(TestJob)
        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
      
        TestJob.start_time = Time.now - 10
        TestJob.before_perform_direct_workers
      end
      
      it "should add worker if only queue length constraint fails" do
        TestJob.direct :max_time => 15, :max_queue => 1
        2.times { Resque.enqueue(TestJob) }
      
        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
        TestJob.start_time = Time.now - 10
        TestJob.before_perform_direct_workers
      end
    end
  end
end
