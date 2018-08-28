#!/usr/bin/env ruby

# azure-storage-blob
require 'azure/storage/blob'

# prometheus_exporter
require 'prometheus_exporter'
require 'prometheus_exporter/server'

require 'json'

# https://blog.eq8.eu/til/ruby-logs-and-puts-not-shown-in-docker-container-logs.html
$docker_stdout = IO.new(IO.sysopen("/proc/1/fd/1", "w"),"w")
$docker_stdout.sync = true
require 'logger'
logger = Logger.new($docker_stdout)

port = ENV['PORT'] || 8080
container_name = ENV['CONTAINER'] || 'insights-metrics-pt1m'
storage_account = ENV['STORAGE_ACCOUNT']
storage_access_key = ENV['STORAGE_ACCESS_KEY']

metrics_prefix = ENV['METRICS_PREFIX'] || 'azure_'

PrometheusExporter::Metric::Base.default_prefix = metrics_prefix

server = PrometheusExporter::Server::WebServer.new port: port
server.start

client = Azure::Storage::Blob::BlobService.create(storage_account_name: storage_account, storage_access_key: storage_access_key)

last_modified = ""
loop do
  blob = client.list_blobs(container_name).last
  if last_modified == blob.properties[:last_modified]
    sleep 60
    next
  end
  last_modified = blob.properties[:last_modified]

  blob, content = client.get_blob(container_name, blob.name)
  metrics = JSON.parse(content)["records"].sort { |a,b| a["time"]<=>b["time"] }
  latest_time = metrics.last["time"]
  metrics.reject! { |m| m["time"] != latest_time }

  metrics.each do |m|
    ["count", "total", "minimum", "maximum", "average"].each do |metric_type|
      gauge = PrometheusExporter::Metric::Gauge.new("#{m["metricName"]}_#{metric_type}", "Azure metrics for #{ m["metricName"]}")
      server.collector.register_metric(gauge)
      gauge.observe(m[metric_type])
    end
  end

  logger.info "metrics grabbed from #{latest_time} - last modified at #{last_modified}"
  sleep 300
end
