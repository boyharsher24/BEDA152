# Episode: eks-docker-raskur - Deploy a FastAPI app to AWS EKS with Docker + Terraform

Based on Mastering Terraform, Chapter 7 (Monitoring, Automating) and Chapter 8
(Containerize with AWS EKS). The book's .NET frontend/backend is replaced by ONE tiny
FastAPI app, "raskur" (app/, copied from https://github.com/boyharsher24/BEDA152,
listens on port 8000, page text "Raskur udachny").

## The big picture

Chapter 7 shipped the app as a VM image (Packer -> AMI -> EC2). Chapter 8 ships it as a
container image (Docker -> ECR -> pods on Kubernetes). The pipeline has three motions,
and they MUST happen in this order because each one needs something the previous made:

  1. terraform/infra   Creates the AWS things: network, registry (ECR), EKS cluster,
                       worker nodes, IAM roles, secret.   -> produces OUTPUTS
  2. docker build+push Needs the ECR repository from step 1 to push into.
                       Packer had no such dependency; Docker does.
  3. terraform/k8s     Needs the cluster from step 1 AND the image from step 2. Talks to
                       the Kubernetes API and creates namespace, pods, service, ingress.

Why two Terraform workspaces (state files)? The k8s layer has a hard dependency on the AWS
layer (no cluster = nothing to talk to). Splitting them means you can redeploy a new app
version (touch only k8s) without risking the VPC/cluster, and a Kubernetes mistake can
never plan a destroy of your network. Fig 8.12 in the book: outputs of workspace 1 become
inputs (variables) of workspace 2.

How we work: one task at a time, tell the tutor "check task N". The tutor runs
terraform fmt/validate/plan itself and reads your files - it does not take your word for it.
Stuck? Ask for a hint first; ask for the full answer explicitly if you want it.

COST WARNING: EKS control plane ~$0.10/h + NAT gateway + 2 nodes + NLB, about $0.25/h in
total once applied. Tasks 1-5 are free until the `apply` in 5c. Destroy when done (Task 14).

Provided for you (no task): terraform/infra network.tf (VPC, 2 public + 2 private subnets,
1 NAT, route tables, security groups, EKS subnet tags), versions/providers/variables/locals.

---------------------------------------------------------------------------------------

## Task 0 - Tooling and credentials
- [ ] 0. Install and verify the toolchain.

  WHAT: Install docker (Docker Desktop), kubectl and the AWS CLI (terraform is already
  installed): `winget install Docker.DockerDesktop Kubernetes.kubectl Amazon.AWSCLI`.
  Put your keys in `episode-eks-docker-raskur/.aws.env` (git-ignored) as `export` lines and
  `source .aws.env`. Verify: `aws sts get-caller-identity`, `docker version`, `kubectl version --client`.
  Also push `app/` to your own GitHub repo (needed for CI in tasks 12-13).

  WHY: Terraform only talks to AWS APIs, but this episode also needs a Docker daemon to
  build the image, the AWS CLI to log docker in to ECR and to produce a kubeconfig, and
  kubectl to look inside the cluster and debug. `get-caller-identity` proves the keys work
  AND shows which account you are about to spend money in. Keys live in a file / env vars,
  never in .tf files, because Terraform state and git history are forever.

  Tasks 1-5 can be done offline: `terraform init -backend=false && terraform validate`.

---------------------------------------------------------------------------------------

## Part A - AWS infrastructure (terraform/infra)

- [ ] 1. Monitoring: VPC Flow Logs -> CloudWatch  (monitoring.tf)

  WHAT: Write six resources: a trust policy for `vpc-flow-logs.amazonaws.com`, an IAM role
  using it, a permissions policy (logs:CreateLogGroup/CreateLogStream/PutLogEvents/...),
  the attachment of that policy to the role, a CloudWatch log group (7-day retention), and
  the `aws_flow_log` that connects the VPC to the log group through the role.

  WHY: This is the book's template for ANY "AWS service writes to CloudWatch" setup, and
  you will repeat it for EKS, Lambda, etc. Two separate IAM questions are always involved:
  (a) the TRUST policy = WHO may assume the role (here the flow-logs service itself), and
  (b) the PERMISSION policy = WHAT the role may do once assumed. Mixing them up is the
  most common IAM mistake. Flow logs also give you a record of accepted/rejected traffic
  in the VPC - very useful later when a pod "can't reach" something. The book also flags
  that resources = ["*"] is too wide; that is stretch task S1.

  Check: `terraform validate`, then `terraform plan` shows 6 new resources.

