# argocd.tf

module "argocd" {
  source = "git::https://github.com/simonangel-fong/terraform-template.git//kubernetes/argocd"
}