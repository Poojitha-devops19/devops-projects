## Docker Build Strategies Used
 
This project demonstrates both Single-Stage and Multi-Stage Docker builds to highlight best practices.
 
### Single-Stage Build
- Uses Node.js runtime for both build and execution
- Simple to implement
- Results in larger image size
- Suitable for development environments
 
### Multi-Stage Build
- Separates build and runtime stages
- Final image contains only production artifacts
- Smaller, more secure image
- Recommended for production deployments
 
### Why Multi-Stage Build?
Multi-stage builds reduce image size, improve security, and align with production-grade DevOps practices.