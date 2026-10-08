# TASK 2 - Container registry + push permissions  (book: "Container registry")
#
# TODO: in locals.tf define repository_list = ["raskur"] and
#       repositories = { for name in local.repository_list : name => name }
# TODO: aws_ecr_repository "main"  (for_each over local.repositories,
#       name "ecr-${local.prefix}-${each.key}", MUTABLE tags)
# TODO: aws_iam_group "ecr_image_pushers"
# TODO: aws_iam_group_policy "ecr_image_pushers" (for_each) - jsonencode policy that
#       allows the 7 push actions from the book on THAT repo's ARN only
# TODO: aws_iam_group_membership "ecr_image_pushers" (users = var.ecr_image_pushers)
#
# Extra (not in book, worth it): ecr:GetAuthorizationToken is account-level and
# CANNOT be scoped to a repo (Resource = "*"). Without it `docker login` fails.
# Add a second statement for it.
