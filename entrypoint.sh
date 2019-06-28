# Reference: https://medium.com/@hex337/running-a-phoenix-1-3-project-with-docker-compose-d82ab55e43cf

# Wait for Postgres to become available
# until psql -h db -U "postgres" -c '\q' 2>/dev/null; do
#   >&2 echo "Postgres is unavailable - sleeping"
#   sleep 1
# done

# Ecto will migrate the db to the latest changes
mix ecto.create
mix ecto.migrate

# Create a minio bucket called "radiator" at our s3 mimic
./mc config host add radiator http://minio:9000 IEKAZMUY3KX32CRJPE9R tXNYsfJyb8ctDgZSaIOYpndQwxOv8T+E+U0Rq3mN
./mc mb radiator/radiator
./mc mb radiator/radiator-test
./mc policy public radiator/radiator
./mc policy public radiator/radiator-test

# Start the Phoenix server
./prod/rel/radiator/bin/radiator start
