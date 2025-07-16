# Start from the official Podman stable image
FROM quay.io/podman/stable

# The image runs as root by default, which is needed for installation
USER root

# Install the gcloud CLI
RUN tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM && \
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
    # Install the SDK and then clean up to keep the image small
    dnf install -y google-cloud-cli && \
    dnf clean all && \
    rm -f /etc/yum.repos.d/google-cloud-sdk.repo
# Default command
CMD ["/bin/bash"]