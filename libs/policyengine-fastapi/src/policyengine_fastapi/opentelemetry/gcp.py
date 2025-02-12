import logging
import os
from opentelemetry.sdk.resources import  Resource

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

log = logging.getLogger(__name__)

# see https://cloud.google.com/trace/docs/setup/python-ot


# except, google lies. For the trace to work it actually needs to be in the format
# projects/policyengine-448017/traces/50d5653a403a853d9d2720690e19c51e
# but thats _NOT_ what's in the header they pass the app (that's just the trace id)
# so the otelTraceID is just the ID by iself.
# so we have to add it

class AddGcpProjectToTraceFilter(logging.Filter):
    def __init__(self, project:str):
        super().__init__()
        self.project = project

    def filter(self, record:logging.LogRecord):
        if not hasattr(record, "otelTraceID"):
            return super().filter(record)
        record.otelTraceID = f"projects/{self.project}/traces/{record.otelTraceID}" # type: ignore
        return super().filter(record)


def _get_project_id()->str:
    return _get_project_id_from_metadata() or os.getenv("GOOGLE_CLOUD_PROJECT") or "NO_PROJECT_SPECIFIED"

def _get_project_id_from_metadata()->str | None:
    from urllib import request
    url = "http://metadata.google.internal/computeMetadata/v1/project/project-id"
    req = request.Request(url)
    req.add_header("Metadata-Flavor", "Google")
    try :
        return request.urlopen(req).read().decode()
    except Exception as err:
        log.info(f"Unable to get the google project id from a local metadata service: {err}")
    return None
    
class GCPLoggingInstrumentor:

    def __init__(self, project_id:str | None = None):
        self.project_id = project_id or _get_project_id()

    '''
    Configures the standard opentelemetry logging instrumentor to generate
    json logs as per gcp expectations.
    '''
    def instrument(self):
        from opentelemetry.instrumentation.logging import LoggingInstrumentor
        from pythonjsonlogger.json import JsonFormatter

        logHandler = logging.StreamHandler()
        formatter = JsonFormatter(
            "%(asctime)s %(levelname)s %(message)s %(otelTraceID)s %(otelSpanID)s %(otelTraceSampled)s",
            rename_fields={
                "levelname": "severity",
                "asctime": "timestamp",
                "otelTraceID": "logging.googleapis.com/trace",
                "otelSpanID": "logging.googleapis.com/spanId",
                "otelTraceSampled": "logging.googleapis.com/trace_sampled",
                },
            datefmt="%Y-%m-%dT%H:%M:%SZ",
        )
        
        logHandler.setFormatter(formatter)
        logHandler.addFilter(AddGcpProjectToTraceFilter(self.project_id))

        logging.basicConfig(
            level=logging.INFO,
            handlers=[logHandler],
        )
        LoggingInstrumentor().instrument()


def export_ot_to_gcp(resource:Resource):
    from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
    from opentelemetry.exporter.cloud_monitoring import CloudMonitoringMetricsExporter
    '''
    configure opentelemetry to directly export to gcp cloudtrace/metrics
    useful when running in the google cloud
    '''
    traceProvider = TracerProvider(resource=resource)
    processor = BatchSpanProcessor(CloudTraceSpanExporter())
    traceProvider.add_span_processor(processor)
    trace.set_tracer_provider(traceProvider)

    reader = PeriodicExportingMetricReader(
        CloudMonitoringMetricsExporter()
    )
    meterProvider = MeterProvider(metric_readers=[reader], resource=resource)
    metrics.set_meter_provider(meterProvider)