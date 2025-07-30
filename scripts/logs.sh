#!/bin/bash
if [ -z "$1" ]; then
    echo "📋 Logs de tous les services:"
    docker-compose -f docker-compose-new.yml logs -f
else
    echo "📋 Logs du service $1:"
    docker-compose -f docker-compose-new.yml logs -f $1
fi
