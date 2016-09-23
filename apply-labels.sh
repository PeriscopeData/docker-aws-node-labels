#!/bin/sh

MD="curl -fs http://169.254.169.254/latest/meta-data/"
INSTANCE_ID=`${MD}/instance-id`
SECURITY_GROUPS=`${MD}/security-groups | tr '\n' ','`
PUBLIC_IP=`${MD}/public-ipv4`

# It appears it takes a while for the pod to incorporate the node name.
while [ "x$NODE" = "x" ] || [ "$NODE" = "null" ]; do
  sleep 1
  echo "[$(date)] Pod: $POD_NAME"
  NODE=`curl  -s -f \
        --cert   /etc/kubernetes/ssl/worker.pem \
        --key    /etc/kubernetes/ssl/worker-key.pem \
        --cacert /etc/kubernetes/ssl/ca.pem  \
        https://${KUBERNETES_SERVICE_HOST}/api/v1/namespaces/kube-system/pods/${POD_NAME} | jq -r '.spec.nodeName'
  `
done

echo "[$(date)] Node: $NODE"
if [ x == x$PUBLIC_IP ]; then
  IS_PUBLIC=false
else
  IS_PUBLIC=true
fi

curl  -s \
      --cert   /etc/kubernetes/ssl/worker.pem \
      --key    /etc/kubernetes/ssl/worker-key.pem \
      --cacert /etc/kubernetes/ssl/ca.pem  \
      --request PATCH \
      -H "Content-Type: application/strategic-merge-patch+json" \
      -d @- \
      https://${KUBERNETES_SERVICE_HOST}/api/v1/nodes/${NODE} <<EOF
{
  "metadata": {
    "labels": {
      "aws.node.kubernetes.io/id":   "${INSTANCE_ID}",
      "aws.node.kubernetes.io/is_public":   "${IS_PUBLIC}"
    },
    "annotations": {
      "aws.node.kubernetes.io/sgs":  "${SECURITY_GROUPS}"
    }
  }
}
EOF
