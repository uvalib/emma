#! /usr/bin/env bash
#
# Run any necessary migrations.
#
# DEPLOYMENT, DBNAME, DBUSER, and DBPASSWD must be defined in
# terraform-infrastructure/emma.lib.virginia.edu/ecs-tasks/*/environment.vars
#
# DBHOST and/or DBPORT *may* be defined there; if not, DATABASE must be defined
# there so that EMMA config/env_vars.rb can derive the missing value(s).

echo
echo BEGIN migrate.sh
echo
env
echo
echo END migrate.sh
echo

export SECRET_KEY_BASE=x
bundle exec rails db:prepare

#
# end of file
#
