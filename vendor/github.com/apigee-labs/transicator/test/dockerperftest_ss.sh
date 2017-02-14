#!/bin/sh

# Copyright 2016 The Transicator Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ ! $TEST_PG_PW ]
then
TEST_PG_PW=password
fi

netName=transicator-tests-$$
dbName=transicator-test-pg-$$
testName=transicator-test-$$
ssName=snapshot-test-$$
csName=changeserver-test-$$
slotName=changeserver_test_slot
postgrestName=postgrest-test-$$


# Build postgresql image
docker build --tag ${dbName} ../pgoutput

# Build Snapshot server
docker build --tag ${ssName} -f ../Dockerfile.snapshotserver .

# Build Change server
docker build --tag ${csName} -f ../Dockerfile.changeserver .

POSTGRES_URL=postgres://postgres:${TEST_PG_PW}@${dbName}/postgres

# Launch Postgress DB
docker run -d \
  --name ${dbName} \
  -e POSTGRES_PASSWORD=${TEST_PG_PW} \
  -p 9442:5432 \
  ${dbName}
# Build Snapshot data generator
TEST_PG_URL=postgres://postgres:${TEST_PG_PW}@${dbName}/postgres?sslmode=disable
docker build -t ${testName} -f ./Dockerfile.dbdatagen .

# Launch Postgres Data generator (DB url, rows in table, scopes in table)
docker run --link ${dbName}:postgres ${testName} $TEST_PG_URL 100 10

# Launch Snapshot server
docker run -d \
  --name ${csName} \
  --link ${dbName}:postgres \
  -p 9443:9443 \
  ${csName} \
  -p 9443 \
  -s ${slotName} -u $POSTGRES_URL

# Launch Snapshot server
docker run -d \
  --name ${ssName} \
  --link ${dbName}:postgres \
  -p 9444:9444 \
  ${ssName} \
  -p 9444 \
  -u $POSTGRES_URL

