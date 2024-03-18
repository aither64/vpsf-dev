# aither's development files for vpsAdminOS/vpsAdmin
These configs and scripts are used to build development virtual machines,
including vpsAdmin cluster.

## vpsAdminOS

```bash
./vpsadminos-shell

# build, update and run nodes
build-node.sh os1 os2 ...
update-node.sh os1 os2 ...
run-node.sh os1 os2 ...

# build, deploy and commit gems
make -j4 build-commit-gems

# build, deploy and amend gems
make -j4 build-amend-gems
```

## vpsAdmin for tree-wide actions

```bash
./vpsadmin-shell

# build and deploy nodectl gems
rake vpsadmin:gems
```

## vpsAdmin API
It is necessary to create `api/config/database.yml`, e.g.:

```yaml
development:
  adapter:  mysql2
  encoding: utf8
  host: 172.16.106.50
  username: vpsadmin
  password: yourpassword
  database: vpsadmin
  pool: 15
```

You should also copy vpsAdmin config into `api/config`, it can be found in
`vpsfree-cz-configuration`.

Interaction with the API:

```bash
./vpsadmin-api-shell

# run development server
api-run-in-shell.rb

# run REPL with vpsAdmin modules
api-repl-in-shell.rb

# run custom ruby script with vpsAdmin modules
api-ruby-in-shell.rb

# run scheduler
api-sheculer-in-shell.rb
```