- [ ] 2. Container registry + push permissions  (ecr.tf, locals.tf)

  WHAT: Define `repository_list` and a map built with a `for` expression, create ECR
  repositories with `for_each`, create an IAM group, give it a per-repository push policy
  (7 ECR actions, scoped to that repo's ARN), and a group membership. Add the extra
  `ecr:GetAuthorizationToken` statement.

  WHY: Unlike Packer, Docker needs a registry that EXISTS before you can publish an
  artifact - that is why infra comes first. The book keeps a list of repos (frontend,
  backend); we have one app, but building it with for_each means adding a second repo is
  a one-word change - practicing iteration from earlier episodes. Permissions go to a
  GROUP, not a user: your GitHub Actions user and any human can be added to the group
  without touching the policy (membership = access). `GetAuthorizationToken` is the
  trap: it is an account-wide action that cannot be limited to one repository, so it needs
  `Resource = "*"` as its own statement, otherwise `docker login` to ECR fails even though
  the push rights look correct.

- [ ] 3. EKS control plane  (eks.tf)

  WHAT: Cluster IAM role (trust: `eks.amazonaws.com`), attach AmazonEKSClusterPolicy and
  AmazonEKSVPCResourceController (use for_each over a set instead of copy-paste), a
  CloudWatch log group named exactly `/aws/eks/<cluster_name>/cluster`, then the
  `aws_eks_cluster` with both security groups, both endpoint access flags, log types
  api+audit, and an explicit `depends_on`.

  WHY: The cluster role is what the EKS SERVICE uses to create ENIs, manage security
  groups etc. in your account on your behalf - it is NOT what your pods use. The log group
  name is a convention EKS looks up by name, which is why `cluster_name` lives in a local
  used in two places. The depends_on matters because nothing in the cluster's arguments
  references the policy attachments, so Terraform sees no dependency and may create the
  cluster before it has permissions; the failure is confusing and slow (EKS takes ~10 min
  to create, so a wrong order costs you real time). Public + private endpoint: public
  lets you run kubectl and Terraform from your laptop; private lets nodes talk to the API
  inside the VPC. In an enterprise you would close the public one.

- [ ] 4. Worker nodes  (node_group.tf)

  WHAT: Node IAM role (trust: `ec2.amazonaws.com`), attach the four mandatory policies
  (WorkerNode, CNI, ECR ReadOnly, CloudWatchAgentServer), then an `aws_eks_node_group`
  (ng-user, 1/2/3 scaling, AMI type and size from variables, depends_on the four
  attachments). Decide which subnets the nodes belong in.

  WHY: The control plane runs nothing of yours; nodes are the EC2 machines that actually
  run pods. Their role is assumed by EC2, hence a different trust principal than the
  cluster role - same pattern, different "who". Each of the four policies has a concrete
  job: join the cluster, give pods IP addresses (CNI), pull your image from ECR
  (this is the line that makes `ImagePullBackOff` go away), and ship metrics/logs.
  Subnet choice is a design question from Fig 8.3: nodes in private subnets (no inbound
  from the internet; outbound via NAT), the load balancer in public ones.

- [ ] 5. Workload identity + secret  (workload_identity.tf, secrets.tf)

  WHAT: Fetch the cluster's OIDC issuer certificate (tls provider), register an IAM OIDC
  provider, write a trust policy with `sts:AssumeRoleWithWebIdentity` conditioned on
  `system:serviceaccount:<namespace>:<sa-name>`, create the role; then create a random
  password, a Secrets Manager secret + version, and a policy allowing GetSecretValue /
  DescribeSecret ONLY on secrets starting with `${prefix}-`, attached to the role.

  WHY: Pods need AWS permissions (to read a secret) but must not hold access keys. IRSA
  solves it: Kubernetes signs a token for a pod's service account, AWS trusts the cluster
  as an identity provider (the OIDC step), and the role's trust policy says "only THIS
  service account in THIS namespace may assume me". Note the trust policy references a
  namespace and service account that do not exist yet - they are created in Task 7, and
  the names in the two workspaces must match exactly or the pod gets AccessDenied. The
  naming prefix is cheap least privilege: the book's `secret:*` grants access to every
  secret in the account; a prefix scopes it to this app.

- [ ] 5c. Outputs + first apply  (outputs.tf)

  WHAT: Uncomment/add the outputs (cluster name, ECR repository URL/name, workload identity
  role ARN, secret name). Run `terraform plan`, read it, then `terraform apply`.
  Verify with `terraform output` and `aws eks describe-cluster --name <name>`.

  WHY: Outputs are the contract between workspaces (Fig 8.12); the k8s workspace takes them
  as variables. Reading the plan before applying is the habit: count resources, make sure
  nothing is "destroy". Apply takes ~15-20 minutes (cluster ~10, nodes ~5) - this is when
  billing starts. If it fails midway, Terraform keeps what was created; fix and re-apply.

---------------------------------------------------------------------------------------

## Part B - Docker

- [ ] 6. Harden the Dockerfile, build, run, push  (app/Dockerfile)

  WHAT: Read the existing Dockerfile line by line. Improve it: pin the base image to a
  specific tag, run as a non-root user, add a HEALTHCHECK (or leave probes to Kubernetes
  and explain why), keep dependency installation before `COPY . .`. Then
  `docker build -t raskur:test .`, `docker run -p 8000:8000 raskur:test`, curl
  localhost:8000. Finally log in to ECR
  (`aws ecr get-login-password | docker login --username AWS --password-stdin <registry>`),
  tag as `<ecr_url>:<version>` and push.

  WHY: The book's Dockerfile is multi-stage because .NET needs an SDK to build and only a
  runtime to run. Python has no compile step so one stage is fine, but the same ideas
  apply: layer ordering (requirements first -> dependency layer cached until they change),
  small base, no root. Testing locally first is the cheapest debugging loop you have: a
  container that doesn't start on your laptop will never start in a pod. Use an explicit
  version tag (not only `latest`): the repo is MUTABLE and k8s only re-pulls when the tag
  string changes, so unique tags are what make rollouts and rollbacks work. The
  "always be specific" theme of the book.

---------------------------------------------------------------------------------------

## Part C - Kubernetes through Terraform (terraform/k8s)

- [ ] 7. Providers, namespace, service account  (providers.tf, namespace_sa.tf)

  WHAT: Add `aws_eks_cluster` + `aws_eks_cluster_auth` data sources, configure the
  `kubernetes` and `helm` providers (host, base64-decoded CA, token). Copy
  terraform.tfvars.example to terraform.tfvars with the real outputs. Create the
  namespace and the service account with the `eks.amazonaws.com/role-arn` annotation.

  WHY: This is the unusual part of the chapter: one Terraform run uses the AWS provider to
  discover how to talk to a cluster and then configures Kubernetes with it. The token is
  short-lived and fetched at plan time, which is why the cluster must already exist. The
  service account is the other half of the bridge from Task 5: its name/namespace match
  the IAM trust policy, and the annotation tells EKS which role to hand to pods using it.
  Reference the namespace resource (instead of retyping its name) so Terraform creates
  it first - implicit dependency instead of luck.

- [ ] 8. Deployment, Service, ConfigMap  (app.tf)

  WHAT: A ConfigMap with non-secret settings, a Deployment (replicas, image from ECR built
  from account id + region + repo + tag, port 8000, service account, env_from the config
  map, readiness + liveness probes on `/`, resource requests/limits), and a ClusterIP
  Service mapping port 80 -> 8000 via a label selector.

  WHY: Deployment = "keep N copies of this pod running, replace them gradually on change".
  Service = a stable internal address and load balancing over whichever pods currently
  match the label; pods come and go, the Service name does not. The readiness probe is not
  in the book but is essential: without it the load balancer sends traffic to a pod that
  is still booting. Resource requests let the scheduler fit pods onto small t3.small
  nodes (without them one pod can starve the others). Port 8000 (not the book's 5000) is
  the classic mismatch: port, targetPort and containerPort must all agree or you get a
  healthy-looking pod that nothing can reach.

- [ ] 9. Secrets Store CSI driver + SecretProviderClass  (secrets_csi.tf, app.tf)

  WHAT: Install the CSI driver and the AWS provider via two `helm_release` resources, create
  the `SecretProviderClass` via `kubernetes_manifest` (objects to fetch + a secretObjects
  mapping to a Kubernetes secret), mount it in the pod as a csi volume, and expose it as
  the env var DB_CONNECTION_STRING. Because of the CRD plan-time problem, apply in two
  passes using `-target` on the helm releases first.

  WHY: Kubernetes Secrets are only base64 - anyone with cluster read access sees them. The
  CSI approach keeps the source of truth in AWS Secrets Manager, with IAM controlling
  access, and the pod fetches the value at start-up using the identity from Task 5. Two
  charts because it is two layers: the cloud-agnostic driver and an AWS adapter (provider).
  SecretProviderClass is a CRD, a custom type that exists only after the chart installs,
  hence the plan-time failure and two-pass apply - the same flavour of ordering problem as
  the book's targeted apply for random_shuffle. One more gotcha: the synced Kubernetes
  Secret only appears while a pod mounts the volume.

- [ ] 10. NGINX ingress -> NLB, Ingress, hostname output  (ingress.tf, outputs.tf)

  WHAT: Install the ingress controller via helm (community chart, Service type
  LoadBalancer, NLB annotation with escaped dots), create the Ingress with
  `ingress_class_name = "nginx"` routing `/` to your Service, with depends_on, and output the
  load balancer hostname via a data source. Open the URL in a browser.

  WHY: A ClusterIP is only reachable inside the cluster. To bring the internet in you need
  (a) a controller that runs reverse-proxy pods (NGINX) and (b) Ingress rules that
  tell it what to route where. The controller's own Service of type LoadBalancer makes AWS
  create an NLB automatically - this is why the cluster needs ELB permissions and why the
  public subnets are tagged. The pattern mirrors the CSI driver / SecretProviderClass pair:
  one object enables a capability, another configures it. NLB DNS takes a few minutes to
  start resolving; "not found" right after apply is normal.

- [ ] 11. End-to-end verification

  WHAT: `aws eks update-kubeconfig --name <cluster> --region eu-central-1`, then
  `kubectl get nodes,pods -A`, `kubectl -n raskur get deploy,svc,ingress`,
  `kubectl -n raskur describe pod <pod>`, `kubectl -n raskur logs <pod>`,
  `kubectl -n raskur exec <pod> -- printenv DB_CONNECTION_STRING`, and curl the NLB
  hostname. Intentionally break something (wrong image tag, wrong targetPort) and diagnose it.

  WHY: "terraform apply succeeded" only means the objects were created, not that the app
  works. Learning the kubectl debugging ladder (get -> describe -> logs -> exec) is as
  important as the Terraform; the typical failures (ImagePullBackOff = ECR permissions or
  tag, CrashLoopBackOff = app error, pending = node capacity, 503 = service selector or
  readiness) each point to a specific earlier task.

---------------------------------------------------------------------------------------

## Part D - Automation (GitHub Actions)

- [ ] 12. docker-build.yaml - build and push the image on app changes

  WHAT: Fill in the TODOs: AWS credentials (key ID from repo variable, secret from repo
  secret), ECR login, buildx, and build-push-action with the tag generated from
  `date +%Y.%m` + `github.run_number`; push only on `push` to main, not on pull requests.
  Add the ECR-pusher IAM user to `ecr_image_pushers` (re-apply infra) so the pipeline
  has permission.

  WHY: Same idea as the book's Packer workflow: the image is an immutable, uniquely
  versioned artifact. Path filter `app/**` means Terraform-only changes don't rebuild
  images. Building (but not pushing) on a pull request is the CI half - it proves the
  Dockerfile still builds before merging. The version scheme guarantees no two builds
  collide, so you never overwrite a tag a running pod uses.

- [ ] 13. terraform-apply.yaml - infra job then k8s job

  WHAT: Add `backend "s3" {}` to both workspaces (different keys), create the state bucket,
  run `terraform init -backend-config=...`, apply infra, pass its outputs to the k8s job
  via job outputs and `-var` flags, do the two-pass apply for the CSI CRD, pin the
  Terraform version.

  WHY: A CI runner starts empty each time - without remote state it would try to create
  everything again. Backend settings are passed on the command line, not hardcoded,
  so the same code works for different buckets/environments. `needs: infra` encodes the
  ordering from the big picture above. Pinned versions ("always be specific") because
  nobody is there to fix a surprise upgrade mid-pipeline.

- [ ] 14. Teardown

  WHAT: `terraform destroy` in terraform/k8s FIRST, then in terraform/infra. Confirm in the AWS
  console/CLI that no load balancers, NAT gateways or EKS clusters remain.

  WHY: Kubernetes created an NLB and network interfaces that Terraform infra doesn't know
  about. If you destroy infra first, the VPC deletion hangs on those leftover
  resources. Destroy in reverse order of creation. Verifying afterwards matters
  because forgotten NAT gateways and load balancers quietly bill you.

---------------------------------------------------------------------------------------

## Stretch
- [ ] S1. Narrow the flow-log policy `resources` from "*" to the specific log group ARN
      (the book calls this out; requires thinking about the `:*` suffix for log streams).
- [ ] S2. Replace the retired ingress-nginx with AWS Load Balancer Controller or Gateway
      API; discuss the tradeoffs (ALB vs NLB, extra IAM, IRSA reused for the controller).
- [ ] S3. Move the single NAT gateway to one-per-AZ and discuss the cost vs availability trade.
