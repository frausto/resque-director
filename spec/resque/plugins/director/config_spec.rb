require 'spec_helper'

describe Resque::Plugins::Director::Config do
  subject { Resque::Plugins::Director::Config }
  
  describe "#initialize" do  
    it "should set the variables to defaults if none are specified" do
      config = subject.new
      config.min_workers.should == 1
      config.wait_time.should == 60
    end
    
    it "should set the variables to the specified values" do
      config = subject.new(:min_workers => 3, :wait_time => 30)
      config.min_workers.should == 3
      config.wait_time.should == 30
    end
    
    it "should handle bogus config options" do
      lambda { subject.new(:bogus => 3) }.should_not raise_error
    end
    
    it "should set max_workers to default if less than min_workers" do
      config = subject.new(:min_workers => 3, :max_workers => 2)
      config.min_workers.should == 3
      config.max_workers.should == 0
    end
  end
end