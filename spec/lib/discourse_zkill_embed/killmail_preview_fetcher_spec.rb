# frozen_string_literal: true

require_relative "../../spec_helper"

class FakeHttpClient
  attr_reader :get_json_calls, :post_json_calls

  def initialize(get_json_response:, post_json_response:)
    @get_json_response = get_json_response
    @post_json_response = post_json_response
    @get_json_calls = 0
    @post_json_calls = 0
  end

  def get_json(_url)
    @get_json_calls += 1
    @get_json_response
  end

  def post_json(_url, _payload)
    @post_json_calls += 1
    @post_json_response
  end
end

describe DiscourseZkillEmbed::KillmailPreviewFetcher do
  it "parses a representative killmail fixture" do
    client =
      FakeHttpClient.new(
        get_json_response: SpecSupport.fixture_json("zkillboard_killmail.json"),
        post_json_response: SpecSupport.fixture_json("esi_names.json"),
      )

    preview = DiscourseZkillEmbed::KillmailPreviewFetcher.new(client: client, cache: Discourse.cache).fetch(136795801)

    _(preview[:ship_type_name]).must_equal "Cybele"
    _(preview[:victim_character_id]).must_equal 2113483277
    _(preview[:victim_name]).must_equal "Trumps Bloodthirst Feynman"
    _(preview[:victim_corporation_id]).must_equal 98540583
    _(preview[:victim_corporation_name]).must_equal "Special law enforcement department"
    _(preview[:victim_alliance_id]).must_equal 99003581
    _(preview[:victim_alliance_name]).must_equal "Fraternity."
    _(preview[:final_blow_character_id]).must_equal 2114631197
    _(preview[:final_blow_name]).must_equal "Chris Martinn"
    _(preview[:final_blow_corporation_id]).must_equal 98557229
    _(preview[:final_blow_corporation_name]).must_equal "Outback Steakhouse of Pancakes"
    _(preview[:final_blow_alliance_id]).must_equal 99004901
    _(preview[:final_blow_alliance_name]).must_equal "Snuffed Out"
    _(preview[:solar_system_id]).must_equal 30000240
    _(preview[:solar_system_name]).must_equal "4-HWWF"
    _(preview[:killmail_time]).must_equal "2026-07-05 13:15 UTC"
    _(preview[:total_value_display]).must_equal "240.67B ISK"
    _(preview[:killmail_url]).must_equal "https://zkillboard.com/kill/136795801/"
    _(preview[:image_url]).must_equal "https://images.evetech.net/types/77726/render?size=128"
  end

  it "handles missing optional fields without crashing" do
    client =
      FakeHttpClient.new(
        get_json_response: SpecSupport.fixture_json("zkillboard_killmail_missing_fields.json"),
        post_json_response: SpecSupport.fixture_json("esi_names_missing_fields.json"),
      )

    preview = DiscourseZkillEmbed::KillmailPreviewFetcher.new(client: client, cache: Discourse.cache).fetch(42)

    _(preview[:ship_type_name]).must_equal "Rifter"
    _(preview[:victim_name]).must_be_nil
    _(preview[:victim_corporation_id]).must_equal 98540583
    _(preview[:victim_corporation_name]).must_equal "Victim Corp"
    _(preview[:victim_alliance_name]).must_be_nil
    _(preview[:final_blow_name]).must_be_nil
    _(preview[:final_blow_corporation_id]).must_equal 98557229
    _(preview[:final_blow_corporation_name]).must_equal "Final Blow Corp"
    _(preview[:solar_system_id]).must_equal 30000142
    _(preview[:total_value_display]).must_be_nil
  end

  it "uses cache instead of repeating upstream requests" do
    client =
      FakeHttpClient.new(
        get_json_response: SpecSupport.fixture_json("zkillboard_killmail.json"),
        post_json_response: SpecSupport.fixture_json("esi_names.json"),
      )

    fetcher = DiscourseZkillEmbed::KillmailPreviewFetcher.new(client: client, cache: Discourse.cache)
    first = fetcher.fetch(136795801)
    second = fetcher.fetch(136795801)

    _(first).must_equal second
    _(client.get_json_calls).must_equal 1
    _(client.post_json_calls).must_equal 1
  end

  it "stores previews under a versioned cache key" do
    client =
      FakeHttpClient.new(
        get_json_response: SpecSupport.fixture_json("zkillboard_killmail.json"),
        post_json_response: SpecSupport.fixture_json("esi_names.json"),
      )

    fetcher = DiscourseZkillEmbed::KillmailPreviewFetcher.new(client: client, cache: Discourse.cache)
    fetcher.fetch(136795801)

    expected_key = DiscourseZkillEmbed.killmail_preview_cache_key(136795801)

    _(expected_key).must_equal(
      "discourse-zkill-embed:killmail-preview:v#{DiscourseZkillEmbed::KILLMAIL_PREVIEW_CACHE_VERSION}:136795801",
    )
    _(Discourse.cache.store.keys).must_include expected_key
  end

  it "negative-caches failed requests" do
    client = FakeHttpClient.new(get_json_response: nil, post_json_response: nil)
    fetcher = DiscourseZkillEmbed::KillmailPreviewFetcher.new(client: client, cache: Discourse.cache)

    _(fetcher.fetch(136795801)).must_be_nil
    _(fetcher.fetch(136795801)).must_be_nil
    _(client.get_json_calls).must_equal 1
    _(client.post_json_calls).must_equal 0
  end
end
