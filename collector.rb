#!/usr/bin/env ruby

# azure-storage-blob
require 'azure/storage/blob'

# prometheus_exporter
require 'prometheus_exporter'
require 'prometheus_exporter/server'

require 'json'

port = ENV['port'] || 8080
container_name = ENV['container'] || 'insights-metrics-pt1m'
storage_account = ENV['storage_account']
storage_access_key = ENV['storage_access_key']

metrics_prefix = ENV['metrics_prefix'] || 'azure_'

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

  puts "metrics grabbed from #{latest_time} - last modified at #{last_modified}"
  sleep 300
end