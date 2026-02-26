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

