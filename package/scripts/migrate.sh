#!/usr/bin/env bash
#
# run any necessary migrations
#

if [ -z "$DBHOST" ]; then
   echo "ERROR: DBHOST is not defined"
   exit 1
fi

if [ -z "$DBPORT" ]; then
   echo "ERROR: DBPORT is not defined"
   exit 1
fi

if [ -z "$DBUSER" ]; then
   echo "ERROR: DBUSER is not defined"
   exit 1
fi

if [ -z "$DBPASSWD" ]; then
   echo "ERROR: DBPASSWD is not defined"
   exit 1
fi

if [ -z "$DBNAME" ]; then
   echo "ERROR: DBNAME is not defined"
   exit 1
fi

export SECRET_KEY_BASE=x
bundle exec rails db:migrate

# return the status
exit $?

#
# end of file
#
