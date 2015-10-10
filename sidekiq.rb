require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { namespace: 'reddit', size: 1 }
end

class SidekiqQueue
  include Sidekiq::Worker

  def perform(opts)
    process_comments opts
  end
end
