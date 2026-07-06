# frozen_string_literal: true

require "erb"

module ::DiscourseZkillEmbed
  class HtmlRenderer
    include ERB::Util

    def initialize(preview, show_ship_image: DiscourseZkillEmbed.show_ship_image?)
      @preview = preview || {}
      @show_ship_image = show_ship_image
    end

    def render
      return "" if @preview.empty?

      <<~HTML
        <aside
          class="onebox zkillboard-killmail-onebox"
          data-onebox-src="#{h(@preview[:killmail_url].to_s)}"
          data-kill-id="#{h(@preview[:kill_id].to_s)}"
        >
          #{image_html}
          <div class="zkillboard-killmail-onebox__content">
            <div class="zkillboard-killmail-onebox__header">
              <p class="zkillboard-killmail-onebox__eyebrow">EVE Online killmail</p>
              <p class="zkillboard-killmail-onebox__source">zKillboard</p>
            </div>
            <h3 class="zkillboard-killmail-onebox__title">#{h(title_text)}</h3>
            <p class="zkillboard-killmail-onebox__subtitle">#{h(victim_text)}</p>
            #{facts_html}
            #{final_blow_html}
            <div class="zkillboard-killmail-onebox__footer">
              <a href="#{h(@preview[:killmail_url].to_s)}">View on zKillboard</a>
            </div>
          </div>
        </aside>
      HTML
    end

    private

    def image_html
      return "" unless @show_ship_image

      image_url = @preview[:image_url]
      return "" if image_url.nil? || image_url.empty?

      <<~HTML
        <div class="zkillboard-killmail-onebox__image">
          <img src="#{h(image_url)}" alt="#{h(title_text)}" loading="lazy">
        </div>
      HTML
    end

    def final_blow_html
      text = final_blow_text
      return "" if text.nil? || text.empty?

      <<~HTML
        <div class="zkillboard-killmail-onebox__final-blow">
          <p class="zkillboard-killmail-onebox__detail-label">Final blow</p>
          <p class="zkillboard-killmail-onebox__detail-text">#{h(text)}</p>
        </div>
      HTML
    end

    def title_text
      ship_name = @preview[:ship_type_name]
      ship_name = "Unknown ship" if ship_name.nil? || ship_name.empty?
      "#{ship_name} destroyed"
    end

    def victim_text
      text = join_present(@preview[:victim_name], @preview[:victim_corporation_name], @preview[:victim_alliance_name])
      return text unless text.empty?

      "Victim details unavailable"
    end

    def facts_html
      facts = []
      facts << fact_html("System", @preview[:solar_system_name])
      facts << fact_html("Time", @preview[:killmail_time])
      facts << fact_html("Value", @preview[:total_value_display])
      facts.compact!

      return "" if facts.empty?

      <<~HTML
        <div class="zkillboard-killmail-onebox__facts">
          #{facts.join("\n")}
        </div>
      HTML
    end

    def final_blow_text
      join_present(
        @preview[:final_blow_name],
        @preview[:final_blow_corporation_name],
        @preview[:final_blow_alliance_name],
      )
    end

    def join_present(*values, separator: " / ")
      values.flatten.compact.map(&:to_s).map(&:strip).reject(&:empty?).join(separator)
    end

    def fact_html(label, value)
      return nil if value.nil? || value.to_s.strip.empty?

      <<~HTML
        <div class="zkillboard-killmail-onebox__fact">
          <p class="zkillboard-killmail-onebox__detail-label">#{h(label)}</p>
          <p class="zkillboard-killmail-onebox__detail-text">#{h(value)}</p>
        </div>
      HTML
    end
  end
end
