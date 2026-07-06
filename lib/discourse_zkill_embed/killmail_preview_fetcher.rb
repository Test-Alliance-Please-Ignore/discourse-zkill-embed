# frozen_string_literal: true

require "time"

module ::DiscourseZkillEmbed
  class KillmailPreviewFetcher
    def initialize(client: HttpClient.new, cache: DiscourseZkillEmbed.cache)
      @client = client
      @cache = cache
    end

    def fetch(kill_id)
      normalized_kill_id = normalize_positive_integer(kill_id)
      return nil unless normalized_kill_id

      key = cache_key(normalized_kill_id)
      cached = @cache.read(key)
      if cached
        return cached[:preview] if cached[:status] == :ok
        return nil if cached[:status] == :missing
      end

      preview = load_preview(normalized_kill_id)
      if preview
        @cache.write(
          key,
          { status: :ok, preview: preview },
          expires_in: DiscourseZkillEmbed.success_cache_ttl_seconds,
        )
      else
        @cache.write(
          key,
          { status: :missing },
          expires_in: DiscourseZkillEmbed::FAILURE_CACHE_TTL_SECONDS,
        )
      end

      preview
    rescue StandardError => e
      DiscourseZkillEmbed.log(:warn, "preview fetch failed for kill #{kill_id}: #{e.class}: #{e.message}")
      nil
    end

    private

    def load_preview(kill_id)
      payload = @client.get_json(format(DiscourseZkillEmbed::ZKILLBOARD_API_URL_TEMPLATE, kill_id: kill_id))
      return nil unless payload.is_a?(Array) && payload.first.is_a?(Hash)

      killmail = payload.first
      names = resolve_names(killmail)
      build_preview(kill_id, killmail, names)
    end

    def resolve_names(killmail)
      ids = []
      victim = hash_value(killmail["victim"])
      final_blow = Array(killmail["attackers"]).find { |attacker| attacker["final_blow"] }

      ids << normalize_positive_integer(killmail["solar_system_id"])
      ids << normalize_positive_integer(victim["ship_type_id"])
      ids << normalize_positive_integer(victim["character_id"])
      ids << normalize_positive_integer(victim["corporation_id"])
      ids << normalize_positive_integer(victim["alliance_id"])
      ids << normalize_positive_integer(final_blow && final_blow["character_id"])
      ids << normalize_positive_integer(final_blow && final_blow["corporation_id"])
      ids << normalize_positive_integer(final_blow && final_blow["alliance_id"])
      ids.compact!
      ids.uniq!

      return {} if ids.empty?

      response = @client.post_json(DiscourseZkillEmbed::ESI_NAMES_URL, ids)
      return {} unless response.is_a?(Array)

      response.each_with_object({}) do |row, memo|
        next unless row.is_a?(Hash)

        row_id = normalize_positive_integer(row["id"])
        row_name = row["name"]
        next unless row_id && row_name.is_a?(String)

        memo[row_id] = row_name
      end
    end

    def build_preview(kill_id, killmail, names)
      victim = hash_value(killmail["victim"])
      final_blow = hash_value(Array(killmail["attackers"]).find { |attacker| attacker["final_blow"] })
      zkb = hash_value(killmail["zkb"])
      ship_type_id = normalize_positive_integer(victim["ship_type_id"])
      solar_system_id = normalize_positive_integer(killmail["solar_system_id"])
      victim_character_id = normalize_positive_integer(victim["character_id"])
      victim_corporation_id = normalize_positive_integer(victim["corporation_id"])
      victim_alliance_id = normalize_positive_integer(victim["alliance_id"])
      final_blow_character_id = normalize_positive_integer(final_blow["character_id"])
      final_blow_corporation_id = normalize_positive_integer(final_blow["corporation_id"])
      final_blow_alliance_id = normalize_positive_integer(final_blow["alliance_id"])

      {
        kill_id: kill_id,
        killmail_url: canonical_killmail_url(kill_id),
        ship_type_id: ship_type_id,
        ship_type_name: names[ship_type_id],
        victim_character_id: victim_character_id,
        victim_name: names[victim_character_id],
        victim_corporation_id: victim_corporation_id,
        victim_corporation_name: names[victim_corporation_id],
        victim_alliance_id: victim_alliance_id,
        victim_alliance_name: names[victim_alliance_id],
        final_blow_character_id: final_blow_character_id,
        final_blow_name: names[final_blow_character_id],
        final_blow_corporation_id: final_blow_corporation_id,
        final_blow_corporation_name: names[final_blow_corporation_id],
        final_blow_alliance_id: final_blow_alliance_id,
        final_blow_alliance_name: names[final_blow_alliance_id],
        solar_system_id: solar_system_id,
        solar_system_name: names[solar_system_id],
        killmail_time: format_killmail_time(killmail["killmail_time"]),
        total_value: zkb["totalValue"],
        total_value_display: format_isk(zkb["totalValue"]),
        image_url: image_url_for(ship_type_id),
      }
    end

    def canonical_killmail_url(kill_id)
      "https://zkillboard.com/kill/#{kill_id}/"
    end

    def cache_key(kill_id)
      DiscourseZkillEmbed.killmail_preview_cache_key(kill_id)
    end

    def image_url_for(type_id)
      return nil unless type_id

      "https://#{DiscourseZkillEmbed::IMAGE_HOST}/types/#{type_id}/render?size=128"
    end

    def format_killmail_time(raw_time)
      return nil unless raw_time.is_a?(String)

      Time.iso8601(raw_time).utc.strftime("%Y-%m-%d %H:%M UTC")
    rescue ArgumentError
      nil
    end

    def format_isk(value)
      numeric_value = Float(value)
      absolute_value = numeric_value.abs

      [
        ["T", 1_000_000_000_000.0],
        ["B", 1_000_000_000.0],
        ["M", 1_000_000.0],
        ["K", 1_000.0],
      ].each do |suffix, divisor|
        next if absolute_value < divisor

        return format("%.2f%s ISK", numeric_value / divisor, suffix)
      end

      format("%.2f ISK", numeric_value)
    rescue ArgumentError, TypeError
      nil
    end

    def normalize_positive_integer(value)
      DiscourseZkillEmbed.normalize_positive_integer(value)
    end

    def hash_value(value)
      value.is_a?(Hash) ? value : {}
    end
  end
end
