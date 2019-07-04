#### 一、简介

​    nginx是一个单线程模型的高性能web服务器, 相比apache的多线程模型(即处理一个请求就要创建一个线程), nginx在linux里使用epoll事件模型可以获得很好的并发性能, 而且占用资源少, 轻量级, 不用它都不好意思说是做web的.

#### 二、Nginx应用场景

##### 1. 静态服务器

静态资源服务器是一个web服务器的本职工作, nginx做得非常好, 其配置如下:

```json
server {
    listen 80; #设置监听端口
    server_name localhost; #设置主机名
    client_max_body_size 1024M; #设置请求body最大为1GB

    location / {
            root /var/www/html;
            index index.html;
    }
}
```

##### 2. 动静分离

现在后台架构主流都是这样了, 静态资源如html文件等直接nginx处理, 动态请求的通过tomcat、wsgi等动态服务处理, 其tomcat的配置如下:

```json
upstream test{
    server localhost:8080;
    server localhost:8081;
    }
server{
    listen 80;
    server_name localhost;

    # 设置根目录index
    location / {
        root /var/www/html;  
        index index.html;
    }
    # 正则匹配所有的静态资源
    location ~ .(gif|jpg|jpeg|png|bmp|swf|css|js)${
        root /var/www/html
    }
    # 正则匹配所有jsp和do文件并传给后段tomcat服务器处理
    location ~ .(jsp|do)$ {
        proxy_pass http://test; # 反向代理
    }
}
```

##### 3. 反向代理

反向代理是nginx最拿手的应用场景了, 可以有效将后端服务器与用户隔离开, 只需要暴露nginx的80端口端口, 同时也可以做负载均衡. 其配置如下:

```json
server { 
    listen 80;
    server_name localhost; #多个主机名可以用空格分开

    location / { # ‘/’是代理所有的意思, 可以用正则来匹配
        proxy_pass http://127.0.0.1:5000; # flask服务
        proxy_set_header Host $host:$server_port;
    }
}
```

##### 4. 负载均衡

load balance是常见的业务需求, 当应对大量用户请求的时候, 负载均衡可以做到分机横向扩展, 还有keepalive机制, 是企业高可用的常见手法, 当然这是应用层的负载均衡, 还有F5硬件负载均衡(以前luxottica就用这个, 财大气粗), F5可以做到传输层和链路层级别的负载均衡, 速度更快性能更好但是更贵.

负载均衡算法主要有:

- Round-Robin(轮训算法, nginx默认就是这个)
  - ip_hash (对于client需要和后台服务保持session, 同一个ip转发到同一个服务器)
  - weight (权重, 控制后端服务器从nginx接受到请求的权重, 适用与后端服务器性能不均匀的情况, 性能好的权重大一点)

nginx负载均衡配置如下:

```json
    upstream test {
        # 默认是Round-Robin算法, 就是轮训
        ip_hash; # 指定使用ip_hash算法,保持session
        server localhost:8080; (weight=6) # 可以加权重
        server localhost:8081; (weight=4)
    }
    server {
        listen       81;                                                         
        server_name  localhost;                                               
        client_max_body_size 1024M;

        location / {
            proxy_pass http://test;
            proxy_set_header Host $host:$server_port;
        }
    }
```

#### 三、Reload

nginx -s reload (支持热启动使配置生效)
