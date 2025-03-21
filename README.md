# Report API

The Report API enables uniform reporting of results and findings from policy engines, scanners, or other tooling.

This repository contains the API specification and Custom Resource Definitions (CRDs).

## Concepts

The API provides a `ClusterReport` and its namespaced variant `Report`.

Each `Report` contains a set of `results` and a `summary`. Each `result` contains attributes such as the source policy and rule name, severity, timestamp, and the resource.

## Reference

* [API Reference](./docs/api-docs.md)

## Demonstration

Typically the Report API is installed and managed by a [producer](#producers). However, to try out the API in a test cluster you can follow the steps below:

1. Add Report API CRDs to your cluster:

```sh
kubectl create -f crd/openreports.io/v1alpha1/
```
2. Create a sample policy report resource:

```sh
kubectl create -f samples/sample-cis-k8s.yaml
```
3. View policy report resources:

```sh
kubectl get reports
```

## Implementations

The following is a list of projects that produce or consume policy reports:

*(To add your project, please create a [pull request](https://github.com/kubernetes-sigs/wg-policy-prototypes/pulls).)*

### Producers

* [Falco](https://github.com/falcosecurity/falcosidekick/blob/master/outputs/policyreport.go)
* [Image Scanner](https://github.com/statnett/image-scanner-operator)
* [jsPolicy](https://github.com/loft-sh/jspolicy/)
* [Kyverno](https://kyverno.io/docs/policy-reports/)
* [Netchecks](https://docs.netchecks.io/)
* [Tracee Adapter](https://github.com/fjogeleit/tracee-polr-adapter)
* [Trivy Operator](https://aquasecurity.github.io/trivy-operator/v0.15.1/tutorials/integrations/policy-reporter/)
* [Kubewarden](https://docs.kubewarden.io/explanations/audit-scanner/policy-reports)

### Consumers

* [Fairwinds Insights](https://fairwinds.com/insights)
* [Kyverno Policy Reporter](https://kyverno.github.io/policy-reporter/)
* [Open Cluster Management](https://open-cluster-management.io/)

## Building 

```sh
make all
```

## Community, discussion, contribution, and support

You can reach the maintainers of this project at:

- [Slack](https://kubernetes.slack.com/messages/wg-policy)
- [Mailing List](https://groups.google.com/forum/#!forum/kubernetes-wg-policy)
- [WG Policy](https://github.com/kubernetes/community/blob/master/wg-policy/README.md)

### Code of conduct

Participation in the OpenReport community is governed by the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md).

[owners]: https://git.k8s.io/community/contributors/guide/owners.md
[Creative Commons 4.0]: https://git.k8s.io/website/LICENSE

# Historical References

See the [Kubernetes policy working group](https://github.com/kubernetes-sigs/wg-policy-prototypes/tree/master) and the [proposal](https://docs.google.com/document/d/1nICYLkYS1RE3gJzuHOfHeAC25QIkFZfgymFjgOzMDVw/edit#) for background and details.

