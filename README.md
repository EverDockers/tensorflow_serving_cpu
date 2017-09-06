# tensorflow serving (cpu)

official introduce: <https://www.tensorflow.org/serving/>

![regular](https://www.tensorflow.org/serving/images/tf_diagram.svg)

## Component

* Bazel 0.5.4
* grpc
* Python 3.5
* python 2.7
* Tensorflow Serving

## Usage

The TS and client web app are hosting on the same container

```bash
docker run -it -v <client>:/client \
 -p 9000:9000 -p 8080:8080 \
 --name <container_name> \ 
 baikangwang/tensorflow_serving_cpu /bin/bash 
```

The TS and client app (console, desktop) are hosting separately

```bash
# Tensorflow serving
docker run -it -v serving:/serving \
 -p 9000:9000 \
 --name <ts_container_name> \ 
 baikangwang/tensorflow_serving_cpu /bin/bash
 
# client app
docker run -it -v serving:/serving \
 --name <c_container_name> \ 
 baikangwang/tensorflow_serving_cpu /bin/bash
```

> `<client>`: it's placeholder presenting the client code directory which must contains BUILD file  
> `<[x_]container_name>`: it's placeholder presenting the container name  
> `9000:9000`: the serving service port, the server part is configurable with the evn variable `$SERVING_PORT`    
> `8080:8080`: the client app port which is optional for console, desktop programs, the server part is configurable with the evn variable `$CLIENT_PORT`  

## Tensorflow serving tasks

### Build serving(optional)

the serving has been built within the docker image. However, it could be rebuilt anytime,

```bash
cd /serving
bazel -c opt //tensorflow_serving/...
```

### Test serving

Check if the build works fine

```bash
cd /serving
bazel test -c opt tensorflow_serving/...
```

### Build client code

#### Rerequisites

1. BUILD file

    the BUILD is configuration file for building the client code by Bazel, which is required and should be put at
    the root directory of the client code. Here is a template,
    
    ```BUILD
    # mnist bazel build file
    
    package(
        default_visibility = ["//tensorflow_serving:internal"],
        features = ["no_layering_check"],
    )
    
    load("//tensorflow_serving:serving.bzl", "serving_proto_library")
    
    py_binary(
        name = "mnist_predict",
        srcs = [
            "mnist_predict.py",
        ],
        srcs_version = "PY2AND3",
        deps = [
            "//tensorflow_serving/example:mnist_input_data",
            "//tensorflow_serving/apis:predict_proto_py_pb2",
            "//tensorflow_serving/apis:prediction_service_proto_py_pb2",
            "@org_tensorflow//tensorflow:tensorflow_py",
        ],
    )
    ```
    Keep the most as they are, the node `py_binary` mainly needs to be customized,
    
    * `name` names the client code as a binary or package.
    * `srcs` outlines all codes going to be built.
    * `deps` outlines the all libraries expected to be `import` from the built tensorflow serving.
    the library path consists with two parts which are combined with the semicolon`:`; 
    the first part, `//tensorflow_serving/api` is the "namespace" which describes as the directory hierarchy;
    and the later part, `predict_proto_py_pb2` is the library name.
    
1. Create symbol link

    The client code should be running with the tensorflow serving library like WCF, so the build process should
    work with the pre-built TS libraries. There are two locations for building client codes, `/serving/tf_models/` and 
    `/serving/tensorflow_serving/`, link to earlier one if the `deps` only contains following libraries,
        
        //tensorflow_serving/apis:predict_proto_py_pb2,
        //tensorflow_serving/apis:prediction_service_proto_py_pb2,
        @org_tensorflow//tensorflow:tensorflow_py
    
    otherwise should link to the later one, because the modifiers of above three libs are `public`, which defined
    in the node,
    
        package(
            default_visibility = ["//tensorflow_serving:public"],
        )
    
    >`/serving/tf_models`:
        
        cd /serving/
        ln -s /client tf_models
        
    > `/serving/tensorflow_serving`:
    
        cd /serving/
        ln -s /client tensorflow_serving
         
#### Build

```bash
cd /serving

# <binary_name> is planceholder presenting the value of py_binary.name 
# defined in BUILD file

# link to tensorflow_serving
bazel build -c opt //tensorflow_serving/client:<binary_name>

# link to tf_models
bazel build -c opt //tf_models/client:<binary_name>
```

#### Start serving server

##### The TS and client web app are hosting on the same container

```bash
cd serving
# host serving
bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server \
--port=9000 --model_name=<model_name> \
--model_base_path=<trained_model_path> && \
# web client app
bazel-bin/tensorflow_serving/<client>/<binary_name> \
--$arguments=... \
--server=localhost:9000 \
--port=8080
```

##### The TS and client app (console, desktop) are hosting separately

TS container

```bash
cd serving
# host serving
bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server \
--port=9000 --model_name=<model_name> \
--model_base_path=<trained_model_path>
```

Client container

```bash
cd serving
bazel-bin/tensorflow_serving/<client>/<binary_name> \
--$arguments=... \
--server=localhost:9000 \
```

##### Example

The TS and client app (console, desktop) are hosting separately

TS container

```bash
cd /serving && \
bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server \
 --port=9000 --model_name=mnist \
 --model_base_path=/client/models/
```

Client container

```bash
cd /serving && \
bazel-bin/tensorflow_serving/MNIST/mnist_predict \
 --num_tests=1000 --server=<TS container>:9000 \
 --data_dir=/client/input_data
```


