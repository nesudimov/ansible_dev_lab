FROM alpine:3.19

# Metadata params
ARG BUILD_DATE
ARG ANSIBLE_VERSION=9.1.0
ARG ANSIBLE_LINT_VERSION=6.22.1
ARG MITOGEN_VERSION=0.3.4
ARG VCS_REF

RUN apk --update --no-cache add \
        ca-certificates \
        git \
        openssh-client \
        openssl \
        py3-cryptography \
        py3-pip \
        py3-yaml \
        python3\
        rsync \
        sshpass

RUN apk --update --no-cache add --virtual \
        .build-deps \
        build-base \
        cargo \
        curl \
        libffi-dev \
        openssl-dev \
        python3-dev 

RUN pip3 install --no-cache-dir --upgrade pip --break-system-packages

RUN pip3 install --no-cache-dir --upgrade --break-system-packages --only-binary \
        cffi \
        ansible==${ANSIBLE_VERSION} \
        ansible-lint==${ANSIBLE_LINT_VERSION} \
        mitogen==${MITOGEN_VERSION} 

RUN apk del \
    .build-deps \
    && rm -rf /var/cache/apk/* \
    && find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
    && find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf

RUN mkdir -p /etc/ansible \
  && echo 'localhost' > /etc/ansible/hosts \
  && echo -e """\
\n\
Host *\n\
    StrictHostKeyChecking no\n\
    UserKnownHostsFile=/dev/null\n\
""" >> /etc/ssh/ssh_config

COPY --chmod=755 entrypoint /usr/local/bin/entrypoint

WORKDIR /ansible

ENTRYPOINT ["sh","/usr/local/bin/entrypoint"]

# default command: display Ansible version
CMD [ "ansible-playbook", "--version" ]