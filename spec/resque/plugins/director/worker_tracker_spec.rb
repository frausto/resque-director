require 'spec_helper'

describe Resque::Plugins::Director::WorkerTracker do
  subject { Resque::Plugins::Director::WorkerTracker }
  
  before do
    Resque::Plugins::Director::Config.queue = "test"
  end
  
  describe "#workers" do  
    it"should return the workers for the queue" do
      Resque::Worker.new(:other).register_worker
      expected_worker = Resque::Worker.new(:test)
      expected_worker.register_worker
      
      subject.new.workers.should == [expected_worker]
    end
    
    it "should not return workers working on multiple queues" do
      Resque::Worker.new(:test, :other).register_worker
      subject.new.workers.should be_empty
    end
  end
  
  describe "worker numbers" do
    before do
      @worker = Resque::Worker.new(:test)
      @worker2 = Resque::Worker.new(:test)
    end
  
    describe "#total_to_remove" do
      before do
        Resque.should_receive(:workers).and_return [@worker, @worker2]
      end
      
      it "should limit the workers to be removed to not go below minimum allowed workers" do
        Resque::Plugins::Director::Config.setup :min_workers => 1
        subject.new.total_to_remove(2).should == 1
      end
    
      it "should allow the workers to be removed if it stays above the minimum" do
        Resque::Plugins::Director::Config.setup :min_workers => 0
        subject.new.total_to_remove(2).should == 2
      end
    end
  
  
    describe "#total_to_add" do
      before do
        Resque.should_receive(:workers).and_return [@worker, @worker2]
      end
      
      it "should limit the workers to be removed to not go below minimum allowed workers" do
        Resque::Plugins::Director::Config.setup :max_workers => 3
        subject.new.total_to_add(2).should == 1
      end
    
      it "should allow the workers to be removed if it stays above the minimum" do
        Resque::Plugins::Director::Config.setup :max_workers => 4
        subject.new.total_to_add(2).should == 2
      end
    
      it "should not limit workers added if max_workers is zero" do
        Resque::Plugins::Director::Config.setup :max_workers => 0
        subject.new.total_to_add(200).should == 200
      end
    end
  
    describe "#total_for_requirements" do
      it "should return the number of workers needed to meet the minimum requirement" do
        Resque.should_receive(:workers).and_return [@worker, @worker2]
        Resque::Plugins::Director::Config.setup :min_workers => 4
        subject.new.total_for_requirements.should == 2
      end
      
      it "should return the number of workers needed to meet the maximum requirement" do
        Resque.should_receive(:workers).and_return [@worker, @worker2]
        Resque::Plugins::Director::Config.setup :max_workers => 1
        subject.new.total_for_requirements.should == -1
      end
      
      it "should return 1 no workers are running and the minimum is zero" do
        Resque.should_receive(:workers).and_return []
        Resque::Plugins::Director::Config.setup :min_workers => 0
        subject.new.total_for_requirements.should == 1
      end
      
      it "should return 0 if number of workers is within requirements" do
        Resque.should_receive(:workers).and_return [@worker, @worker2]
        Resque::Plugins::Director::Config.setup :min_workers => 1, :max_workers => 3
        subject.new.total_for_requirements.should == 0
      end
    end
  end
end