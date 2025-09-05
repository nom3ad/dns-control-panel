$TTL    604800
@       IN      SOA     ns1.example.com. admin.example.com. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

; Name servers
        IN      NS      ns1.example.com.
        IN      NS      ns2.example.com.

; Mail exchangers
        IN      MX  10  mail.example.com.

; A records
@       IN      A       192.0.2.10
www     IN      A       192.0.2.11
mail    IN      A       192.0.2.12
ns1     IN      A       192.0.2.10
ns2     IN      A       192.0.2.13

; CNAME records
ftp     IN      CNAME   www.example.com.

; TXT records
@       IN      TXT     "v=spf1 mx ~all"
