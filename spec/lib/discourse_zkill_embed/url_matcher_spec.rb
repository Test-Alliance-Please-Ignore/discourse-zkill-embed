# frozen_string_literal: true

require_relative "../../spec_helper"

describe DiscourseZkillEmbed::UrlMatcher do
  it "accepts valid zKillboard killmail URLs" do
    urls = [
      "https://zkillboard.com/kill/136795801/",
      "http://zkillboard.com/kill/136795801/",
      "https://www.zkillboard.com/kill/136795801/",
      "http://www.zkillboard.com/kill/136795801/",
    ]

    urls.each do |url|
      _(DiscourseZkillEmbed::UrlMatcher.match?(url)).must_equal true
    end
  end

  it "rejects malformed or lookalike URLs" do
    urls = [
      "https://zkillboard.com/kill/abc/",
      "https://zkillboard.com/character/136795801/",
      "https://zkillboard.com/kill/136795801",
      "https://zkillboard.com/kill/136795801/?foo=bar",
      "https://zkillboard.com.evil.tld/kill/136795801/",
      "https://example.com/kill/136795801/",
    ]

    urls.each do |url|
      _(DiscourseZkillEmbed::UrlMatcher.match?(url)).must_equal false
    end
  end

  it "extracts the numeric kill ID" do
    _(DiscourseZkillEmbed::UrlMatcher.extract_kill_id("https://zkillboard.com/kill/136795801/")).must_equal 136795801
    _(DiscourseZkillEmbed::UrlMatcher.extract_kill_id("https://zkillboard.com/kill/not-a-number/")).must_be_nil
  end
end
