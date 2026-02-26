# Lab M4.07 - Terraform AWS Networking Deep Dive

**Repository:** https://github.com/MaryaAhmadi/ce-lab-terraform-networking.git

**Activity Type:** Individual  
**Estimated Time:** 60-90 minutes  
**Submission:** GitHub Repository


📌 Overview

This lab demonstrates how to provision a production-style AWS network using Terraform.
The architecture spans three Availability Zones (AZs) and follows a three-tier design (public, private, database).



## Learning Objectives

- [ ] Build complete multi-AZ VPC with Terraform
- [ ] Configure Internet Gateway and NAT Gateways
- [ ] Set up public and private route tables
- [ ] Implement network isolation
- [ ] Test network connectivity
- [ ] Apply cost optimization patterns

## Prerequisites

- [ ] Completed Week 3 networking labs (manual VPC creation)
- [ ] Completed Labs M4.01-M4.06
- [ ] Understanding of VPC concepts

---

## Introduction

Recreate your Week 3 VPC architecture using Terraform. This time, it's automated, repeatable, and version-controlled. Compare the manual process with Infrastructure as Code.

## Scenario

Build production-grade network infrastructure:
- Multi-AZ for high availability
- Public subnets for load balancers
- Private subnets for application servers
- Isolated database subnets
- NAT Gateways for outbound internet
- Proper routing and security

---

## Your Task

**What you'll build:**
- VPC spanning 3 availability zones
- 3 public subnets (web tier)
- 3 private subnets (application tier)
- 3 database subnets (data tier)
- Internet Gateway
- NAT Gateways (configurable: 1 or 3)
- Route tables and associations
- Network ACLs (optional)

**Time limit:** 60-90 minutes

---


Infrastructure Created

Component	           Details
----------             ------------
VPC	                   10.0.0.0/16
Availability Zones	      3
Public Subnets	          3 (for web/load balancer tier)
Private Subnets	          3 (for application tier)
Database Subnets	          3 (isolated database tier)
Internet Gateway	1
NAT Gateways	              1 (configurable to 3)
Route Tables	              Public, Private, Database



## Step-by-Step Instructions

### Step 1: Create Project Structure

```bash
mkdir -p ~/ce-labs/m4-07-networking
cd ~/ce-labs/m4-07-networking

# Create files
touch main.tf variables.tf outputs.tf terraform.tfvars
```

---

### Step 2: Define Variables

Create `variables.tf`:

```hcl
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "networking-lab"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnet_cidrs" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cost savings)"
  type        = bool
  default     = true
}
```

---

### Step 3: Create VPC and Subnets

Create `main.tf`:

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Tier = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    Tier = "Private"
  }
}

# Database Subnets
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.project_name}-database-${count.index + 1}"
    Tier = "Database"
  }
}
```

---

### Step 4: Create Internet Gateway

Add to `main.tf`:

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}
```

---

### Step 5: Create NAT Gateways

Add to `main.tf`:

```hcl
# Elastic IPs for NAT
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}"
  }
  
  depends_on = [aws_internet_gateway.main]
}
```

---

### Step 6: Create Route Tables

Add to `main.tf`:

```hcl
# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables
resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
  }
  
  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  }
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

# Database Route Table
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-database-rt"
  }
}

# Database Route Table Associations
resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}
```

---

### Step 7: Create Outputs

Create `outputs.tf`:

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  value = aws_subnet.database[*].id
}

output "nat_gateway_ips" {
  value = aws_eip.nat[*].public_ip
}

output "availability_zones" {
  value = var.availability_zones
}
```

---

### Step 8: Deploy Infrastructure

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve
```

**Expected outcome:** VPC with 9 subnets, IGW, NAT Gateway(s), route tables created in ~5 minutes.

---

### Step 9: Test Network Connectivity

Create test script `test-connectivity.sh`:

```bash
#!/bin/bash

# Get VPC ID
VPC_ID=$(terraform output -raw vpc_id)

# Test 1: Verify VPC
echo "=== VPC Details ==="
aws ec2 describe-vpcs --vpc-ids $VPC_ID

# Test 2: Count subnets
echo ""
echo "=== Subnet Count ==="
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].[Tags[?Key==`Name`].Value|[0]]' \
  --output text | wc -l

# Test 3: Verify NAT Gateway
echo ""
echo "=== NAT Gateways ==="
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' \
  --output table

# Test 4: Check route tables
echo ""
echo "=== Route Tables ==="
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

Run test:
```bash
chmod +x test-connectivity.sh
./test-connectivity.sh
```

---

### Step 10: Compare Cost Scenarios

Create `cost-comparison.md`:

```markdown
# NAT Gateway Cost Comparison

## Single NAT Gateway (Current: single_nat_gateway = true)
- 1 NAT Gateway: ~$32.40/month
- Data processing: ~$0.045/GB
- **Total (100GB/month):** ~$36.90/month

**Trade-offs:**
- ✅ Lower cost
- ❌ Single point of failure
- ❌ Cross-AZ data transfer charges

## Multi-AZ NAT Gateways (single_nat_gateway = false)
- 3 NAT Gateways: ~$97.20/month
- Data processing: ~$0.045/GB  
- **Total (100GB/month):** ~$102.70/month

**Trade-offs:**
- ✅ High availability
- ✅ No cross-AZ charges
- ❌ Higher cost

## Recommendation
- **Dev/Test:** Single NAT Gateway
- **Production:** Multi-AZ NAT Gateways
```

---

Architecture
AZ-A          AZ-B          AZ-C
├─ Public     ├─ Public     ├─ Public
├─ Private    ├─ Private    ├─ Private
└─ Database   └─ Database   └─ Database

Traffic Flow

Public subnets → Internet Gateway

Private subnets → NAT Gateway

Database subnets → Isolated (no internet access)


---

Deployment

Initialize Terraform:
terraform init
terraform fmt


terraform validate:

Apply (Development — Single NAT Gateway)
terraform apply -var="single_nat_gateway=true"
Apply (Production — Multi-AZ NAT Gateways)
terraform apply -var="single_nat_gateway=false"


🔍 Verification

Run connectivity tests to verify resources:

chmod +x test-connectivity.sh
./test-connectivity.sh

---

output:

✅ VPC is available

✅ 9 subnets are created

✅ NAT Gateway is available

✅ Route tables are correctly configured

💰 Cost Comparison
Mode	Monthly Cost	Notes
Single NAT	~$36.90	Lower cost, single point of failure
Multi-AZ NAT	~$102.70	High availability, no cross-AZ charges



--- 
Screenshots

all screenshots inside the screenshots/ folder.


VPC overview in AWS Console

All subnets (public, private, database)

NAT Gateway details

Route tables overview

Terraform Apply output


---

## Key Takeaways

✅ **Terraform** automates VPC creation  
✅ **Multi-AZ** provides high availability  
✅ **Cost optimization** via single NAT Gateway option  
✅ **Route tables** control traffic flow  
✅ **Infrastructure as Code** is faster and more reliable

---



Cleanup

To avoid ongoing AWS charges:

terraform destroy -auto-approve



**Next Lab:** M4.08 - Terraform AWS Compute (EC2 & Security Groups)
