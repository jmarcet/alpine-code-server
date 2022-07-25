FROM python:3.10-alpine

ARG TARGETARCH=amd64
ARG VERSION=4.5.1

ENV EUID=1000 EGID=1000 HOME=/home/vscode

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /src/go
ENV PATH /home/vscode/.local/bin:/src/go/bin:$PATH
ENV PYTHONUNBUFFERED=1

RUN sed -e 's:alpine\/[.0-9v]\+\/:alpine/edge/:g' -i /etc/apk/repositories
RUN apk update && apk upgrade --available --prune --purge
RUN apk --no-cache add build-base go libffi-dev linux-headers make musl-dev sqlite-libs \
   bash curl docker-compose docker-compose-zsh-completion docker-zsh-completion \
   git gnupg nodejs openssh-client s6 tmux vim wrk zsh

RUN \
   cd /tmp && \
   wget https://github.com/cdr/code-server/releases/download/v$VERSION/code-server-$VERSION-linux-$TARGETARCH.tar.gz && \
   tar xzf code-server-$VERSION-linux-$TARGETARCH.tar.gz && \
   rm code-server-$VERSION-linux-$TARGETARCH/code-server && \
   rm code-server-$VERSION-linux-$TARGETARCH/lib/node && \
   rm code-server-$VERSION-linux-$TARGETARCH/node && \
   rm code-server-$VERSION-linux-$TARGETARCH.tar.gz && \
   mv code-server-$VERSION-linux-$TARGETARCH /usr/lib/code-server && \
   sed -i 's/"$ROOT\/lib\/node"/node/g'  /usr/lib/code-server/bin/code-server

COPY code-server /usr/bin/
RUN chmod +x /usr/bin/code-server

RUN addgroup -g ${EGID} vscode && adduser -s /bin/zsh -G vscode -u ${EUID} -D vscode

WORKDIR /home/vscode
USER vscode
RUN pip install --upgrade pip && pip install black flake8 ipython

CMD code-server --bind-addr 0.0.0.0:8080 --auth none --disable-telemetry --disable-update-check \
    --proxy-domain ${PROXY_DOMAIN} --config /config/.config/code-server/config.yaml \
    --user-data-dir /config/data --extensions-dir /config/extensions
