package v1alpha1

func contains(elem string, arr []string) bool {
	for _, e := range arr {
		if elem == e {
			return true
		}
	}
	return false
}
