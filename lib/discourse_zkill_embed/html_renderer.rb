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
            <p class="zkillboard-killmail-onebox__eyebrow">EVE Online killmail</p>
            <h3 class="zkillboard-killmail-onebox__title">#{h(title_text)}</h3>
            <p class="zkillboard-killmail-onebox__subtitle">#{victim_html}</p>
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
          <a href="#{h(@preview[:killmail_url].to_s)}" aria-label="#{h(title_text)}">
            <img src="#{h(image_url)}" alt="#{h(title_text)}" loading="lazy">
          </a>
        </div>
      HTML
    end

    def final_blow_html
      html = linked_entities_html(
        [
          [@preview[:final_blow_name], :character, @preview[:final_blow_character_id]],
          [@preview[:final_blow_corporation_name], :corporation, @preview[:final_blow_corporation_id]],
          [@preview[:final_blow_alliance_name], :alliance, @preview[:final_blow_alliance_id]],
        ],
      )
      return "" if html.empty?

      <<~HTML
        <p class="zkillboard-killmail-onebox__final-blow">
          <span class="zkillboard-killmail-onebox__label">Final blow:</span> #{html}
        </p>
      HTML
    end

    def title_text
      ship_name = @preview[:ship_type_name]
      ship_name = "Unknown ship" if ship_name.nil? || ship_name.empty?
      "#{ship_name} destroyed"
    end

    def victim_html
      html = linked_entities_html(
        [
          [@preview[:victim_name], :character, @preview[:victim_character_id]],
          [@preview[:victim_corporation_name], :corporation, @preview[:victim_corporation_id]],
          [@preview[:victim_alliance_name], :alliance, @preview[:victim_alliance_id]],
        ],
      )
      return html unless html.empty?

      h("Victim details unavailable")
    end

    def facts_html
      facts = []
      facts << meta_item_html("System", linked_value_html(@preview[:solar_system_name], :system, @preview[:solar_system_id]))
      facts << meta_item_html("Time", text_html(@preview[:killmail_time]))
      facts << meta_item_html("Value", text_html(@preview[:total_value_display]))
      facts.compact!

      return "" if facts.empty?

      %(<p class="zkillboard-killmail-onebox__meta">#{facts.join(%(<span class="zkillboard-killmail-onebox__separator"> | </span>))}</p>)
    end

    def meta_item_html(label, value_html)
      return nil if value_html.nil? || value_html.empty?

      %(<span class="zkillboard-killmail-onebox__meta-item"><span class="zkillboard-killmail-onebox__label">#{h(label)}:</span> #{value_html}</span>)
    end

    def linked_entities_html(entities, separator: " / ")
      parts =
        entities.filter_map do |name, entity_type, entity_id|
          next if blank_text?(name)

          linked_value_html(name, entity_type, entity_id)
        end

      parts.join(separator)
    end

    def linked_value_html(text, entity_type, entity_id)
      return nil if blank_text?(text)

      url = DiscourseZkillEmbed.zkillboard_entity_url(entity_type, entity_id)
      return text_html(text) if url.nil?

      %(<a href="#{h(url)}">#{h(text.to_s.strip)}</a>)
    end

    def text_html(text)
      return nil if blank_text?(text)

      h(text.to_s.strip)
    end

    def blank_text?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end
end
