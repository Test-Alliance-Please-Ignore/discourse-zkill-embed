# frozen_string_literal: true

module Onebox
  module Engine
    class ZKillboardKillmailOnebox
      include ::Onebox::Engine

      always_https
      matches_regexp(DiscourseZkillEmbed::UrlMatcher::URL_REGEXP)

      def self.priority
        10
      end

      def self.fetcher_class
        DiscourseZkillEmbed::KillmailPreviewFetcher
      end

      def self.renderer_class
        DiscourseZkillEmbed::HtmlRenderer
      end

      def self.extract_kill_id(url)
        DiscourseZkillEmbed::UrlMatcher.extract_kill_id(url)
      end

      def to_html
        DiscourseZkillEmbed.render_for_url(
          @url,
          fetcher: self.class.fetcher_class.new,
          renderer_class: self.class.renderer_class,
        )
      rescue StandardError => e
        DiscourseZkillEmbed.log(:warn, "onebox render failed for #{@url}: #{e.class}: #{e.message}")
        ""
      end
    end
  end
end
