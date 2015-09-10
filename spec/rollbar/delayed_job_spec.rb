require 'spec_helper'
require 'delayed_job'
require 'rollbar/delayed_job'

describe Rollbar::Delayed, :reconfigure_notifier => true do
  class FailingJob
    class TestException < Exception; end

    def do_job
      this = will_crash!
    end

    def do_job_please!(a, b)
      this = will_crash_again!
    end
  end

  before do
    Rollbar::Delayed.wrap_worker
    Delayed::Worker.backend = :test

    Delayed::Worker.reset
  end

  let(:logger) { Rollbar.logger }
  let(:expected_args) do
    [kind_of(NoMethodError), { :use_exception_level_filters => true }]
  end

  context 'with delayed method without arguments failing' do
    let(:expected_scope) do
      {
        :request => {
          'object' => {},
          'args' => [],
          'method_name' => 'do_job'
        }
      }
    end

    it 'sends the exception' do
      expect(Rollbar).to receive(:scope).with(expected_scope).and_call_original
      expect_any_instance_of(Rollbar::Notifier).to receive(:error).with(*expected_args)

      FailingJob.new.delay.do_job
    end
  end

  context 'with delayed method with arguments failing' do
    let(:expected_scope) do
      {
        :request => {
          'object' => {},
          'args' => ['foo', 'bar'],
          'method_name' => 'do_job_please!'
        }
      }
    end

    it 'sends the exception' do
      expect(Rollbar).to receive(:scope).with(expected_scope).and_call_original
      expect_any_instance_of(Rollbar::Notifier).to receive(:error).with(*expected_args)

      FailingJob.new.delay.do_job_please!(:foo, :bar)
    end
  end
end
