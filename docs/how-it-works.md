## How it works

Azure deployments are asynchronous.

This tool:

1. Starts deployment with --no-wait
2. Polls deployment operations
3. Parses operation states
4. Displays:
   - Progress bar
   - Resource states
   - Deployment status