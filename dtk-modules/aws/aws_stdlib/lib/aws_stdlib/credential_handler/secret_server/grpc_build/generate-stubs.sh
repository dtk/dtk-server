#!/bin/bash
proto_path=$PWD
proto_file="$proto_path/secret_server.proto"
PATH=$PATH:/usr/local/share/ruby/gems/2.0/gems/grpc-tools-1.0.1/bin
output_dir=../grpc_helper/
mkdir -p $output_dir
grpc_plugin=`which grpc_tools_ruby_protoc_plugin` 
grpc_tools_ruby_protoc -I $proto_path --ruby_out=$output_dir --grpc_out=$output_dir --plugin=protoc-gen-grpc=$grpc_plugin $proto_file

