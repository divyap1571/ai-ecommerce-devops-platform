# AI Incident Analysis

## Incident
A controlled backend outage was simulated by scaling the Kubernetes
server deployment from 2 replicas to 0 replicas.

## Detection
Kubernetes events reported:
- ScalingReplicaSet: server scaled down from 2 to 0
- SuccessfulDelete: backend pods deleted
- Killing: backend containers stopped

## Root Cause
The immediate root cause was an intentional administrative scaling
operation that reduced the backend replica count from 2 to 0.

## Impact
The backend service became unavailable during the controlled test.
Frontend and MongoDB components remained deployed.

## Recovery
The server deployment was scaled back from 0 to 2 replicas.
Kubernetes created two new backend pods and started the containers.

## Verification
The deployment rollout completed successfully.
Backend logs confirmed:
- Server running on port 5000
- Successful MongoDB connection

## AI-Assisted Recommendation
1. Maintain a minimum of two backend replicas for availability.
2. Configure monitoring alerts for unexpected replica reduction.
3. Monitor Kubernetes deployment events and pod health.
4. Keep readiness and liveness probes enabled.
5. Investigate HPA metrics availability because the cluster reported
   missing metrics.k8s.io during the test period.

## Incident Lifecycle
Detect -> Analyze -> Identify Root Cause -> Recover -> Verify -> Prevent
