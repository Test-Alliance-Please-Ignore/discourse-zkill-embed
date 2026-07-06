# frozen_string_literal: true

require_relative "../../spec_helper"

describe DiscourseZkillEmbed::HtmlRenderer do
  it "renders the expected killmail fields and link" do
    preview = {
      kill_id: 136795801,
      killmail_url: "https://zkillboard.com/kill/136795801/",
      ship_type_name: "Cybele",
      victim_character_id: 2113483277,
      victim_name: "Trumps Bloodthirst Feynman",
      victim_corporation_id: 98540583,
      victim_corporation_name: "Special law enforcement department",
      victim_alliance_id: 99003581,
      victim_alliance_name: "Fraternity.",
      final_blow_character_id: 2114631197,
      final_blow_name: "Chris Martinn",
      final_blow_corporation_id: 98557229,
      final_blow_corporation_name: "Outback Steakhouse of Pancakes",
      final_blow_alliance_id: 99004901,
      final_blow_alliance_name: "Snuffed Out",
      solar_system_id: 30000240,
      solar_system_name: "4-HWWF",
      killmail_time: "2026-07-05 13:15 UTC",
      total_value_display: "240.67B ISK",
      image_url: "https://images.evetech.net/types/77726/render?size=128",
    }

    html = DiscourseZkillEmbed::HtmlRenderer.new(preview).render

    _(html).must_include "Cybele destroyed"
    _(html).must_include "href=\"https://zkillboard.com/character/2113483277/\""
    _(html).must_include "href=\"https://zkillboard.com/corporation/98540583/\""
    _(html).must_include "href=\"https://zkillboard.com/alliance/99003581/\""
    _(html).must_include "href=\"https://zkillboard.com/system/30000240/\""
    _(html).must_include "href=\"https://zkillboard.com/character/2114631197/\""
    _(html).must_include "href=\"https://zkillboard.com/corporation/98557229/\""
    _(html).must_include "href=\"https://zkillboard.com/alliance/99004901/\""
    _(html).must_include "<a href=\"https://zkillboard.com/kill/136795801/\" aria-label=\"Cybele destroyed\">"
    _(html).must_include ">Trumps Bloodthirst Feynman</a>"
    _(html).must_include ">Special law enforcement department</a>"
    _(html).must_include ">Fraternity.</a>"
    _(html).must_include ">4-HWWF</a>"
    _(html).must_include "4-HWWF</a><span class=\"zkillboard-killmail-onebox__separator\"> | </span>2026-07-05 13:15 UTC"
    _(html).must_include "2026-07-05 13:15 UTC<span class=\"zkillboard-killmail-onebox__separator\"> | </span>240.67B ISK"
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
      victim_character_id: 55,
      victim_name: "<img src=x onerror=alert(1)>",
      victim_corporation_id: 56,
      victim_corporation_name: "Corp",
      victim_alliance_id: 57,
      victim_alliance_name: "Alliance",
      final_blow_character_id: 58,
      final_blow_name: "<b>Bad</b>",
      solar_system_id: 59,
      solar_system_name: "Jita",
      killmail_time: "2026-07-05 13:15 UTC",
      total_value_display: "1.00 ISK",
      image_url: "https://images.evetech.net/types/587/render?size=128",
    }

    html = DiscourseZkillEmbed::HtmlRenderer.new(preview).render

    _(html).wont_include "<script>"
    _(html).wont_include "<img src=x onerror=alert(1)>"
    _(html).wont_include "<b>Bad</b>"
    _(html).must_include "href=\"https://zkillboard.com/character/55/\""
    _(html).must_include "href=\"https://zkillboard.com/character/58/\""
    _(html).must_include "&lt;script&gt;alert(1)&lt;/script&gt;"
    _(html).must_include "&lt;img src=x onerror=alert(1)&gt;"
    _(html).must_include "&lt;b&gt;Bad&lt;/b&gt;"
  end

  it "renders a useful card when optional fields are missing" do
    preview = {
      kill_id: 42,
      killmail_url: "https://zkillboard.com/kill/42/",
      ship_type_name: "Rifter",
      victim_corporation_id: 98540583,
      victim_corporation_name: "Victim Corp",
      solar_system_id: 30000142,
      solar_system_name: "Jita",
      killmail_time: "2026-07-05 13:15 UTC",
    }

    html = DiscourseZkillEmbed::HtmlRenderer.new(preview, show_ship_image: false).render

    _(html).must_include "Rifter destroyed"
    _(html).must_include "href=\"https://zkillboard.com/corporation/98540583/\""
    _(html).must_include ">Victim Corp</a>"
    _(html).must_include "href=\"https://zkillboard.com/system/30000142/\""
    _(html).must_include ">Jita</a><span class=\"zkillboard-killmail-onebox__separator\"> | </span>2026-07-05 13:15 UTC"
    _(html).wont_include "Final blow:"
  end
end
