module "bastion" {
  source = "../../modules/compute/bastion"

  # Write the private key to the repo root ssh/ directory (gitignored).
  private_key_filename = "../../ssh/kk-lab-bastion.pem"
}
