VERSION := $(shell git describe --tags --abbrev=0)
BUILD_DATE := $(shell date -R)
VCS_URL := $(shell basename `git rev-parse --show-toplevel`)
VCS_REF := $(shell git log -1 --pretty=%h)
NAME := $(shell basename `git rev-parse --show-toplevel`)
VENDOR := $(shell whoami)
DOCKER_HOST := logging
USER_NAME ?= $(shell echo $USER_NAME)
GCE_PROJECT ?= $(shell echo $GOOGLE_PROJECT)

.PHONY: all version docker-env build up-app up-down show-ip login push-app
all: create-vm build-app build-monitoring push-app push-monitoring up-app show-ip

version:
	@echo VERSION=${VERSION}
	@echo BUILD_DATE=${BUILD_DATE}
	@echo VCS_URL=${VCS_URL}
	@echo VCS_REF=${VCS_REF}
	@echo NAME=${NAME}
	@echo VENDOR=${VENDOR}

create-vm:
	docker-machine create --driver google \
	--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 \
	--google-zone europe-west1-b \
	--google-open-port 5601/tcp \
	--google-open-port 9292/tcp \
	--google-open-port 9411/tcp \
	--google-open-port 8080/tcp \
	--google-open-port 9090/tcp \
	--google-open-port 3000/tcp \
	--google-open-port 9292/tcp \
	--google-scopes "https://www.googleapis.com/auth/monitoring.read" \
	--engine-opt experimental \
	--engine-opt metrics-addr=0.0.0.0:9999 \
	$(DOCKER_HOST)

set-env:
	eval $$(docker-machine env $(DOCKER_HOST))

destroy-vm:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker-machine rm ${DOCKER_MACHINE_NAME}

build: build-app build-monitoring build-logging
build-app: build-ui build-post build-comment
build-monitoring: build-prometheus build-mongodb-exporter build-blackbox-exporter build-alertmanager build-grafana build-telegraf build-trickster
build-logging: build-fluentd

build-ui:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/ui:${VERSION} -t ${USER_NAME}/ui:latest src/ui/

build-post:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/post:${VERSION} -t ${USER_NAME}/post:latest src/post-py/

build-comment:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/comment:${VERSION} -t ${USER_NAME}/comment:latest src/comment/

build-prometheus:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/prometheus:${VERSION} -t ${USER_NAME}/prometheus:latest \
	--build-arg VERSION="${VERSION}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg VCS_URL="${VCS_URL}" \
	--build-arg VCS_REF="${VCS_REF}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" monitoring/prometheus

build-alertmanager:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/alertmanager:${VERSION} -t ${USER_NAME}/alertmanager:latest \
	--build-arg VERSION="${VERSION}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg VCS_URL="${VCS_URL}" \
	--build-arg VCS_REF="${VCS_REF}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" monitoring/alertmanager

build-grafana:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/grafana:${VERSION} -t ${USER_NAME}/grafana:latest \
	--build-arg VERSION="${VERSION}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg VCS_URL="${VCS_URL}" \
	--build-arg VCS_REF="${VCS_REF}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" monitoring/grafana

build-mongodb-exporter:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/mongodb_exporter:${VERSION} -t ${USER_NAME}/mongodb_exporter:latest \
	--build-arg VERSION="${VERSION}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg VCS_URL="${VCS_URL}" \
	--build-arg VCS_REF="${VCS_REF}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" monitoring/mongodb_exporter

build-blackbox-exporter:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/blackbox_exporter:${VERSION} -t ${USER_NAME}/blackbox_exporter:latest \
	--build-arg VERSION="${VERSION}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg VCS_URL="${VCS_URL}" \
	--build-arg VCS_REF="${VCS_REF}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" monitoring/blackbox_exporter

build-telegraf:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/telegraf:${VERSION} -t ${USER_NAME}/telegraf:latest \
	--build-arg VERSION="${VERSION}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg VCS_URL="${VCS_URL}" \
	--build-arg VCS_REF="${VCS_REF}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" monitoring/telegraf

build-trickster:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/trickster:${VERSION} -t ${USER_NAME}/trickster:latest \
	--build-arg VERSION="${VERSION}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg VCS_URL="${VCS_URL}" \
	--build-arg VCS_REF="${VCS_REF}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" monitoring/trickster

build-fluentd:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker build -t ${USER_NAME}/fluentd:${VERSION} -t ${USER_NAME}/fluentd:latest \
	--build-arg VERSION="${VERSION}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg VCS_URL="${VCS_URL}" \
	--build-arg VCS_REF="${VCS_REF}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" logging/fluentd

login:
	docker login -u ${USER_NAME}

