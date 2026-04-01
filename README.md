## Create project in GCP called "elk-testbed" This can be done in TF if you wish however I did it manually.

### Terraform ###

terraform apply -var="service_account_id=<input service_account ex 111111111111-compute@developer.gserviceaccount.com>"

### Attach Kubectl ###

gcloud container clusters get-credentials elastic-testbed --region us-east4 --project elk-testbed

### HELM deploy ###

kubectl create namespace elk
helm install elk-stack ./elk-stack -n elk --wait
kubectl port-forward -n elk svc/elk-stack-kibana 5601:5601


### ESRALLY ###

kubectl apply -f rally.yaml
kubectl exec -it esrally -- bash

# then inside the pod:
esrally race \
  --track=geonames \
  --challenge=append-no-conflicts \
  --pipeline=benchmark-only \
  --target-hosts=34.118.228.93:9200






  ######
  ISSUES FOUND DURING DEPLOYMENT
  ######

- Simple deployment in kubernetes with only 3 nodes led to multi-tenancy. The nodes were also too small to do a proper load test on.
- I had been doing some hands on dashboard building on the cluster and had some data loaded already, which led to warnings that metrics may be misleading.
- Test took entirely too long on my local machine with the port forwarded cluster ended up having to deploy a long standing ESrally to the cluster.
- When creating two nodepools I tainted the generic nodepool and had no system nodes available to do basic K8s funcitons.
- ES will not run unless min&max JVM heap sizes are the same.
- Quota Management in GCP. Ran out of Disk space had to adjust.
- Ran a track that the decompressed data was larger than the persistent storage of the pod... killing the pod.