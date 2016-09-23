A small Alpine based container that fetched AWS metadata for the instance it
executes on and applies it as node labels in Kubernetes.  Ideally used by
dropping into the `/etc/kubernetes/manifests` directory a pod spec like:

```
apiVersion: v1
kind: Pod
metadata:
  name: aws-node-labels
  namespace: kube-system
spec:
  hostNework: true
  restartPolicy: OnFailure
  containers:
    - name: apply-labels
      image: scopej/aws-node-labels:latest
      env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      volumeMounts:
        - mountPath: /etc/kubernetes/ssl
          name: kubernetes-ssl
          readOnly: true
  volumes:
    - name: kubernetes-ssl
      hostPath:
        path: /etc/kubernetes/ssl
```
