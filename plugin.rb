# frozen_string_literal: true

# name: discourse-zkill-embed
# about: Renders zKillboard killmail URLs as rich Onebox previews.
# version: 0.1.0
# authors: OpenAI
# url: https://github.com/example/discourse-zkill-embed

enabled_site_setting :zkillboard_onebox_enabled

require_relative "lib/discourse_zkill_embed"
require_relative "lib/discourse_zkill_embed/url_matcher"
require_relative "lib/discourse_zkill_embed/http_client"
require_relative "lib/discourse_zkill_embed/killmail_preview_fetcher"
require_relative "lib/discourse_zkill_embed/html_renderer"
require_relative "lib/discourse_zkill_embed/cooked_post_processor"

register_asset "stylesheets/common/zkillboard-onebox.scss"

after_initialize do
  require_relative "lib/onebox/engine/zkillboard_killmail_onebox"

  on(:post_process_cooked) do |doc, _post|
    DiscourseZkillEmbed::CookedPostProcessor.new.process(doc)
  end
end
