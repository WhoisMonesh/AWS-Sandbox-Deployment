# Console-only / SDK-only Services

The following KodeKloud Playground services do **not** have a Terraform module in
this lab because they are either console-only, CLI-only, or SDK-only by design.
Practice them directly with the linked tooling instead of Terraform.

| Service | Why no Terraform module | How to practice |
|---------|------------------------|-----------------|
| EC2 Instance Connect | Browser/SSH console feature; no standalone resource | Use the EC2 console "Connect" → EC2 Instance Connect |
| AWS CloudShell | Browser-based shell; no deployable resource | Launch from the console |
| RDS Data API | Invoked via SDK/CLI against an existing Aurora Serverless DB | `aws rds-data execute-statement` |
| AWS CDK | Application code (TypeScript/Python/…) compiled to CFN | `cdk init` / `cdk deploy` locally |
| AWS SAM | CLI + template (YAML); local build/deploy tool | `sam init` / `sam deploy` locally |
| Tag Editor | Console-only bulk tagging UI | Use the console Tag Editor |
| SSM Messages | Service endpoint used by SSM Agent; not a resource | Indirect (via SSM) |
| AWS Management Console | The console itself | Browser |
| CodeStar | Deprecated service; `aws_codestar_project` removed from AWS provider v6 | Console only |
| MediaConnect | `aws_mediaconnect_*` resources not present in AWS provider v6.61 | Console only |

All other playground services have a Terraform module under `modules/<category>/`
and a deployable root under `services/<service>/`.
