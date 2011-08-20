class TestJob
  include Resque::Plugins::Director
  @queue = :test

  def self.perform
  end
end