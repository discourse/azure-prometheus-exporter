# azure-prometheus-exporter

Prometheus exporter for azure awg stats

## Environment Variables

### Required

* `storage_account` - Azure blob storage account

* `storage_access_key` - Azure blob storage account access key

### Optional

* `container` - blob storage container to load defaults to `insights-metrics-pt1m`

* `metrics_prefix` - Prometheus prefix for all exported metrics. Defaults to `azure_`

* `port` - running port for the container. Defaults to `8080`
