D = Steep::Diagnostic
#
target :lib do
  signature "sig"
#
  check "lib"                       # Directory name
#   check "Gemfile"                   # File name
#   check "app/models/**/*.rb"        # Glob
  ignore "lib/discordrb/voice/voice_bot.rb"
  ignore "lib/discordrb/voice/*.rb"
  ignore "lib/discordrb/commands/parser.rb"
  ignore "lib/discordrb/data/server.rb"
  ignore "lib/discordrb/data/message.rb"
  ignore "lib/discordrb/data/interaction.rb"
  ignore "lib/discordrb/data/channel.rb"
  ignore "lib/discordrb/data/member.rb"
  ignore "lib/discordrb/events/channels.rb"
  ignore "lib/discordrb/bot.rb"
  ignore "lib/discordrb/gateway.rb"
  ignore "lib/discordrb/webhooks/view.rb"
  ignore "lib/discordrb/permissions.rb"
  ignore "lib/discordrb/webhooks/client.rb"
  ignore "lib/discordrb/data/audit_logs.rb"
  ignore "lib/discordrb/data/webhook.rb"
  ignore "lib/discordrb/events/await.rb"
  ignore "lib/discordrb/events/invites.rb"
  ignore "lib/discordrb/data/user.rb"
  ignore "lib/discordrb/events/presence.rb"
  ignore "lib/discordrb/webhooks/embeds.rb"
  ignore "lib/discordrb/data/component.rb"
  ignore "lib/discordrb/websocket.rb"
  ignore "lib/discordrb/paginator.rb"
  ignore "lib/discordrb/data/role.rb"
  ignore "lib/discordrb/data/recipient.rb"
  ignore "lib/discordrb/light/integrations.rb"
  ignore "lib/discordrb/data/overwrite.rb"
  ignore "lib/discordrb/data/invite.rb"
  ignore "lib/discordrb/commands/command_bot.rb"
  ignore "lib/discordrb/events/interactions.rb"
  ignore "lib/discordrb/api/channel.rb"
  ignore "lib/discordrb/cache.rb"
  ignore "lib/discordrb/data/integration.rb"
  ignore "lib/discordrb/container.rb"
  ignore "lib/discordrb/commands/rate_limiter.rb"
  ignore "lib/discordrb/api.rb"
  ignore "lib/discordrb/errors.rb"
  ignore "lib/discordrb/commands/container.rb"
#
  library "pathname", "set", "json", "time", 'base64', 'uri'       # Standard libraries
#   library "websocket-client-simple"           # Gems
#
#   # configure_code_diagnostics(D::Ruby.strict)       # `strict` diagnostics setting
#   # configure_code_diagnostics(D::Ruby.lenient)      # `lenient` diagnostics setting
#   # configure_code_diagnostics do |hash|             # You can setup everything yourself
#   #   hash[D::Ruby::NoMethod] = :information
#   # end
end

# target :test do
#   signature "sig", "sig-private"
#
#   check "test"
#
#   # library "pathname", "set"       # Standard libraries
# end
