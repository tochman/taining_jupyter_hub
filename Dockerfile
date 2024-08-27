# Start with an official Python runtime as a parent image
FROM python:3.10-slim

# Install necessary system packages
RUN apt-get update && apt-get install -y \
    npm \
    nodejs \
    sudo \
    adduser \
    libpq-dev \
    gcc \
    curl \
    unzip \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Create the jupyterhub user
RUN adduser --disabled-password --gecos "" jupyterhub

# Switch to the jupyterhub user
USER jupyterhub

# Install Deno for the jupyterhub user
RUN curl -fsSL https://deno.land/install.sh | sh

# Set environment variables for Deno
ENV DENO_INSTALL="/home/jupyterhub/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"

# Install the Deno Jupyter kernel as the jupyterhub user
RUN deno jupyter --install

# Switch back to root user to move the kernel to the global directory
USER root

# Install JupyterHub, notebook, and psycopg2 for PostgreSQL as root
RUN pip install jupyterhub notebook psycopg2 bcrypt sqlalchemy


# Install configurable-http-proxy for JupyterHub
RUN npm install -g configurable-http-proxy

# Copy all necessary files
COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py
COPY custom_authenticator.py /srv/jupyterhub/custom_authenticator.py
COPY create_user.sh /srv/jupyterhub/create_user.sh
COPY create_admin.py /srv/jupyterhub/create_admin.py
COPY startup.sh /srv/jupyterhub/startup.sh

# Set correct permissions for scripts
RUN chmod +x /srv/jupyterhub/create_user.sh /srv/jupyterhub/startup.sh

# Create the shared data directory
RUN mkdir -p /srv/data/langchain_basics

# Set permissions for the shared folder
RUN chmod 755 /srv/data/langchain_basics

# Copy your data into the shared folder
COPY langchain_basics /srv/data/langchain_basics/

# Create a symbolic link in /etc/skel for new users
RUN ln -s /srv/data/langchain_basics /etc/skel/langchain_basics

# Set the working directory
WORKDIR /srv/jupyterhub

# Move the Deno kernel to the global Jupyter kernels directory
RUN mv /home/jupyterhub/.local/share/jupyter/kernels/deno /usr/local/share/jupyter/kernels/

# Set the default command to start JupyterHub
CMD ["/srv/jupyterhub/startup.sh"]
