# QuizSpark Architecture Diagram

```mermaid
graph TD
    subgraph Frontend
        A[React Application] --> B[AWS S3]
        B -->|Static Hosting| C[User Browser]
    end

    subgraph Backend
        D[Node.js/Express Server] --> E[AWS EC2]
        E --> F[Port 3000]
    end

    subgraph Database
        G[Supabase] --> H[PostgreSQL]
    end

    subgraph CI/CD Pipeline
        I[GitHub Repository] --> J[GitHub Actions]
        J -->|Backend| K[Docker → ECR → EC2]
        J -->|Frontend| L[S3 Bucket]
    end

    subgraph Monitoring
        M[Prometheus] --> N[Port 9090]
        O[Node Exporter] --> P[Port 9100]
    end

    C -->|API Calls| F
    F -->|Database Operations| G
    K --> E
    L --> B
    E --> M
    E --> O
```

## Key Components

1. **Frontend Layer**:
   - React-based web application
   - Hosted on AWS S3 for static website hosting
   - Accessible via S3 website endpoint

2. **Backend Layer**:
   - Node.js/Express server
   - Deployed on AWS EC2 instance
   - Running on port 3000
   - Handles API requests and business logic

3. **Database Layer**:
   - Supabase as the backend-as-a-service
   - PostgreSQL database
   - Handles data persistence and authentication

4. **CI/CD Pipeline**:
   - GitHub Actions for automation
   - Separate workflows for frontend and backend
   - Backend: Docker → ECR → EC2 deployment
   - Frontend: Build → S3 deployment

5. **Monitoring Stack**:
   - Prometheus for metrics collection
   - Node Exporter for system metrics
   - Both running on the EC2 instance
   - Accessible on ports 9090 and 9100 respectively

6. **Security & Quality**:
   - CodeQL analysis for security scanning
   - Automated testing through GitHub Actions
   - Infrastructure as Code (Terraform) 