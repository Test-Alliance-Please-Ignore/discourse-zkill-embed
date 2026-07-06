# frozen_string_literal: true

module ::DiscourseZkillEmbed
  class CookedPostProcessor
    def process(doc)
      return if doc.nil? || !DiscourseZkillEmbed.enabled?

      replace_generic_oneboxes(doc)
      augment_matching_links(doc)
    rescue StandardError => e
      DiscourseZkillEmbed.log(:warn, "cooked post processing failed: #{e.class}: #{e.message}")
    end

    private

    def replace_generic_oneboxes(doc)
      doc.css("aside.onebox[data-onebox-src]").to_a.each do |aside|
        next if aside["class"].to_s.split.include?("zkillboard-killmail-onebox")

        url = aside["data-onebox-src"].to_s
        next unless UrlMatcher.match?(url)

        html = DiscourseZkillEmbed.render_for_url(url)
        next if html.empty?

        aside.replace(html)
      end
    end

    def augment_matching_links(doc)
      doc.css("a[href]").to_a.each do |link|
        next unless eligible_link?(link)

        url = link["href"].to_s
        next unless UrlMatcher.match?(url)

        html = DiscourseZkillEmbed.render_for_url(url)
        next if html.empty?

        insert_rendered_onebox(link, html)
      end
    end

    def eligible_link?(link)
      return false if link["href"].to_s.empty?
      return false if ancestor_named?(link, "aside", "quote")
      return false if ancestor_named?(link, "aside", "zkillboard-killmail-onebox")

      true
    end

    def insert_rendered_onebox(link, html)
      parent = link.parent

      if standalone_link_paragraph?(parent, link)
        parent.replace(html)
      elsif parent&.name == "p"
        return if following_zkill_onebox?(parent, link["href"])

        parent.add_next_sibling(html)
      else
        link.replace(html)
      end
    end

    def standalone_link_paragraph?(parent, link)
      return false unless parent&.name == "p"

      significant_children =
        parent.children.reject do |child|
          child.text? && child.text.strip.empty?
        end

      significant_children.length == 1 && significant_children.first == link
    end

    def following_zkill_onebox?(paragraph, href)
      sibling = paragraph.next_sibling
      while sibling && sibling.text? && sibling.text.strip.empty?
        sibling = sibling.next_sibling
      end

      return false unless sibling&.element?
      return false unless sibling.name == "aside"

      classes = sibling["class"].to_s.split
      classes.include?("zkillboard-killmail-onebox") && sibling["data-onebox-src"] == href
    end

    def ancestor_named?(node, element_name, class_name)
      current = node.parent
      while current
        if current.element? && current.name == element_name
          classes = current["class"].to_s.split
          return true if classes.include?(class_name)
        end
        current = current.parent
      end

      false
    end
  end
end
