#!/bin/bash
set -e

instance_create() {
    set -e
    
    NAME=$1

    if [ -z ${NAME} ]; then
        echo "Name not set"
        exit 1
    fi

    scw instance server create name=$NAME type=DEV1-S cloud-init=@./cloud-init.yaml ip=dynamic image=ubuntu_focal tags.0=scw-flake
    echo "It takes a while for nix-infect to finish, to check progress, ssh in and tail /tmp/infect.log"
}

instance_id() {
    set -e

    NAME=$1

    if [ -z ${NAME} ]; then
        IDS="$(scw instance server list tags.0=scw-flake | tail -n+2 | awk '{print $1}')"
    else
        IDS="$(ids_from_name $NAME)"
    fi

    echo $(exactly_one_match $IDS)
}

instance_list() {
    set -e
    
    scw instance server list tags.0=scw-flake
}

instance_ip() {
    set -e
    
    NAME=$1

    ID=$(instance_id $NAME)

    scw instance server get $ID | grep Address | awk '{print $2}'
}

instance_ssh() {
    set -e

    NAME=$1

    IP=$(instance_ip $NAME)
    echo "SSHing into $NAME($IP)"

    ssh -t root@$IP
}

instance_terminate() {
    set -e
    
    NAME=$1

    if [ -z ${NAME} ]; then
        echo "Name required"
        exit 1
    fi

    ID=$(exactly_one_match $(ids_from_name $NAME))

    echo "Terminating $ID"
    scw instance server terminate $ID
}

ids_from_name() {
    set -e
    
    NAME=$1

    scw instance server list name=$NAME tags.0=scw-flake | tail -n+2 | awk '{print $1}'
}

exactly_one_match() {
    set -e
    
    if [ -z $1 ]; then
        echo "No match found"
        exit 1
    elif [[ $1 =~ $'\n' ]]; then
        echo "More than one matches"
        exit 1
    else
        echo $1
    fi
}

COMMAND=$1

case $COMMAND in
create)
    instance_create $2
;;
id)
    instance_id $2
;;
list)
    instance_list
;;
terminate)
    instance_terminate $2
;;
ssh)
    instance_ssh $2
;;
ip)
    instance_ip $2
;;
*)
    echo "Unrecognised command : $COMMAND"
    exit 1
esac    
