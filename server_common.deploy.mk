## pull the tag and region from the tf vars used by the github actions workflow
TAG=${TF_VAR_container_tag}
REGION=${TF_VAR_region}
include ../../server_common.mk
