# frozen_string_literal: true

require_relative "spec_helper"

Dir[File.expand_path("**/*_spec.rb", __dir__)].sort.each { |file| require file }
