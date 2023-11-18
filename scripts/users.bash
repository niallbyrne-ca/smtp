#!/bin/bash

function _fn_users() {
  echo "CONTAINER > 'users' function has been called."
  echo -e "${USER_LIST}" > /run/secrets/users.txt
}
