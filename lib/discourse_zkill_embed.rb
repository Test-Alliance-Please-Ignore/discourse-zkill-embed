# frozen_string_literal: true

require "logger"

module ::DiscourseZkillEmbed
  PLUGIN_NAME = "discourse-zkill-embed"
  PLUGIN_VERSION = "0.1.0"
  ZKILLBOARD_API_HOST = "zkillboard.com"
  ZKILLBOARD_API_URL_TEMPLATE = "https://zkillboard.com/api/killID/%<kill_id>d/"
  ESI_HOST = "esi.evetech.net"
  ESI_NAMES_URL = "https://esi.evetech.net/latest/universe/names/?datasource=tranquility"
  IMAGE_HOST = "images.evetech.net"
  FAILURE_CACHE_TTL_SECONDS = 10 * 60

  def self.enabled?
    !!site_setting(:zkillboard_onebox_enabled, true)
  end

  def self.show_ship_image?
    !!site_setting(:zkillboard_onebox_show_ship_image, true)
  end

  def self.request_timeout_seconds
    seconds = site_setting(:zkillboard_onebox_request_timeout_seconds, 5).to_i
    [[seconds, 1].max, 15].min
  end

  def self.success_cache_ttl_seconds
    hours = site_setting(:zkillboard_onebox_cache_ttl_hours, 12).to_i
    [[hours, 1].max, 24].min * 3600
  end

  def self.user_agent
    host =
      if defined?(GlobalSetting) && GlobalSetting.respond_to?(:hostname)
        GlobalSetting.hostname
      end
    host = "unknown-host" if host.nil? || host.empty?

    "#{PLUGIN_NAME}/#{PLUGIN_VERSION} (#{host})"
  end

  def self.cache
    Discourse.cache
  end

  def self.logger
    if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
      Rails.logger
    else
      @logger ||= Logger.new($stdout)
    end
  end

  def self.log(level, message)
    logger.public_send(level, "[#{PLUGIN_NAME}] #{message}")
  rescue StandardError
    nil
  end

  def self.site_setting(name, default)
    return default unless defined?(SiteSetting) && SiteSetting.respond_to?(name)

    SiteSetting.public_send(name)
  rescue StandardError
    default
  end
end
