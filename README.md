# azure-prometheus-exporter

Prometheus exporter for azure awg stats

## Environment Variables

### Required

* `STORAGE_ACCOUNT` - Azure blob storage account

* `STORAGE_ACCESS_KEY` - Azure blob storage account access key

### Optional

* `CONTAINER` - blob storage container to load defaults to `insights-metrics-pt1m`

* `METRICS_PREFIX` - Prometheus prefix for all exported metrics. Defaults to `azure_`

* `PORT` - running port for the container. Defaults to `8080`
