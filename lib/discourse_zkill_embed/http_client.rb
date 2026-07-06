# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "uri"

module ::DiscourseZkillEmbed
  class HttpClient
    ALLOWED_HOSTS = {
      DiscourseZkillEmbed::ZKILLBOARD_API_HOST => "/api/",
      DiscourseZkillEmbed::ESI_HOST => "/latest/universe/names/",
    }.freeze

    def get_json(url)
      request_json(:get, url)
    end

    def post_json(url, payload)
      request_json(:post, url, payload)
    end

    private

    def request_json(method, url, payload = nil)
      uri = URI.parse(url)
      validate_uri!(uri)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = DiscourseZkillEmbed.request_timeout_seconds
      http.read_timeout = DiscourseZkillEmbed.request_timeout_seconds

      request = build_request(method, uri, payload)
      response = http.request(request)

      return nil if response.is_a?(Net::HTTPNotFound)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError,
           IOError,
           OpenSSL::SSL::SSLError,
           SocketError,
           SystemCallError,
           Timeout::Error,
           URI::InvalidURIError => e
      DiscourseZkillEmbed.log(:warn, "#{method.to_s.upcase} #{url} failed: #{e.class}: #{e.message}")
      nil
    end

    def build_request(method, uri, payload)
      headers = {
        "Accept" => "application/json",
        "User-Agent" => DiscourseZkillEmbed.user_agent,
      }

      request =
        case method
        when :get
          Net::HTTP::Get.new(uri.request_uri, headers)
        when :post
          Net::HTTP::Post.new(uri.request_uri, headers.merge("Content-Type" => "application/json"))
        else
          raise ArgumentError, "unsupported request method: #{method}"
        end

      request.body = JSON.generate(payload) if payload
      request
    end

    def validate_uri!(uri)
      raise URI::InvalidURIError, "only https requests are allowed" unless uri.is_a?(URI::HTTPS)

      allowed_path_prefix = ALLOWED_HOSTS[uri.host]
      raise URI::InvalidURIError, "host not allowed: #{uri.host}" unless allowed_path_prefix
      raise URI::InvalidURIError, "path not allowed: #{uri.path}" unless uri.path.start_with?(allowed_path_prefix)
    end
  end
end
