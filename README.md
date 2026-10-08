# DevOps Networking - 12-Week DevOps & Cloud Learning Portfolio

> **Shubham Nishane** | Platform Engineer | Cloud Infrastructure | Automation | Observability
> Pune, India (open to Noida / Hybrid) | [LinkedIn](https://linkedin.com/in/shubham-nishane-2b340b416) | [GitHub](https://github.com/shubhamnishane-064) | shubhamnishane108@gmail.com

This repo documents my daily DevOps and Cloud learning: hands-on labs, real errors I hit, how I fixed them, and one mega project every week.

## For Recruiters: Start Here
1. Read the project table below (one project per week).
2. Open any `troubleshooting/` folder to see how I debug.
3. Open `quick-revision/` to see how I consolidate knowledge.

## Tech Covered
AWS (EC2, S3, IAM, VPC, RDS, CloudWatch) | Terraform | Ansible | Docker | Kubernetes | Jenkins | GitHub Actions | Prometheus | Grafana | Linux | Bash | Python | Nginx | GitOps / Pulumi

## Roadmap and Progress
| Week | Theme | Sunday Mega Project | Done |
|---|---|---|---|
| 1 | [Linux & Bash Foundations](week-01-linux-bash/) | Server health-check & backup toolkit (Bash + cron) | [ ] |
| 2 | [Networking for DevOps](week-02-networking/) | Nginx reverse proxy + load balancer lab with 2 backends | [ ] |
| 3 | [Git & GitHub Actions](week-03-git-github-actions/) | CI pipeline with lint, test, build and release on GitHub Actions | [ ] |
| 4 | [Docker & Containers](week-04-docker/) | Multi-container app (app + DB + Nginx) with Compose | [ ] |
| 5 | [Jenkins & CI/CD](week-05-jenkins-cicd/) | End-to-end Jenkins pipeline: GitHub -> Docker -> EC2 deploy | [ ] |
| 6 | [AWS Core Services](week-06-aws-core/) | Highly available 2-tier app on AWS (VPC, ALB, EC2, RDS) | [ ] |
| 7 | [Terraform IaC](week-07-terraform/) | Reusable Terraform module set that provisions the Week 6 architecture | [ ] |
| 8 | [Kubernetes](week-08-kubernetes/) | Deploy the Dockerized app on Kind with Ingress, HPA and Helm | [ ] |
| 9 | [Observability & Monitoring](week-09-observability/) | Monitoring stack: Prometheus + Grafana + alerts for the app | [ ] |
| 10 | [Ansible & Config Management](week-10-ansible/) | Ansible roles that configure Nginx + Docker + app on fresh EC2 | [ ] |
| 11 | [GitOps & Pulumi](week-11-gitops-pulumi/) | GitOps flow: Git push -> ArgoCD -> Kind cluster | [ ] |
| 12 | [Capstone & Job Prep](week-12-capstone/) | CAPSTONE: production-style platform, fully automated and documented | [ ] |

## Repo Structure
```
devops-networking/
  README.md
  week-01-linux-bash/
    README.md                  weekly plan + reflection
    1-mon/ ... 7-sun/
      README.md                daily log
      documentation/           notes, diagrams
      troubleshooting/         error-01.md (error -> root cause -> fix)
    7-sun/mega-project/        weekend project
    quick-revision/            cheatsheet + interview Qs
  week-02-.../
  ...
  templates/                   copy-paste templates
  troubleshooting-index.md     searchable list of all errors
  quick-revision-master/       final all-weeks revision
  scripts/new_week.sh          helper to add extra weeks
```

## Daily Routine (2-3 hrs)
| Time | Activity |
|---|---|
| 45 min | Learn concept |
| 90 min | Hands-on lab |
| 20 min | Notes + error log |
| 10 min | Commit and push |

Commit style: `week-03 wed: add reusable workflow + fix secret scope error`
