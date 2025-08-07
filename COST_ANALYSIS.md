# Azure Cost Estimation for Weather API on AKS

## Monthly Cost Breakdown (West Europe Region)

### Core Infrastructure

| Service | Specification | Monthly Cost (USD) | Notes |
|---------|---------------|-------------------|--------|
| **AKS Cluster** | Free Tier | $0 | No management fees |
| **Virtual Machine** | Standard_B2s (1 node) | ~$30 | 2 vCPU, 4GB RAM, Burstable |
| **Storage** | 30GB Premium SSD | ~$5 | OS disk for node |
| **Load Balancer** | Standard | ~$20 | Included with AKS |
| **Container Registry** | Basic | ~$5 | 10GB storage included |
| **Bandwidth** | Outbound data | ~$5-10 | Depends on usage |

### **Total Estimated Monthly Cost: $65-70 USD**

## Cost Optimization Strategies

### 1. **Auto-Scaling Configuration**
```yaml
# Node auto-scaling (in Terraform)
enable_auto_scaling = true
min_count          = 1    # Scale down to 1 node
max_count          = 3    # Scale up when needed
```

### 2. **Development vs Production**

#### Development Environment
- **1 node cluster**: ~$35/month
- **Single replica**: Reduce resource usage
- **Stop after hours**: Save ~40% with automation

#### Production Environment
- **2-3 nodes**: ~$70-105/month
- **High availability**: Multiple replicas
- **24/7 operation**: Full cost

### 3. **Further Cost Reductions**

#### Option A: Spot Instances (Risk: Interruption)
```hcl
# In Terraform - can save up to 80%
default_node_pool {
  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = -1  # Current spot price
}
```
**Potential savings**: $50-55/month

#### Option B: Container Instances (Serverless)
- Azure Container Instances for very low traffic
- Pay only for execution time
- **Cost**: $0.0012/vCPU-second + $0.00012/GB-second

#### Option C: App Service (Platform as a Service)
- Azure App Service with containers
- **Basic tier**: ~$13/month
- No Kubernetes complexity

### 4. **Free Tier Benefits**
- **Azure Free Account**: $200 credit for 30 days
- **Always Free services**: Some services remain free after credit
- **Student accounts**: Additional credits if applicable

## Usage-Based Cost Factors

### Traffic Volume Impact
| Requests/Month | Bandwidth Cost | Total Additional Cost |
|----------------|----------------|----------------------|
| 10K requests   | ~$1           | ~$1                  |
| 100K requests  | ~$3           | ~$3                  |
| 1M requests    | ~$10          | ~$10                 |

### Storage Growth
| Container Images | ACR Storage Cost |
|------------------|------------------|
| 5 images (~2GB)  | Included        |
| 20 images (~8GB) | ~$2/month       |
| 50 images (~20GB)| ~$5/month       |

## Monitoring and Alerts

### Set up cost alerts in Azure
```bash
# Create budget alert
az consumption budget create \
  --account-name "your-subscription" \
  --budget-name "weather-api-budget" \
  --amount 100 \
  --time-grain Monthly
```

### Recommended Alert Thresholds
- **Warning**: 50% of budget ($35)
- **Critical**: 80% of budget ($56)
- **Maximum**: 100% of budget ($70)

## Real-World Cost Examples

### Scenario 1: Learning/Development
- **Setup**: 1 node, basic monitoring
- **Usage**: 8 hours/day, 5 days/week
- **Cost**: ~$25-30/month

### Scenario 2: Small Production API
- **Setup**: 2 nodes, auto-scaling
- **Usage**: 24/7 with moderate traffic
- **Cost**: ~$65-70/month

### Scenario 3: High-Availability Production
- **Setup**: 3 nodes, multiple regions
- **Usage**: Enterprise-grade deployment
- **Cost**: ~$150-200/month

## Cost Optimization Checklist

- [ ] Use Free AKS tier
- [ ] Choose burstable VM sizes (B-series)
- [ ] Enable auto-scaling (min=1, max=3)
- [ ] Use Basic ACR tier
- [ ] Monitor with Azure Cost Management
- [ ] Set up billing alerts
- [ ] Consider spot instances for dev
- [ ] Stop dev environments after hours
- [ ] Use tags for cost tracking
- [ ] Review and optimize monthly

## Notes
- Prices are estimates and may vary by region
- Actual costs depend on usage patterns
- Monitor Azure pricing for updates
- Consider Azure Hybrid Benefit if applicable
- Free tier credits can cover initial months
