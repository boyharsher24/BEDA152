# episode-eks-docker-raskur

See tasks.md. Layout:
  app/              the raskur FastAPI app (+ Dockerfile)
  terraform/infra/  AWS layer (provided: network.tf, versions/providers/variables; rest = TODOs)
  terraform/k8s/    Kubernetes layer (kubernetes + helm providers)
  .github/workflows CI/CD skeletons
