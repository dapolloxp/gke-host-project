FROM quay.io/podman/stable

USER root

# Create Google Cloud SDK repository file using echo commands
RUN echo "[google-cloud-cli]" > /etc/yum.repos.d/google-cloud-sdk.repo && \
    echo "name=Google Cloud CLI" >> /etc/yum.repos.d/google-cloud-sdk.repo && \
    echo "baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64" >> /etc/yum.repos.d/google-cloud-sdk.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/google-cloud-sdk.repo && \
    echo "gpgcheck=1" >> /etc/yum.repos.d/google-cloud-sdk.repo && \
    echo "repo_gpgcheck=0" >> /etc/yum.repos.d/google-cloud-sdk.repo && \
    echo "gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" >> /etc/yum.repos.d/google-cloud-sdk.repo

# Install dependencies and gcloud CLI
RUN dnf install -y libxcrypt-compat.x86_64 google-cloud-cli && \
    dnf clean all && \
    rm -f /etc/yum.repos.d/google-cloud-sdk.repo

CMD ["sleep", "infinity"]