#!/bin/bash

/usr/local/bin/lttng-relayd -d

get_ses=$(babeltrace -i lttng-live net://localhost)
while [ "$get_ses" == "" ]
do
    sleep 1
    get_ses=$(babeltrace -i lttng-live net://localhost)
done

babeltrace -i lttng-live  $session > $pipe_file &
echo "*****Started babeltrace-live  ******"
