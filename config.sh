#!/bin/sh
docker exec -it dockercomposephabricator_php_1 /srv/phabricator/bin/config "$@"