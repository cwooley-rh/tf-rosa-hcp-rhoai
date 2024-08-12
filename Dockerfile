# Stage 1: Build Stage
FROM fedora:33 as build

ENV HOME=/home/ansible
ENV TERRAFORM_VERSION=1.9.3

# Install necessary packages
RUN dnf -y install \
    bash gcc musl-devel libffi-devel git gpgme-devel libxml2-devel \
    libxslt-devel curl cargo openssl-devel python3-devel unzip

# Create ansible user and group
RUN groupadd -g 1000 ansible && useradd -s /bin/bash -g ansible -u 1000 ansible -d ${HOME}

# Create necessary directories
RUN mkdir -p /ansible/virtualenv && chown -R ansible:ansible /ansible

# Switch to root to install Terraform and other tools
USER root

# Create .local/bin directory
RUN mkdir -p ${HOME}/.local/bin

# Install Terraform
RUN curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform ${HOME}/.local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install kubectl
RUN curl -sL https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kubectl \
    -o ${HOME}/.local/bin/kubectl && chmod +x ${HOME}/.local/bin/kubectl

# Install ROSA CLI
RUN curl -sL https://github.com/openshift/rosa/releases/download/v1.1.0/rosa-linux-amd64 \
    -o ${HOME}/.local/bin/rosa && chmod +x ${HOME}/.local/bin/rosa

# Install AWS CLI
RUN curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    -o awscli.zip && unzip awscli.zip && ./aws/install -i ${HOME}/.local/aws-cli -b ${HOME}/.local/bin

# Switch back to ansible user
USER ansible

# Set up virtual environment and install Python dependencies
RUN python3 -m venv /ansible/virtualenv
RUN /ansible/virtualenv/bin/python3 -m pip install --upgrade pip
COPY requirements.txt /ansible/requirements.txt
RUN /ansible/virtualenv/bin/pip3 install -r /ansible/requirements.txt

# Install Ansible collections
COPY requirements.yaml /ansible/requirements.yaml
RUN /ansible/virtualenv/bin/ansible-galaxy collection install -r /ansible/requirements.yaml

# Copy project files
COPY . /ansible

# Stage 2: Final Stage
FROM fedora:33

ENV HOME=/home/ansible

# Install necessary packages
RUN dnf -y install \
    bash openssl unzip glibc groff

# Create ansible user and group
RUN groupadd -g 1000 ansible && useradd -s /bin/bash -g ansible -u 1000 ansible -d ${HOME}
RUN mkdir -p /ansible/virtualenv && chown -R ansible:ansible /ansible

# Copy executables and virtual environment from build stage
COPY --chown=ansible:ansible ./ /ansible
COPY --from=build ${HOME}/.local ${HOME}/.local
COPY --from=build /ansible/virtualenv /ansible/virtualenv

# Switch to ansible user
USER ansible

# Set environment variables
ENV PATH=${HOME}/.local/bin:/ansible/virtualenv/bin:/ansible/staging/bin:$PATH
ENV PYTHONPATH=/ansible/virtualenv/lib/python3.12/site-packages/
ENV ANSIBLE_PYTHON_INTERPRETER=/ansible/virtualenv/bin/python
ENV KUBECONFIG=/ansible/staging/.kube/config
ENV ANSIBLE_FORCE_COLOR=1

WORKDIR /ansible

