package v1alpha1

import (
	"fmt"
	"strings"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Status specifies state of a policy result
const (
	StatusPass  = "pass"
	StatusFail  = "fail"
	StatusWarn  = "warn"
	StatusError = "error"
	StatusSkip  = "skip"
)

// Severity specifies priority of a policy result
const (
	SeverityCritical = "critical"
	SeverityHigh     = "high"
	SeverityMedium   = "medium"
	SeverityLow      = "low"
	SeverityInfo     = "info"
)

// +kubebuilder:validation:Enum=pass;fail;warn;error;skip

// PolicyResult has one of the following values:
//   - pass: indicates that the policy requirements are met
//   - fail: indicates that the policy requirements are not met
//   - warn: indicates that the policy requirements and not met, and the policy is not scored
//   - error: indicates that the policy could not be evaluated
//   - skip: indicates that the policy was not selected based on user inputs or applicability
type PolicyResult string

// +kubebuilder:validation:Enum=critical;high;low;medium;info

// PolicySeverity has one of the following values:
// - critical
// - high
// - low
// - medium
// - info
type Severity string

var SeverityLevel = map[ResultSeverity]int{
	"":               -1,
	SeverityInfo:     0,
	SeverityLow:      1,
	SeverityMedium:   2,
	SeverityHigh:     3,
	SeverityCritical: 4,
}

func (r *ReportResult) GetResource() *corev1.ObjectReference {
	if len(r.Subjects) == 0 {
		return nil
	}

	return &r.Subjects[0]
}

func (r *ReportResult) HasResource() bool {
	return len(r.Subjects) > 0
}

func (r *ReportResult) GetKind() string {
	if !r.HasResource() {
		return ""
	}

	return r.GetResource().Kind
}

func (r *ReportResult) GetID() string {
	return r.ID
}

func (r *ReportResult) ResourceString() string {
	if !r.HasResource() {
		return ""
	}

	return ToResourceString(r.GetResource())
}

func ToResourceString(res *corev1.ObjectReference) string {
	var resource string

	if res.Namespace != "" {
		resource = res.Namespace
	}

	if res.Kind != "" && resource != "" {
		resource = fmt.Sprintf("%s/%s", resource, strings.ToLower(res.Kind))
	} else if res.Kind != "" {
		resource = strings.ToLower(res.Kind)
	}

	if res.Name != "" && resource != "" {
		resource = fmt.Sprintf("%s/%s", resource, res.Name)
	} else if res.Name != "" {
		resource = res.Name
	}

	return resource
}

type ReportInterface interface {
	metav1.Object
	GetID() string
	GetKey() string
	GetScope() *corev1.ObjectReference
	GetResults() []ReportResult
	HasResult(id string) bool
	GetSummary() ReportSummary
	GetSource() string
	GetKinds() []string
	GetSeverities() []string
}
