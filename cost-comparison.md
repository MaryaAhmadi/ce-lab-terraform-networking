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

