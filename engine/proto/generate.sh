#!/bin/bash
protoc -I=. --cpp_out=../src/protobuf shared.proto
protoc -I=. --cpp_out=../src/protobuf appearances.proto
