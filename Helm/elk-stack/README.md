# elk-stack Helm Chart

Deploys a production-ready **ELK Stack** (Elasticsearch 8, Logstash 8, Kibana 8)
onto a **Google Kubernetes Engine (GKE)** cluster.

---

## Prerequisites

| Requirement | Minimum version |
|---|---|
| Helm | 3.10+ |
| Kubernetes | 1.27+ |
| GKE node pool | e2-standard-4 recommended (4 vCPU / 16 GB) |
| GKE StorageClass | `standard-rwo` (default, SSD-backed RWO) |

---

## Quick Start

```bash
# 1. Create a dedicated namespace
kubectl create namespace elk

# 2. Install with defaults (dev/staging sizing)
helm install elk-stack ./elk-stack \
  --namespace elk \
  --wait

# 3. Port-forward Kibana to your laptop
kubectl port-forward -n elk svc/elk-stack-kibana 5601:5601
# → open http://localhost:5601
```

---

## GKE-specific Notes

### vm.max_map_count
Elasticsearch requires `vm.max_map_count=262144` on every node it runs on.
The chart handles this with a privileged `initContainer` (busybox `sysctl`).
If your cluster has **PodSecurityAdmission** set to `restricted`, you will need
to either:
- Use a **node-level DaemonSet** to set `vm.max_map_count` instead, or
- Label the namespace: `kubectl label namespace elk pod-security.kubernetes.io/enforce=privileged`

### Workload Identity (recommended for production)
Annotate the ServiceAccount and map it to a GCP IAM service account:

```yaml
serviceAccount:
  annotations:
    iam.gke.io/gcp-service-account: elk-sa@PROJECT_ID.iam.gserviceaccount.com
```

### StorageClass
The default `standard-rwo` maps to GCE Persistent Disk (SSD). Change via:

```bash
helm install elk-stack ./elk-stack \
  --set global.storageClass=premium-rwo   # balanced PD
```

### Exposing Kibana via GKE Ingress

```bash
helm upgrade elk-stack ./elk-stack \
  --set kibana.ingress.enabled=true \
  --set kibana.ingress.className=gce \
  --set kibana.ingress.host=kibana.yourdomain.com \
  --set "kibana.ingress.annotations.kubernetes\\.io/ingress\\.global-static-ip-name=my-ip"
```

---

## Configuration Reference

### Global

| Parameter | Default | Description |
|---|---|---|
| `global.storageClass` | `standard-rwo` | GKE StorageClass for PVCs |
| `global.imagePullPolicy` | `IfNotPresent` | Image pull policy for all containers |

### Elasticsearch

| Parameter | Default | Description |
|---|---|---|
| `elasticsearch.replicas` | `3` | Number of ES data/master nodes |
| `elasticsearch.resources` | see values.yaml | CPU/memory requests & limits |
| `elasticsearch.javaOpts` | `-Xms2g -Xmx2g` | JVM heap (keep ≤50% of limit) |
| `elasticsearch.persistence.size` | `30Gi` | PVC size per node |
| `elasticsearch.antiAffinity` | `soft` | `soft` or `hard` pod anti-affinity |
| `elasticsearch.xpackSecurityEnabled` | `false` | Enable X-Pack security (TLS + auth) |

### Logstash

| Parameter | Default | Description |
|---|---|---|
| `logstash.replicas` | `1` | Number of Logstash pods |
| `logstash.pipeline.input` | Beats on 5044 | Logstash input block |
| `logstash.pipeline.filter` | _(empty)_ | Logstash filter block |
| `logstash.pipeline.output` | ES output | Logstash output block |

### Kibana

| Parameter | Default | Description |
|---|---|---|
| `kibana.replicas` | `1` | Number of Kibana pods |
| `kibana.ingress.enabled` | `false` | Enable GKE Ingress |
| `kibana.ingress.host` | `kibana.example.com` | Kibana hostname |
| `kibana.ingress.className` | `""` | IngressClass (e.g. `gce`) |

---

## Production Checklist

- [ ] Enable X-Pack security (`elasticsearch.xpackSecurityEnabled: true`) and provision TLS certificates
- [ ] Set `elasticsearch.antiAffinity: hard` to guarantee cross-node spread
- [ ] Size node pool: ≥3 nodes with ≥8 GB RAM each
- [ ] Enable `networkPolicy.enabled: true`
- [ ] Use Workload Identity for the ServiceAccount
- [ ] Store secrets (ES passwords) in GCP Secret Manager and inject via ExternalSecrets Operator
- [ ] Enable GKE Ingress with a managed TLS certificate for Kibana
- [ ] Configure log retention ILM policies inside Kibana

---

## Uninstall

```bash
helm uninstall elk-stack -n elk

# Remove PVCs (data is deleted!)
kubectl delete pvc -n elk -l app.kubernetes.io/instance=elk-stack
```
