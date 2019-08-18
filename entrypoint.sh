# Reference: https://medium.com/@hex337/running-a-phoenix-1-3-project-with-docker-compose-d82ab55e43cf

# FIXME: find out why psql wait script is not working

# Wait for Postgres to become available
# until psql -h db -U "postgres" -c '\q' 2>/dev/null; do
#   >&2 echo "Postgres is unavailable - sleeping"
#   sleep 1
# done

./prod/rel/radiator/bin/radiator eval "Radiator.Release.create"
./prod/rel/radiator/bin/radiator eval "Radiator.Release.migrate"


# Create a minio bucket called "radiator" at our s3 mimic
./mc config host add radiator http://minio:9000 IEKAZMUY3KX32CRJPE9R tXNYsfJyb8ctDgZSaIOYpndQwxOv8T+E+U0Rq3mN
./mc mb radiator/radiator
./mc mb radiator/radiator-test
./mc policy set public radiator/radiator
./mc policy set public radiator/radiator-test

# Start the Phoenix server
./prod/rel/radiator/bin/radiator start
