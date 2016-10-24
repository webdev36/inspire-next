# https://github.com/Shopify/statsd-instrument
StatsD.backend = StatsD::Instrument::Backends::UDPBackend.new("52.5.223.200:8125", :statsd)
StatsD.prefix = "inspire.#{Rails.env}"
