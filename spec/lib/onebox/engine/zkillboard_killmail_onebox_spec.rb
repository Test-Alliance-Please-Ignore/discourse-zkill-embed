# frozen_string_literal: true

require_relative "../../../spec_helper"

describe Onebox::Engine::ZKillboardKillmailOnebox do
  it "uses the strict matcher" do
    _(Onebox::Engine::ZKillboardKillmailOnebox.matcher.match("https://zkillboard.com/kill/136795801/")).wont_be_nil
    _(Onebox::Engine::ZKillboardKillmailOnebox.matcher.match("https://zkillboard.com.evil.tld/kill/136795801/")).must_be_nil
  end

  it "returns rendered HTML when preview data is available" do
    preview = { kill_id: 1, killmail_url: "https://zkillboard.com/kill/1/" }
    fetcher = Minitest::Mock.new
    fetcher.expect(:fetch, preview, [1])
    fetcher_class = Class.new { define_method(:initialize) { } }
    fetcher_class.define_singleton_method(:new) { fetcher }

    renderer = Minitest::Mock.new
    renderer.expect(:render, "<aside>ok</aside>")
    renderer_class = Class.new { define_method(:initialize) { |_preview| } }
    renderer_class.define_singleton_method(:new) { |_preview| renderer }

    html =
      Onebox::Engine::ZKillboardKillmailOnebox.stub(:fetcher_class, fetcher_class) do
        Onebox::Engine::ZKillboardKillmailOnebox.stub(:renderer_class, renderer_class) do
          Onebox::Engine::ZKillboardKillmailOnebox.new("https://zkillboard.com/kill/1/").to_html
        end
      end

    _(html).must_equal "<aside>ok</aside>"
    fetcher.verify
    renderer.verify
  end

  it "falls back gracefully when preview data cannot be fetched" do
    fetcher = Minitest::Mock.new
    fetcher.expect(:fetch, nil, [1])
    fetcher_class = Class.new { define_method(:initialize) { } }
    fetcher_class.define_singleton_method(:new) { fetcher }

    html =
      Onebox::Engine::ZKillboardKillmailOnebox.stub(:fetcher_class, fetcher_class) do
        Onebox::Engine::ZKillboardKillmailOnebox.new("https://zkillboard.com/kill/1/").to_html
      end

    _(html).must_equal ""
    fetcher.verify
  end
end
