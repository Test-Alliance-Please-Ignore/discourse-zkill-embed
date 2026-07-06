# frozen_string_literal: true

module Onebox
  module Engine
    class ZKillboardKillmailOnebox
      include ::Onebox::Engine

      always_https
      matches_regexp(DiscourseZkillEmbed::UrlMatcher::URL_REGEXP)

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
        return "" unless DiscourseZkillEmbed.enabled?

        kill_id = self.class.extract_kill_id(@url)
        return "" unless kill_id

        preview = self.class.fetcher_class.new.fetch(kill_id)
        return "" unless preview

        self.class.renderer_class.new(preview).render
      rescue StandardError => e
        DiscourseZkillEmbed.log(:warn, "onebox render failed for #{@url}: #{e.class}: #{e.message}")
        ""
      end
    end
  end
end
