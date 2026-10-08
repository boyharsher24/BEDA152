# TASK 10 (cont.): output the public hostname of the NLB.
# Hint: data "kubernetes_service_v1" for ingress-nginx-controller in ns ingress-nginx ->
#       status[0].load_balancer[0].ingress[0].hostname
# NLB DNS takes a few minutes to start resolving after it shows up.
