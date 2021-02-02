# https://fedoramagazine.org/building-smaller-container-images/
FROM registry.fedoraproject.org/fedora-minimal:33

# https://jhrozek.wordpress.com/2015/03/31/authenticating-a-docker-container-against-hosts-unix-accounts/
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/using_containerized_identity_management_services/configuring-the-sssd-container-to-provide-identity-and-authentication-services-on-atomic-host
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/using_containerized_identity_management_services/deploying-sssd-containers-with-different-configurations
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/configuring_authentication_and_authorization_in_rhel/index
RUN microdnf install borgbackup rsync openssh-clients openssh-server \
        bash zsh findutils hostname \
        sssd-client krb5-workstation nss-altfiles && \
    microdnf install authselect && \
    authselect select sssd --force && \
    microdnf remove authselect authselect-libs && \
    microdnf clean all && \
    sed -i 's/passwd:     sss files systemd/passwd: sss files altfiles systemd/g' /etc/nsswitch.conf && \
    sed -i 's/group:      sss files systemd/group: sss files altfiles systemd/g' /etc/nsswitch.conf && \
    sed -i 's/shadow:     files/shadow:     files altfiles/g' /etc/nsswitch.conf && \
    cp /etc/passwd /lib/passwd && \
    cp /etc/group /lib/group && \
    cp /etc/shadow /lib/shadow && \
    mkdir -p /var/lib/sss/pubconf/krb5.include.d && \
    mkdir -p /etc/krb5.conf.d/

ENTRYPOINT ["/usr/sbin/sshd", "-De"]
