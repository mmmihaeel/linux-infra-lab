# Topology

## Runtime topology

```text
                    +-------------------+
                    |   Client / curl   |
                    +---------+---------+
                              |
                              v
                    +-------------------+
                    |      Apache       |
                    |   Reverse Proxy   |
                    +-----+-------+-----+
                          |       |
            /node/* ------+       +------ /php/*
                          |       |
                          v       v
                  +-----------+ +-----------+
                  | node-demo | | php-demo  |
                  +-----+-----+ +-----+-----+
                        |             |
                        |             |
                        v             v
                  +-----------+ +-----------+
                  | postgres  | |  mysql    |
                  +-----------+ +-----------+
                        \           /
                         \         /
                          v       v
                          +-------+
                          | redis |
                          +-------+
```

## Docker network

- All services run on an isolated bridge network: `infra-net`.
- Apache is the public ingress service in local development.
- Data stores are available on mapped localhost ports for direct operator access.

## Port map (default)

- Apache: `localhost:8084` -> container `80`
- Node: `localhost:3006` -> container `3006`
- PHP: `localhost:8000` -> container `8000`
- MySQL: `localhost:3307` -> container `3306`
- PostgreSQL: `localhost:5438` -> container `5432`
- Redis: `localhost:6385` -> container `6379`

## Route map

- `/node/` -> `http://node-demo:3006/`
- `/php/` -> `http://php-demo:8000/`
- `/healthz` -> `http://node-demo:3006/health`
- `/server-status?auto` -> Apache mod_status endpoint
