cache_gen_server
=====

An OTP application, creating ets database. 

HTTP output:

insert Item into database
$ curl -H "Content-Type: application/json" -X POST
    -d "{\"action\":\"insert\",\"key\":\"Ivanov\",\"value\":55,\"t_life\":20000}" 
    http://localhost:8080/api/cache_server
{"status":"ok"}
    
get Item by Key
$ curl -H "Content-Type: application/json" -X POST
    -d "{\"action\":\"lookup\",\"key\":\"Ivanov\"}" 
    http://localhost:8080/api/cache_server
{"value":{"ok":55}}

get Items between born characters "Date_from" and "Date_to".
$ curl -H "Content-Type: application/json" -X POST
    -d "{\"action\":\"lookup_by_date\",\"date_from\":\"2021/3/10 00:00:00\",\"date_to\":\"2021/3/10 07:00:00\"}" 
    http://localhost:8080/api/cache_server
{"value":[{"ok":["Ivanov",55]}]}

delete Item from database by Key
$ curl -H "Content-Type: application/json" -X POST
    -d "{\"action\":\"delete_item\",\"key\":\"Ivanov\"}" 
    http://localhost:8080/api/cache_server
{"status":"ok"}

delete Item from database by determined time
$ curl -H "Content-Type: application/json" -X POST
    -d "{\"action\":\"delete_per_time\"}" 
    http://localhost:8080/api/cache_server
{"status":"ok"}

start automatic deleting Item from database by drop interval
$ curl -H "Content-Type: application/json" -X POST
    -d "{\"action\":\"delete_periodic\",\"key\":\"drop_interval\",\"value\":10}" 
    http://localhost:8080/api/cache_server
{"delete_periodic":10}

stop() -> stop application command.
$ curl -H "Content-Type: application/json" -X POST
    -d "{\"action\":\"stop\"}" http://localhost:8080/api/cache_server
{"status":"ok"}

Build
-----

    $ rebar3 compile
