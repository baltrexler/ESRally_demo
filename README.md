# ELK Testbed on GKE

A self-contained ELK stack (Elasticsearch, Logstash, Kibana) deployed on Google Kubernetes Engine, with ESRally benchmarking support.

---

## Prerequisites

- GCP project named `elk-testbed` (created manually or via Terraform)
- `gcloud`, `kubectl`, and `helm` installed and authenticated

---

## Deployment

### 1. Provision Infrastructure

```bash
terraform apply -var="service_account_id=<sa>@<project>.iam.gserviceaccount.com"
```

> Alternatively, export `TF_VAR_service_account_id` in your environment to avoid passing it on the command line.

### 2. Configure kubectl

```bash
gcloud container clusters get-credentials elastic-testbed --region us-east4 --project elk-testbed
```

### 3. Deploy ELK Stack via Helm

```bash
kubectl create namespace elk
helm install elk-stack ./Helm/elk-stack -n elk --wait
```

### 4. Access Kibana

```bash
kubectl port-forward -n elk svc/elk-stack-kibana 5601:5601
```

Kibana will be available at `http://localhost:5601`.

---

## Benchmarking with ESRally

### Deploy the ESRally Pod

```bash
kubectl apply -f rally.yaml
```

### Run a Benchmark

```bash
kubectl exec -it esrally -- bash
```

Then inside the pod:

```bash
esrally race \
  --track=geonames \
  --challenge=append-no-conflicts \
  --pipeline=benchmark-only \
  --target-hosts=<elasticsearch-service-ip>:9200
```

---

## Known Issues

| Issue | Notes |
|---|---|
| Multi-tenancy on small nodes | A 3-node cluster with undersized nodes caused resource contention and was insufficient for meaningful load testing. |
| Pre-existing data on cluster | Data loaded from prior dashboard work caused warnings that benchmark metrics may be misleading. |
| Local port-forward performance | Running ESRally locally against a port-forwarded cluster was too slow; a long-running ESRally pod deployed to the cluster was required instead. |
| Tainted nodepool blocking system pods | When tainting the generic nodepool, no untainted nodes remained for core Kubernetes functions. Ensure a system nodepool is always left untainted. |
| Elasticsearch JVM heap | ES requires `Xms` and `Xmx` to be equal. Mismatched values will prevent startup. |
| GCP disk quota | Ran out of persistent disk quota mid-deployment. Check and raise GCP quotas before provisioning. |
| Track data exceeds PVC size | Running a track whose decompressed dataset exceeded the pod's persistent storage killed the pod. Size PVCs accordingly before selecting a track. |
| Disk utilized after terraform destroy | If you do a terraform destroy of the GKE cluster, it will not destroy the disks automatically. I can fix this bug later but for now you may need to manually clean up the disks in gcloud console > compute engine / Disks. You'll see them there. |
| GKE cluster may be delete protected | May require manual deletion of GKE cluster after terraform destroy. Though the terraform destroy WILL delete all nodes and resources EXCEPT for some disks |
