# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

# This needs to be defined before Rails is initialized
RUN_SYSTEM_SPECS = ENV.fetch('RUN_SYSTEM_SPECS', false)

if RUN_SYSTEM_SPECS
  STREAMING_PORT = ENV.fetch('TEST_STREAMING_PORT', '4020')
  ENV['STREAMING_API_BASE_URL'] = "http://localhost:#{STREAMING_PORT}"
end

require File.expand_path('../config/environment', __dir__)

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'spec_helper'
require 'rspec/rails'
require 'webmock/rspec'
require 'paperclip/matchers'
require 'capybara/rspec'
require 'chewy/rspec'
require 'email_spec/rspec'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!
WebMock.disable_net_connect!(allow: Chewy.settings[:host], allow_localhost: RUN_SYSTEM_SPECS)
Sidekiq.logger = nil

# System tests config
DatabaseCleaner.strategy = [:deletion]

Devise::Test::ControllerHelpers.module_eval do
  alias_method :original_sign_in, :sign_in

  def sign_in(resource, _deprecated = nil, scope: nil)
    original_sign_in(resource, scope: scope)

    SessionActivation.deactivate warden.cookies.signed['_session_id']

    warden.cookies.signed['_session_id'] = {
      value: resource.activate_session(warden.request),
      expires: 1.year.from_now,
      httponly: true,
    }
  end
end

RSpec.configure do |config|
  # This is set before running spec:system, see lib/tasks/tests.rake
  config.filter_run_excluding type: lambda { |type|
    case type
    when :system
      !RUN_SYSTEM_SPECS
    end
  }

  # By default, skip the elastic search integration specs
  config.filter_run_excluding search: true

  config.fixture_paths = [
    Rails.root.join('spec', 'fixtures'),
  ]
  config.use_transactional_fixtures = true
  config.order = 'random'
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Set type to `cli` for all CLI specs
  config.define_derived_metadata(file_path: Regexp.new('spec/lib/mastodon/cli')) do |metadata|
    metadata[:type] = :cli
  end

  # Set `search` metadata true for all specs in spec/search/
  config.define_derived_metadata(file_path: Regexp.new('spec/search/*')) do |metadata|
    metadata[:search] = true
  end

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :helper
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Paperclip::Shoulda::Matchers
  config.include ActiveSupport::Testing::TimeHelpers
  config.include Chewy::Rspec::Helpers
  config.include Redisable
  config.include SignedRequestHelpers, type: :request
  config.include CommandLineHelpers, type: :cli

  config.around(:each, use_transactional_tests: false) do |example|
    self.use_transactional_tests = false
    example.run
    self.use_transactional_tests = true
  end

  config.around(:each, :sidekiq_inline) do |example|
    Sidekiq::Testing.inline!(&example)
  end

  config.before :each, type: :cli do
    stub_reset_connection_pools
  end

  config.before :each, type: :feature do
    Capybara.current_driver = :rack_test
  end

  config.before do |example|
    allow(Resolv::DNS).to receive(:open).and_raise('Real DNS queries are disabled, stub Resolv::DNS as needed') unless example.metadata[:type] == :system
  end

  config.before do |example|
    unless example.metadata[:paperclip_processing]
      allow_any_instance_of(Paperclip::Attachment).to receive(:post_process).and_return(true) # rubocop:disable RSpec/AnyInstance
    end
  end

  config.after do
    Rails.cache.clear
    redis.del(redis.keys)
  end

  # Assign types based on dir name for non-inferred types
  config.define_derived_metadata(file_path: %r{/spec/}) do |metadata|
    unless metadata.key?(:type)
      match = metadata[:location].match(%r{/spec/([^/]+)/})
      metadata[:type] = match[1].singularize.to_sym
    end
  end
end

RSpec::Sidekiq.configure do |config|
  config.warn_when_jobs_not_processed_by_sidekiq = false
end

RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_include, :include

def request_fixture(name)
  Rails.root.join('spec', 'fixtures', 'requests', name).read
end

def attachment_fixture(name)
  Rails.root.join('spec', 'fixtures', 'files', name).open
end

def stub_reset_connection_pools
  # TODO: Is there a better way to correctly run specs without stubbing this?
  # (Avoids reset_connection_pools! in test env)
  allow(ActiveRecord::Base).to receive(:establish_connection)
  allow(RedisConfiguration).to receive(:establish_pool)
end
