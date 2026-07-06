# frozen_string_literal: true

require "json"
require "logger"
require "minitest/autorun"
require "minitest/spec"
require "time"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

module Onebox
  module Engine
    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(url, *_args)
      @url = url
    end

    module ClassMethods
      def matches_regexp(regexp)
        @matcher = regexp
      end

      def matcher
        @matcher
      end

      def always_https
        @always_https = true
      end
    end
  end
end

class TestCache
  attr_reader :store

  def initialize
    clear
  end

  def read(key)
    entry = @store[key]
    return nil unless entry
    return entry[:value] if entry[:expires_in].nil?

    age = Time.now - entry[:written_at]
    return entry[:value] if age < entry[:expires_in].to_i

    @store.delete(key)
    nil
  end

  def write(key, value, expires_in: nil)
    @store[key] = { value: value, expires_in: expires_in, written_at: Time.now }
  end

  def clear
    @store = {}
  end
end

module SiteSetting
  class << self
    attr_accessor :zkillboard_onebox_enabled
    attr_accessor :zkillboard_onebox_cache_ttl_hours
    attr_accessor :zkillboard_onebox_request_timeout_seconds
    attr_accessor :zkillboard_onebox_show_ship_image
  end
end

module Discourse
  class << self
    attr_accessor :cache
  end
end

module GlobalSetting
  class << self
    attr_accessor :hostname
  end
end

module Rails
  class << self
    attr_accessor :logger
  end
end

Discourse.cache = TestCache.new
GlobalSetting.hostname = "spec.example.com"
Rails.logger = Logger.new(nil)

module SpecSupport
  def self.reset_settings!
    SiteSetting.zkillboard_onebox_enabled = true
    SiteSetting.zkillboard_onebox_cache_ttl_hours = 12
    SiteSetting.zkillboard_onebox_request_timeout_seconds = 5
    SiteSetting.zkillboard_onebox_show_ship_image = true
  end

  def self.fixture_json(name)
    path = File.expand_path("fixtures/#{name}", __dir__)
    JSON.parse(File.read(path))
  end
end

SpecSupport.reset_settings!

class Minitest::Test
  def setup
    SpecSupport.reset_settings!
    Discourse.cache.clear
  end

  def fixture_json(name)
    SpecSupport.fixture_json(name)
  end
end

require "discourse_zkill_embed"
require "discourse_zkill_embed/url_matcher"
require "discourse_zkill_embed/http_client"
require "discourse_zkill_embed/killmail_preview_fetcher"
require "discourse_zkill_embed/html_renderer"
require "discourse_zkill_embed/cooked_post_processor"
require_relative "../lib/onebox/engine/zkillboard_killmail_onebox"
