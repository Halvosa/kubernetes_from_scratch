#!/bin/bash
kubelet --config ./config \
 --container-runtime=remote \
 --container-runtime-endpoint=unix:///var/run/crio/crio.sock \
 &> /var/log/containers/kubelet.log
