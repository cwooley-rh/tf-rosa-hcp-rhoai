FROM registry.access.redhat.com/ubi8/ubi as build

RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RUN yum -y install \
    bash gcc libffi-devel git gpgme-devel libxml2-devel \
    libxslt-devel curl openssl-devel python3.12-devel unzip

RUN mkdir -p /opt/bin && mkdir -p /opt/az

RUN curl -slL https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kubectl \
        -o kubectl && install kubectl /opt/bin/

RUN curl -slL https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm -o /opt/az/packages-microsoft-prod.rpm

RUN curl -slL https://releases.hashicorp.com/terraform/1.9.4/terraform_1.9.4_linux_amd64.zip -o /opt/tf.zip && unzip /opt/tf.zip -d /opt/bin && rm /opt/tf.zip && chmod +x /opt/bin/terraform

RUN groupadd ansible --g 1000 && useradd -s /bin/bash -g ansible -u 1000 ansible -d /home/ansible
RUN mkdir -p /ansible/virtualenv && chown -R ansible:ansible /ansible
USER ansible:ansible


WORKDIR /ansible

COPY ./ansible/requirements.txt /ansible/requirements.txt
COPY ./ansible/requirements.yaml /ansible/requirements.yaml

RUN python3 --version
RUN python3 -m venv /ansible/virtualenv
RUN /ansible/virtualenv/bin/python3 -m pip install --upgrade pip
RUN /ansible/virtualenv/bin/pip3 install -r /ansible/requirements.txt
RUN /ansible/virtualenv/bin/ansible-galaxy collection install -r requirements.yaml
# RUN /ansible/virtualenv/bin/pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt


FROM registry.access.redhat.com/ubi8/ubi-minimal

# # update the image
COPY --from=build /opt/az/packages-microsoft-prod.rpm /opt/az/packages-microsoft-prod.rpm

RUN rpm -i /opt/az/packages-microsoft-prod.rpm \
    && microdnf --enablerepo=ubi-8-baseos-rpms --enablerepo=packages-microsoft-com-prod -y install \
    openssl unzip python3.12 \
    shadow-utils \
    make \
    azure-cli \
    && microdnf clean all

RUN groupadd ansible --g 1000 && useradd -s /bin/bash -g ansible -u 1000 ansible -d /ansible
RUN mkdir -p ./virtualenv && chown -R ansible:ansible ./virtualenv

# # copy executables from build image
COPY --from=build /opt /opt

COPY --chown=ansible:ansible . /ansible
COPY --chown=ansible:ansible --from=build /ansible/virtualenv /ansible/virtualenv

USER ansible:ansible

# # set pathing
ENV PATH=/opt/bin:./virtualenv/bin:$PATH
ENV PYTHONPATH=./virtualenv/lib/python3.8/site-packages/
ENV ANSIBLE_PYTHON_INTERPRETER=./virtualenv/bin/python
# # set kubeconfig and ansible options
ENV KUBECONFIG=/ansible/.kube/config
ENV ANSIBLE_FORCE_COLOR=1

WORKDIR /ansible
