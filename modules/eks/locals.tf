locals {
  # Strip https:// from OIDC issuer for IRSA condition keys
  oidc_issuer_without_https = replace(
    aws_eks_cluster.this.identity[0].oidc[0].issuer,
    "https://",
    ""
  )

  # Effective SG ID, whether created by the module or provided externally
  cluster_security_group_id_effective = (var.create_cluster_security_group
    ? aws_security_group.cluster[0].id
    : var.cluster_security_group_id)
}