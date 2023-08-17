# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

# Required to execute Delayed Jobs
require_relative '../lib/import_archive_job.rb'

