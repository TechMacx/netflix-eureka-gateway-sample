DR SOP docs

======HIGH LAVEL===========

1. Check our Infra feasibility and code update (terraform) - pre-checklist.
2. Configure Load balancer & API endpoint health checks in Route53.  
3. Configure RDS master-master with multi-az replica set.
4. Configure terraform to peform DR infra spin-up.
5. Configure Jenkins pipeline to build & deploy the latest codebase to both Primary / DR env.
6. validate API gateways and Custom domain Names in the DR site & test manual.


# confirm DR deployments.

Drill >>

1. Start DR by down Primary sites, and check latest entity has been shown in the DR site or not for data validation.
2. Revert to primary after some time and check added entity during the DR site active has been properly fetched or not in Primary sites for data validation.

## we should validate our infra architecture after DR-Drill is complete.

===========================

DETAILS

> secondary region - Terraform code:

1. Must check region ID in "variable.tf" inside root directory.
2. In module - "route53_public_zone_existing" - must replace zone ID with route53 zone's ID that deployed in "primary_region_cluster" deployment.
3. In module - "route53_private_zone_existing" - must replace zone ID with route53 zone's ID that deployed in "primary_region_cluster" deployment.
4. In module - "ovpn-vm" inside "secondary_region_cluster" - must replace AMI_ID by exect AMI_ID provided by amazone for that region.
5. https://www.youtube.com/watch?v=S9LcJeb89lY  (route53 health check)
6. dns record for - primary & secondary failover endpoints
