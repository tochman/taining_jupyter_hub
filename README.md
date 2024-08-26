# Training with JupyterHub

The goal of this project is to create a JupyterHub instance that can be used in programming training.

## Useful commands

Build and start the container

```bash
./build.sh local start
```

View docker logs: 

```bash
docker logs -f jupyterhub_container
```

Login to container terminal

```bash
docker exec -it jupyterhub_container /bin/bash
```

Login to the local database
```bash
docker exec -it jupyterhub_container psql postgresql://jupyterhub:jupyter_2024@host.docker.internal/jupyterhub_db
```