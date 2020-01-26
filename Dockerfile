FROM alpine:3.3

RUN apk add --no-cache php-xml php-sqlite3 libc-dev perl-dev gcc supervisor nginx bash curl perl rrdtool make perl-rrd git php-fpm ttf-dejavu tzdata && rm -rf /var/cache/apk/*

WORKDIR /root/

RUN curl --location http://search.cpan.org/CPAN/authors/id/R/RC/RCLAMP/File-Find-Rule-0.34.tar.gz | tar -xzf - \
    && cd File-Find-Rule-0.34/ \
    && perl Makefile.PL ; make ; make install

RUN curl --location http://search.cpan.org/CPAN/authors/id/E/EL/ELISA/Net-sFlow-0.11.tar.gz | tar -xzf - \
    && cd Net-sFlow-0.11/ \
    && perl Makefile.PL ; make ; make install

RUN curl --location http://search.cpan.org/CPAN/authors/id/R/RC/RCLAMP/Text-Glob-0.09.tar.gz | tar -xzf - \
    && cd Text-Glob-0.09/ \
    && perl Makefile.PL ; make ; make install

RUN curl --location  http://search.cpan.org/CPAN/authors/id/R/RC/RCLAMP/Number-Compare-0.03.tar.gz | tar -xzf - \
    && cd Number-Compare-0.03/ \
    && perl Makefile.PL ; make ; make install

RUN curl --location  https://cpan.metacpan.org/authors/id/M/ML/MLEHMANN/Types-Serialiser-1.0.tar.gz | tar -xzf - \
    && cd Types-Serialiser-1.0/ \
    && PERL_CANARY_STABILITY_NOPROMPT=1 perl Makefile.PL ; make ; make install

RUN curl --location  https://cpan.metacpan.org/authors/id/M/ML/MLEHMANN/common-sense-3.74.tar.gz | tar -xzf - \
    && cd common-sense-3.74/ \
    && PERL_CANARY_STABILITY_NOPROMPT=1 perl Makefile.PL ; make ; make install

RUN curl --location  https://cpan.metacpan.org/authors/id/G/GR/GRUBER/Net-Patricia-1.22.tar.gz | tar -xzf - \
    && cd Net-Patricia-1.22/ \
    && PERL_CANARY_STABILITY_NOPROMPT=1 perl Makefile.PL ; make ; make install

RUN curl --location  https://cpan.metacpan.org/authors/id/U/UM/UMEMOTO/Socket6-0.29.tar.gz | tar -xzf - \
    && cd Socket6-0.29/ \
    && PERL_CANARY_STABILITY_NOPROMPT=1 perl Makefile.PL ; make ; make install


RUN curl --location  https://cpan.metacpan.org/authors/id/M/ML/MLEHMANN/Canary-Stability-2013.tar.gz | tar -xzf - \
    && cd Canary-Stability-2013/ \
    && PERL_CANARY_STABILITY_NOPROMPT=1 perl Makefile.PL ; make ; make install


RUN curl --location  https://cpan.metacpan.org/authors/id/M/ML/MLEHMANN/JSON-XS-4.02.tar.gz | tar -xzf - \
    && cd JSON-XS-4.02/ \
    && PERL_CANARY_STABILITY_NOPROMPT=1 perl Makefile.PL ; make ; make install

RUN curl --location  https://cpan.metacpan.org/authors/id/T/TI/TIMB/DBI-1.642.tar.gz | tar -xzf - \
    && cd DBI-1.642/ \
    && PERL_CANARY_STABILITY_NOPROMPT=1 perl Makefile.PL ; make ; make install

RUN curl --location  https://cpan.metacpan.org/authors/id/I/IS/ISHIGAKI/DBD-SQLite-1.64.tar.gz | tar -xzf - \
    && cd DBD-SQLite-1.64/ \
    && PERL_CANARY_STABILITY_NOPROMPT=1 perl Makefile.PL ; make ; make install

RUN curl --location  https://cpan.metacpan.org/authors/id/N/NI/NICOLAW/RRD-Simple-1.44.tar.gz | tar -xzf - \
    && cd RRD-Simple-1.44/ \
    && PERL_CANARY_STABILITY_NOPROMPT=1 perl Makefile.PL ; make ; make install


RUN rm -Rf Net-sFlow-0.11 File-Find-Rule-0.34 Text-Glob-0.09 Number-Compare-0.03 JSON-XS-4.02 Canary-Stability-2013 Socket6-0.29 Net-Patricia-1.22 common-sense-3.74 Types-Serialiser-1.0 DBI-1.642 DBD-SQLite-1.64 RRD-Simple-1.44

ADD https://github.com/JackSlateur/perl-ip2as/archive/master.zip ip2as.zip
RUN unzip ip2as.zip \
    && rm ip2as.zip \
    && cp perl-ip2as-master/ip2as.pm /usr/lib/perl5/core_perl/ \
    && rm -Rf perl-ip2as-master

ADD https://github.com/manuelkasper/AS-Stats/archive/master.zip master.zip
RUN unzip master.zip \
    && mv AS-Stats-master AS-Stats \
    && rm master.zip

RUN rm -Rf /var/www/localhost \
    && rm -Rf AS-Stats/www

ADD https://github.com/nidebr/as-stats-gui/archive/master.zip gui.zip
RUN unzip gui.zip \
    && mv as-stats-gui-master/* /var/www \
    && rm -Rf as-stats-gui-master \
    && rm gui.zip

### NGINX + PHP5-FPM
RUN mkdir /run/nginx/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/sites-available/ && \
    mkdir -p /etc/nginx/sites-enabled/
ADD nginx/asstats.conf /etc/nginx/sites-available/asstats.conf
RUN ln -s /etc/nginx/sites-available/asstats.conf /etc/nginx/sites-enabled/asstats.conf

EXPOSE 80

VOLUME ["/data/as-stats"]

ADD files/cron.txt /root
RUN cat /root/cron.txt >> /etc/crontabs/root && rm /root/cron.txt

ADD files/stats-day.sh /usr/sbin/stats-day
RUN chmod +x /usr/sbin/stats-day

ADD files/startup.sh /root
ADD files/supervisord.conf /etc/supervisord.conf
RUN chmod +x /root/startup.sh

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c",  "/etc/supervisord.conf"]
#ENTRYPOINT ["/bin/sh"]
