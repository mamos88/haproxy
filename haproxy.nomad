job "haproxy" {
   region = "global"
   datacenters = ["dc-aws-1"] 
   type = "system"

    group "haproxy" {
        count = 1

        network {
            port "http" {
                static = 8080
            }

            port "haproxy_ui" {
                static = 1936
            }
        }
    service {
        name = "haproxy"

        check {
            name = "alive"
            type = "tcp"
            port = "http"
            interval = "10s"
            timeout = "2s"
        }
    }
    task "haproxy" {
        driver = "docker"

        config {
            image = "haproxy:2.7"
            network_mode = "host"

            volumes = [
                "local/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg",
            ]
        }

        template {
            data = <<EOF

defaults
    mode http

frontend stats
    bind *:1936
    stats uri /
    stats show-legends
    no log

frontend http_front
    bind *:8080

    # ACL for chris.michaelamos.ninja
    acl ACL_chris.michaelamos.ninja hdr(host) -i chris.michaelamos.ninja
    use_backend be_chris if ACL_chris.michaelamos.ninja

    # ACL for myapp.michaelamos.ninja
    acl ACL_myapp.michaelamos.ninja hdr(host) -i myapp.michaelamos.ninja
    use_backend be_myapp if ACL_myapp.michaelamos.ninja

    # Prometheus
    acl ACL_prometheus.michaelamos.ninja hdr(host) -i prometheus.michaelamos.ninja
    use_backend be_prmetheus if ACL_prometheus.michaelamos.ninja

    # Grafana
    acl ACL_grafana.michaelamos.ninja hdr(host) -i grafana.michaelamos.ninja
    use_backend be_grafana if ACL_grafana.michaelamos.ninja

    acl ACL_http-echo.michaelamos.ninja hdr(host) -i http-echo.michaelamos.ninja
    use_backend be_http-echo if ACL_http-echo.michaelamos.ninja

    default_backend status_page

backend be_chris
    balance roundrobin
    server-template chrisapp 10 _chris-app._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend be_http-echo
    balance roundrobin
    server-template http-echo 10 _http-echo._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend be_myapp
    balance roundrobin
    server-template myapp 10 _myapp._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend status_page
    balance roundrobin
    server-template status-page 10 _status-page._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend be_prmetheus
    balance roundrobin
    server-template prometheus 10 _prometheus._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend be_grafana
    server-template grafana 10 _grafana._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

resolvers consul
    nameserver consul 127.0.0.1:8600
    accepted_payload_size 8192
    hold valid 5s

EOF
    destination = "local/haproxy.cfg"
        }
    resources {
        cpu = 200
        memory = 128
    }
    }
    }

}