push: push-app push-monitoring push-logging
push-app: push-ui push-post push-comment
push-monitoring: push-prometheus push-mongodb-exporter push-blackbox-exporter push-alertmanager push-grafana push-telegraf push-trickster
push-logging: push-fluentd

push-ui:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/ui:${VERSION} ; docker push ${USER_NAME}/ui:latest

push-post:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/post:${VERSION} ; docker push ${USER_NAME}/post:latest

push-comment:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/comment:${VERSION} ; docker push ${USER_NAME}/comment:latest

push-prometheus:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/prometheus:${VERSION} ; docker push ${USER_NAME}/prometheus:latest

push-alertmanager:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/alertmanager:${VERSION} ; docker push ${USER_NAME}/alertmanager:latest

push-grafana:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/grafana:${VERSION} ; docker push ${USER_NAME}/grafana:latest

push-mongodb-exporter:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/mongodb_exporter:${VERSION} ; docker push ${USER_NAME}/mongodb_exporter:latest

push-blackbox-exporter:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/blackbox_exporter:${VERSION} ; docker push ${USER_NAME}/blackbox_exporter:latest

push-telegraf:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/telegraf:${VERSION} ; docker push ${USER_NAME}/telegraf:latest

push-trickster:
	eval $$(docker-machine env $(DOCKER_HOST)) ; docker login -u ${USER_NAME} ; docker push ${USER_NAME}/trickster:${VERSION} ; docker push ${USER_NAME}/trickster:latest

up-app: down-app
	eval $$(docker-machine env $(DOCKER_HOST)) ; cd docker/ ; docker-compose up -d
down-app:
	eval $$(docker-machine env $(DOCKER_HOST)) ; cd docker/ ; docker-compose down

up-monitoring:
	eval $$(docker-machine env $(DOCKER_HOST)) ; cd docker/ ; docker-compose -f docker-compose-monitoring.yml up -d
down-monitoring:
	eval $$(docker-machine env $(DOCKER_HOST)) ; cd docker/ ; docker-compose -f docker-compose-monitoring.yml down

up-logging:
	eval $$(docker-machine env $(DOCKER_HOST)) ; cd docker/ ; docker-compose -f docker-compose-logging.yml up -d
down-logging:
	eval $$(docker-machine env $(DOCKER_HOST)) ; cd docker/ ; docker-compose -f docker-compose-logging.yml down

show-ip:
	@echo ${DOCKER_HOST} ip-address: $(shell docker-machine ip ${DOCKER_HOST})

install-tiller:
ifeq ($(shell kubectl get pods -n kube-system | grep -Ec "tiller.*Running"), 0)
	@echo ">> Creating tiller service account"
	kubectl apply -f kubernetes/reddit/tiller.yml
	helm init --service-account tiller
else
	@echo ">> Tiller exits"
endif

k8s-cluster-run:
	cd kubernetes/terraform && terraform get && terraform init && terraform apply -auto-approve=true

k8s-cluster-destroy:
	cd kubernetes/terraform && terraform destroy -auto-approve=true

k8s-deploy-app: install-tiller
	@echo ">> Deploying Reddit application to Production"
	cd kubernetes/Charts/reddit && helm dep update
	cd kubernetes/Charts && helm upgrade prod reddit --install --namespace production

k8s-deploy-gitlab: install-tiller
	@echo ">> Deploying GitLab CE ..."
	cd kubernetes/Charts/gitlab-omnibus && helm install --name gitlab . -f values.yaml

k8s-install-nginx-ingress: install-tiller
	@echo ">> Deploying Nginx Ingress ..."
	helm install stable/nginx-ingress --name nginx

k8s-install-prometheus: install-tiller
	@echo ">> Deploying Prometheus ..."
	cd kubernetes/Charts/prometheus && helm upgrade prom . -f custom_values.yml --install

k8s-install-prometheus-operator: install-tiller
	@echo ">> Deploying Prometheus Operator..."
	cd kubernetes/Charts/prometheus-operator && helm upgrade prom-operator . --install

k8s-install-grafana: install-tiller
	@echo ">> Deploying Grafana..."
	helm upgrade grafana stable/grafana --install --set "adminPassword=admin" --set "service.type=NodePort" --set "ingress.enabled=true"  --set "ingress.hosts={reddit-grafana}"

k8s-install-monitoring: k8s-install-prometheus k8s-install-grafana

k8s-install-efk:
	@echo ">> Deploying Elasticsearch and Fluentd ..."
	cd kubernetes && kubectl apply -f ./efk

k8s-install-kibana:
	@echo ">> Deploying Kibana ..."
	helm upgrade kibana stable/kibana --install --set "ingress.enabled=true" --set "ingress.hosts={reddit-kibana}" --set "env.ELASTICSEARCH_HOSTS=http://elasticsearch-logging:9200" --version 2.3.0

