# https://fedoramagazine.org/building-smaller-container-images/
FROM registry.fedoraproject.org/fedora-minimal:33

# https://jhrozek.wordpress.com/2015/03/31/authenticating-a-docker-container-against-hosts-unix-accounts/
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/using_containerized_identity_management_services/configuring-the-sssd-container-to-provide-identity-and-authentication-services-on-atomic-host
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/using_containerized_identity_management_services/deploying-sssd-containers-with-different-configurations
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/configuring_authentication_and_authorization_in_rhel/index
RUN microdnf install borgbackup rsync openssh-clients openssh-server \
        bash zsh findutils hostname \
        sssd-client krb5-workstation && \
    microdnf install authselect && \
    authselect select sssd --force && \
    microdnf remove authselect authselect-libs && \
    microdnf clean all

ENTRYPOINT ["/usr/sbin/sshd", "-De"]
