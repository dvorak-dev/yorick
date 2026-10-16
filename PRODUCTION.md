# Yorick Production Deployment Guide

This guide explains how to deploy Yorick in production using Docker Compose.

## 🚀 Quick Start

### 1. Build the Production Image

```bash
# Build the production image
docker build -t yorick:latest .

# Or pull from your registry
docker pull your-registry/yorick:latest
```

### 2. Set Up Environment Variables

```bash
# Copy the example environment file
cp env.example .env

# Edit with your production values
nano .env
```

**Required variables to set:**
- `SECRET_KEY_BASE`: Generate with `openssl rand -hex 64`
- `POSTGRES_PASSWORD`: Strong database password
- `POSTGRES_DB`: Database name (default: yorick)
- `POSTGRES_USER`: Database user (default: yorick)
- `CHEWY_HOST`: Set to `elasticsearch:9200` for production
- `CHEWY_PREFIX`: Set to `yorick_production` for production

### 3. Deploy with Docker Compose

```bash
# Start all services
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f web
```

**Note:** The production Docker Compose configuration includes:
- DNS configuration for reliable network connectivity
- Elasticsearch security settings disabled for single-node deployment
- Health checks for all services
- Proper volume management for data persistence

## 📋 Services Overview

### Web Application (`yorick:latest`)
- **Port**: 3000
- **Health Check**: `http://localhost:3000/up`
- **Dependencies**: Database, Elasticsearch
- **Volumes**: Storage, Logs

### PostgreSQL Database
- **Version**: 15-alpine (still the running server)
- **Port**: Internal only (5432)
- **Health Check**: Database connectivity
- **Volume**: Persistent data storage
- **Upgrade**: Postgres 16 is pinned in the repo and is not applied on the server yet. Follow [docs/postgres-16-migration.md](docs/postgres-16-migration.md). Do not change the image tag until that dump and restore is done.

### Elasticsearch
- **Version**: 8.13.4
- **Port**: Internal only (9200)
- **Health Check**: Cluster health
- **Memory**: 512MB (configurable via ES_JAVA_OPTS)
- **Security**: X-Pack security disabled for single-node deployment
- **Volume**: Persistent data storage

## 🔧 Configuration Options

### Environment Variables

#### Required
```bash
SECRET_KEY_BASE=your_64_character_secret
POSTGRES_PASSWORD=your_secure_password
CHEWY_HOST=elasticsearch:9200
CHEWY_PREFIX=yorick_production
```

#### Optional
```bash
# Performance tuning
WEB_CONCURRENCY=2
RAILS_MAX_THREADS=5

# Logging
RAILS_LOG_LEVEL=info

# SSL
FORCE_SSL=true

# Static files
RAILS_SERVE_STATIC_FILES=true

# Google Search Console (optional)
GOOGLE_SITE_VERIFICATION=your_verification_code
```

### Volume Management

```bash
# List volumes
docker volume ls

# Backup database
docker run --rm -v yorick_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz -C /data .

# Restore database
docker run --rm -v yorick_postgres_data:/data -v $(pwd):/backup alpine tar xzf /backup/postgres_backup.tar.gz -C /data
```

## 🔒 Security Considerations

### 1. Environment File Security
```bash
# Set proper permissions
chmod 600 .env

# Don't commit to version control
echo ".env" >> .gitignore
```

### 2. Network Security
- Services communicate via internal Docker network
- Only web service exposes external port (3000)
- Consider using reverse proxy (nginx) for SSL termination

### 3. Database Security
- Use strong, unique passwords
- Consider external database for production
- Regular backups

## 📊 Monitoring and Maintenance

### Health Checks
All services include health checks:
```bash
# Check service health
docker-compose -f docker-compose.prod.yml ps

# View health check logs
docker inspect yorick-web | jq '.[0].State.Health'
```

### Logs
```bash
# Application logs
docker-compose -f docker-compose.prod.yml logs -f web

# Database logs
docker-compose -f docker-compose.prod.yml logs -f db

# Elasticsearch logs
docker-compose -f docker-compose.prod.yml logs -f elasticsearch
```

### Updates
```bash
# Update application
docker-compose -f docker-compose.prod.yml pull web
docker-compose -f docker-compose.prod.yml up -d web

# Update all services
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Application Won't Start
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs web

# Verify environment variables
docker-compose -f docker-compose.prod.yml exec web env | grep SECRET_KEY_BASE
```

#### 2. Database Connection Issues
```bash
# Check database health
docker-compose -f docker-compose.prod.yml exec db pg_isready -U yorick

# Verify database exists
docker-compose -f docker-compose.prod.yml exec db psql -U yorick -l
```

#### 3. Elasticsearch Issues
```bash
# Check cluster health
curl http://localhost:9200/_cluster/health

# Check logs
docker-compose -f docker-compose.prod.yml logs elasticsearch
```

### Performance Tuning

#### Memory Optimization
```bash
# Adjust Elasticsearch memory in .env
ES_JAVA_OPTS=-Xms1g -Xmx1g

# Adjust web concurrency
WEB_CONCURRENCY=4
```

#### Database Optimization
```bash
# Add to .env for PostgreSQL tuning
POSTGRES_SHARED_BUFFERS=256MB
POSTGRES_EFFECTIVE_CACHE_SIZE=1GB
```

## 🔄 Backup and Recovery

### Automated Backups
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

# Database backup
docker-compose -f docker-compose.prod.yml exec -T db pg_dump -U yorick yorick > $BACKUP_DIR/db_$DATE.sql

# Elasticsearch backup
curl -X PUT "localhost:9200/_snapshot/backup_repo/snapshot_$DATE" -H 'Content-Type: application/json' -d '{"indices": "yorick_*"}'
```

### Recovery
```bash
# Database recovery
docker-compose -f docker-compose.prod.yml exec -T db psql -U yorick yorick < backup.sql

# Elasticsearch recovery
curl -X POST "localhost:9200/_snapshot/backup_repo/snapshot_$DATE/_restore"
```

## 🌐 Production Considerations

### 1. Reverse Proxy (Recommended)
Uncomment the nginx service in `docker-compose.prod.yml` and configure SSL.

### 2. External Services
Consider using managed services:
- **Database**: AWS RDS, Google Cloud SQL, Azure Database
- **Elasticsearch**: AWS Elasticsearch Service, Elastic Cloud
- **Redis**: AWS ElastiCache, Redis Cloud

### 3. Monitoring
- **Application**: New Relic, DataDog, AppSignal
- **Infrastructure**: Prometheus, Grafana
- **Logs**: ELK Stack, Fluentd

### 4. Scaling
```bash
# Scale web service
docker-compose -f docker-compose.prod.yml up -d --scale web=3

# Use external load balancer
# Configure nginx upstream
```

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review application logs
3. Verify environment configuration
4. Check service health status

---

**Remember**: Always test in staging before deploying to production! 