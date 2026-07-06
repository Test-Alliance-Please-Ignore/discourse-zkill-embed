# frozen_string_literal: true

module ::DiscourseZkillEmbed
  module UrlMatcher
    URL_REGEXP = %r{\Ahttps?://(?:www\.)?zkillboard\.com/kill/(?<kill_id>\d+)/\z}i.freeze

    def self.match(url)
      return nil if url.nil?

      URL_REGEXP.match(url)
    end

    def self.match?(url)
      !match(url).nil?
    end

    def self.extract_kill_id(url)
      matched = match(url)
      return nil unless matched

      matched["kill_id"].to_i
    end
  end
end
