ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

# Disable Chewy (Elasticsearch) in test environment
Chewy.strategy(:bypass)

# Suppress deprecation warnings. Rails 7.2 removed the class-level setter.
Rails.application.deprecators.behavior = :silence

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
