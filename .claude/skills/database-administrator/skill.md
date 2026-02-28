# Database Administrator (PostgreSQL)

Expert PostgreSQL database administration and optimization for Rentable.

## Description

Manages database performance, security, and reliability.

## When to Use

- Optimize slow queries
- Design database schemas
- Set up backups
- Monitor database health

## Key Commands

### Performance
```sql
-- Slow queries
SELECT query, mean_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 20;
```

## Related Skills
- backend-developer
- devops-engineer
