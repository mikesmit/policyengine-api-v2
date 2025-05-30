from google.cloud.run_v2 import (
    ServicesAsyncClient,
    TrafficTarget,
    TrafficTargetAllocationType,
    UpdateServiceRequest,
    GetServiceRequest,
)
import logging

log = logging.getLogger(__file__)


class CloudrunClient:
    def __init__(self):
        self.services_client = ServicesAsyncClient()

    async def tag_revision(
        self, cloudrun_service_name: str, revision_name: str, tag: str
    ) -> str:
        service = await self.services_client.get_service(
            GetServiceRequest(name=cloudrun_service_name)
        )
        log.info(f"Looking for revision {revision_name}")
        # If it exists, just return it.
        for traffic in service.traffic:
            if traffic.revision == revision_name:
                if traffic.tag == tag:
                    log.info(
                        f"Revision {revision_name} is already tagged with {tag}"
                    )
                    return service.uri

        # Doesnt exist, so create it
        new_traffic = TrafficTarget()
        new_traffic.revision = revision_name
        new_traffic.percent = 0
        new_traffic.tag = tag
        new_traffic.type_ = (
            TrafficTargetAllocationType.TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION
        )
        service.traffic.append(new_traffic)

        log.info(f"tagging revision {revision_name} with tag {tag}")
        # I have no direct documentation of this but
        # this _should_ fail if the record has already been updated because
        # the original request includes an "etag" which, when provided in this
        # update request _should_ ask the cloudrun service to only succeed
        # if the record has not changed between the original get and this update.
        # none of this is explicitly documented for cloudrun or this call though.
        await self.services_client.update_service(
            UpdateServiceRequest(
                service=service, update_mask={"paths": ["traffic"]}
            )
        )
        return service.uri
