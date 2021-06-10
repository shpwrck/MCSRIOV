# *M*ultus, *C*alico, and *SR-IOV* on k3s

Installs a k3s on a single `c3.2xlarge` instance on the default subnet in the `us-east-1a` availability zone with three elastic network interaces and one elastic ip.

## To deploy

1. Clone the repo.
1. Copy the `terraform.tfvars.example` file to `terraform.tfvars` and replace with meaningful content.
1. Run `terraform apply` and approve the generated plan.
1. When complete, use the provided output in the following command `ssh -i id_rsa ubuntu@<<OUTPUT>>`.
1. When finished testing, run `terraform destroy` and approve the generated plan.
