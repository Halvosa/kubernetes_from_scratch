apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
staticPodPath: /etc/kubernetes/manifests/
cgroupDriver: systemd
authorization:
  mode: AlwaysAllow
authentication:
  anonymous:
    enabled: true
  webhook:
    enabled: false
