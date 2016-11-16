# https://github.com/Shopify/statsd-instrument
StatsD.backend = StatsD::Instrument::Backends::UDPBackend.new("#{ENV['STATSD_HOST']}:#{ENV['STATSD_PORT']}", :statsd)
StatsD.prefix = "inspire.#{Rails.env}"
