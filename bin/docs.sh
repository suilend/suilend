#!/bin/bash

# Navigate to the suilend contracts directory
cd contracts/suilend

# Build the Sui Move documentation
sui move build --doc

# Remove the existing suilend folder in the docs directory if it exists
if [ -d "../../docs/suilend" ]; then
    rm -rf ../../docs/suilend
fi

# Copy the generated documentation to the docs directory
cp -r build/suilend/docs/suilend ../../docs/

cd ../..