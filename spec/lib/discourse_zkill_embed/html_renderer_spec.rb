# frozen_string_literal: true

require_relative "../../spec_helper"

describe DiscourseZkillEmbed::HtmlRenderer do
  it "renders the expected killmail fields and link" do
    preview = {
      kill_id: 136795801,
      killmail_url: "https://zkillboard.com/kill/136795801/",
      ship_type_name: "Cybele",
      victim_name: "Trumps Bloodthirst Feynman",
      victim_corporation_name: "Special law enforcement department",
      victim_alliance_name: "Fraternity.",
      final_blow_name: "Chris Martinn",
      final_blow_corporation_name: "Outback Steakhouse of Pancakes",
      final_blow_alliance_name: "Snuffed Out",
      solar_system_name: "4-HWWF",
      killmail_time: "2026-07-05 13:15 UTC",
      total_value_display: "240.67B ISK",
      image_url: "https://images.evetech.net/types/77726/render?size=128",
    }

    html = DiscourseZkillEmbed::HtmlRenderer.new(preview).render

    _(html).must_include "Cybele destroyed"
    _(html).must_include "Trumps Bloodthirst Feynman / Special law enforcement department / Fraternity."
    _(html).must_include "4-HWWF | 2026-07-05 13:15 UTC | 240.67B ISK"
    _(html).must_include "Final blow:"
    _(html).must_include "View on zKillboard"
    _(html).must_include "https://zkillboard.com/kill/136795801/"
    _(html).must_include "data-onebox-src=\"https://zkillboard.com/kill/136795801/\""
  end

  it "escapes remote text fields" do
    preview = {
      kill_id: 7,
      killmail_url: "https://zkillboard.com/kill/7/",
      ship_type_name: "<script>alert(1)</script>",
      victim_name: "<img src=x onerror=alert(1)>",
      victim_corporation_name: "Corp",
      victim_alliance_name: "Alliance",
      final_blow_name: "<b>Bad</b>",
      solar_system_name: "Jita",
      killmail_time: "2026-07-05 13:15 UTC",
      total_value_display: "1.00 ISK",
      image_url: "https://images.evetech.net/types/587/render?size=128",
    }

    html = DiscourseZkillEmbed::HtmlRenderer.new(preview).render

    _(html).wont_include "<script>"
    _(html).wont_include "<img src=x onerror=alert(1)>"
    _(html).wont_include "<b>Bad</b>"
    _(html).must_include "&lt;script&gt;alert(1)&lt;/script&gt;"
    _(html).must_include "&lt;img src=x onerror=alert(1)&gt;"
    _(html).must_include "&lt;b&gt;Bad&lt;/b&gt;"
  end

  it "renders a useful card when optional fields are missing" do
    preview = {
      kill_id: 42,
      killmail_url: "https://zkillboard.com/kill/42/",
      ship_type_name: "Rifter",
      victim_corporation_name: "Victim Corp",
      solar_system_name: "Jita",
      killmail_time: "2026-07-05 13:15 UTC",
    }

    html = DiscourseZkillEmbed::HtmlRenderer.new(preview, show_ship_image: false).render

    _(html).must_include "Rifter destroyed"
    _(html).must_include "Victim Corp"
    _(html).must_include "Jita | 2026-07-05 13:15 UTC"
    _(html).wont_include "Final blow:"
  end
end
