# API Reference

## Packages
- [openreports.io/v1alpha1](#openreportsiov1alpha1)


## openreports.io/v1alpha1

Package v1alpha1 contains API Schema definitions for the policy v1alpha1 API group

### Resource Types
- [ClusterReport](#clusterreport)
- [ClusterReportList](#clusterreportlist)
- [Report](#report)
- [ReportList](#reportlist)



#### ClusterReport



ClusterReport is the Schema for the ClusterReport API



_Appears in:_
- [ClusterReportList](#clusterreportlist)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `apiVersion` _string_ | `openreports.io/v1alpha1` | | |
| `kind` _string_ | `ClusterReport` | | |
| `metadata` _[ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#objectmeta-v1-meta)_ | Refer to Kubernetes API documentation for fields of `metadata`. |  |  |
| `source` _string_ | Source is an identifier for the source e.g. a policy engine that manages this report.<br />Use this field if all the results are produced by a single policy engine.<br />If the results are produced by multiple sources e.g. different engines or scanners,<br />then use the Source field at the ReportResult level. |  |  |
| `scope` _[ObjectReference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#objectreference-v1-core)_ | Scope is an optional reference to the report scope (e.g. a Deployment, Namespace, or Node) |  |  |
| `scopeSelector` _[LabelSelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#labelselector-v1-meta)_ | ScopeSelector is an optional selector for multiple scopes (e.g. Pods).<br />Either one of, or none of, but not both of, Scope or ScopeSelector should be specified. |  |  |
| `configuration` _[ReportConfiguration](#reportconfiguration)_ | Configuration is an optional field which can be used to specify<br />a contract between Report generators and consumers |  |  |
| `summary` _[ReportSummary](#reportsummary)_ | ReportSummary provides a summary of results |  |  |
| `results` _[ReportResult](#reportresult) array_ | ReportResult provides result details |  |  |


#### ClusterReportList



ClusterReportList contains a list of ClusterReport





| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `apiVersion` _string_ | `openreports.io/v1alpha1` | | |
| `kind` _string_ | `ClusterReportList` | | |
| `metadata` _[ListMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#listmeta-v1-meta)_ | Refer to Kubernetes API documentation for fields of `metadata`. |  |  |
| `items` _[ClusterReport](#clusterreport) array_ |  |  |  |


#### Limits







_Appears in:_
- [ReportConfiguration](#reportconfiguration)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `maxResults` _integer_ | MaxResults is the maximum number of results contained in the report |  |  |
| `statusFilter` _[StatusFilter](#statusfilter) array_ | StatusFilter indicates that the Report contains only those reports with statuses specified in this list |  | Enum: [pass fail warn error skip] <br /> |


#### Report



Report is the Schema for the reports API



_Appears in:_
- [ReportList](#reportlist)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `apiVersion` _string_ | `openreports.io/v1alpha1` | | |
| `kind` _string_ | `Report` | | |
| `metadata` _[ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#objectmeta-v1-meta)_ | Refer to Kubernetes API documentation for fields of `metadata`. |  |  |
| `source` _string_ | Source is an identifier for the source e.g. a policy engine that manages this report.<br />Use this field if all the results are produced by a single policy engine.<br />If the results are produced by multiple sources e.g. different engines or scanners,<br />then use the Source field at the ReportResult level. |  |  |
| `scope` _[ObjectReference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#objectreference-v1-core)_ | Scope is an optional reference to the report scope (e.g. a Deployment, Namespace, or Node) |  |  |
| `scopeSelector` _[LabelSelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#labelselector-v1-meta)_ | ScopeSelector is an optional selector for multiple scopes (e.g. Pods).<br />Either one of, or none of, but not both of, Scope or ScopeSelector should be specified. |  |  |
| `configuration` _[ReportConfiguration](#reportconfiguration)_ | Configuration is an optional field which can be used to specify<br />a contract between Report generators and consumers |  |  |
| `summary` _[ReportSummary](#reportsummary)_ | ReportSummary provides a summary of results |  |  |
| `results` _[ReportResult](#reportresult) array_ | ReportResult provides result details |  |  |


#### ReportConfiguration







_Appears in:_
- [ClusterReport](#clusterreport)
- [Report](#report)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `limits` _[Limits](#limits)_ |  |  |  |


#### ReportList



ReportList contains a list of Report





| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `apiVersion` _string_ | `openreports.io/v1alpha1` | | |
| `kind` _string_ | `ReportList` | | |
| `metadata` _[ListMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#listmeta-v1-meta)_ | Refer to Kubernetes API documentation for fields of `metadata`. |  |  |
| `items` _[Report](#report) array_ |  |  |  |


#### ReportResult



ReportResult provides the result for an individual policy



_Appears in:_
- [ClusterReport](#clusterreport)
- [Report](#report)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `source` _string_ | Source is an identifier for the policy engine that manages this report<br />If the Source is specified at this level, it will override the Source<br />field set at the Report level |  |  |
| `policy` _string_ | Policy is the name or identifier of the policy |  |  |
| `rule` _string_ | Rule is the name or identifier of the rule within the policy |  |  |
| `category` _string_ | Category indicates policy category |  |  |
| `severity` _[ResultSeverity](#resultseverity)_ | Severity indicates policy check result criticality |  | Enum: [critical high low medium info] <br /> |
| `timestamp` _[Timestamp](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#timestamp-v1-meta)_ | Timestamp indicates the time the result was found |  |  |
| `result` _[Result](#result)_ | Result indicates the outcome of the policy rule execution |  | Enum: [pass fail warn error skip] <br /> |
| `scored` _boolean_ | Scored indicates if this result is scored |  |  |
| `resources` _[ObjectReference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#objectreference-v1-core) array_ | Subjects is an optional reference to the checked Kubernetes resources |  |  |
| `resourceSelector` _[LabelSelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#labelselector-v1-meta)_ | ResourceSelector is an optional label selector for checked Kubernetes resources.<br />For example, a policy result may apply to all pods that match a label.<br />Either a Subject or a ResourceSelector can be specified. If neither are provided, the<br />result is assumed to be for the policy report scope. |  |  |
| `message` _string_ | Description is a short user friendly message for the policy rule |  |  |
| `properties` _object (keys:string, values:string)_ | Properties provides additional information for the policy rule |  |  |


#### ReportSummary



ReportSummary provides a status count summary



_Appears in:_
- [ClusterReport](#clusterreport)
- [Report](#report)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `pass` _integer_ | Pass provides the count of policies whose requirements were met |  |  |
| `fail` _integer_ | Fail provides the count of policies whose requirements were not met |  |  |
| `warn` _integer_ | Warn provides the count of non-scored policies whose requirements were not met |  |  |
| `error` _integer_ | Error provides the count of policies that could not be evaluated |  |  |
| `skip` _integer_ | Skip indicates the count of policies that were not selected for evaluation |  |  |


#### Result

_Underlying type:_ _string_

Result has one of the following values:
  - pass: the policy requirements are met
  - fail: the policy requirements are not met
  - warn: the policy requirements are not met and the policy is not scored
  - error: the policy could not be evaluated
  - skip: the policy was not selected based on user inputs or applicability

_Validation:_
- Enum: [pass fail warn error skip]

_Appears in:_
- [ReportResult](#reportresult)



#### ResultSeverity

_Underlying type:_ _string_

ResultSeverity has one of the following values:
  - critical
  - high
  - low
  - medium
  - info

_Validation:_
- Enum: [critical high low medium info]

_Appears in:_
- [ReportResult](#reportresult)



#### StatusFilter

_Underlying type:_ _string_

StatusFilter is used by Report generators to write only those reports whose status is specified by the filters

_Validation:_
- Enum: [pass fail warn error skip]

_Appears in:_
- [Limits](#limits)



