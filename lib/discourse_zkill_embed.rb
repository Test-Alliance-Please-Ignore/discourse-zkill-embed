# frozen_string_literal: true

require "logger"

module ::DiscourseZkillEmbed
  PLUGIN_NAME = "discourse-zkill-embed"
  PLUGIN_VERSION = "0.1.0"
  KILLMAIL_PREVIEW_CACHE_VERSION = 2
  ZKILLBOARD_API_HOST = "zkillboard.com"
  ZKILLBOARD_WEB_URL = "https://zkillboard.com"
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

  def self.render_for_url(url, fetcher: nil, renderer_class: nil, show_ship_image: nil)
    return "" unless enabled?

    fetcher ||= KillmailPreviewFetcher.new
    renderer_class ||= HtmlRenderer
    show_ship_image = show_ship_image? if show_ship_image.nil?

    kill_id = UrlMatcher.extract_kill_id(url)
    return "" unless kill_id

    preview = fetcher.fetch(kill_id)
    return "" unless preview

    renderer_class.new(preview, show_ship_image: show_ship_image).render
  rescue StandardError => e
    log(:warn, "render failed for #{url}: #{e.class}: #{e.message}")
    ""
  end

  def self.zkillboard_entity_url(entity_type, entity_id)
    normalized_id = normalize_positive_integer(entity_id)
    return nil unless normalized_id

    path_segment =
      case entity_type.to_sym
      when :system
        "system"
      when :character
        "character"
      when :corporation
        "corporation"
      when :alliance
        "alliance"
      end

    return nil if path_segment.nil?

    "#{ZKILLBOARD_WEB_URL}/#{path_segment}/#{normalized_id}/"
  end

  def self.killmail_preview_cache_key(kill_id)
    normalized_id = normalize_positive_integer(kill_id)
    return nil unless normalized_id

    "#{PLUGIN_NAME}:killmail-preview:v#{KILLMAIL_PREVIEW_CACHE_VERSION}:#{normalized_id}"
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

  def self.normalize_positive_integer(value)
    integer = value.is_a?(String) ? Integer(value, 10) : Integer(value)
    integer.positive? ? integer : nil
  rescue ArgumentError, TypeError
    nil
  end
end
