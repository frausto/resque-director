## 2.2.2 (2011-09-09)

* Bugfix: ignore wait_time when scaling to be within limits

## 2.2.1 (2011-09-07)

* Bugfix: make compatible with ruby 1.9

## 2.2.0 (2011-09-07)

* Added scaling workers working on multiple queues

## 2.1.1 (2011-09-02)

* Dont update last scaled time if start/stop block returns false

## 2.1.0 (2011-09-01)

* Change default log level to debug
* Make gem compatible with resque ~> 1.10
* add `no_enqueue_scale` option
* scale within requirements before perform

## 2.0.0 (2011-08-24)

* Must extend the plugin instead of include
* Modify resque's push/pop functionality to track time
* Start/stop override lambdas accept queue-name as an argument

## 1.1.0 (2011-08-23)

* Added logging options
* Bugfix: don't raise error when killing worker process

## 1.0.1 (2011-08-20)

* Bugfix: Dont append timestamp argument to resque job for non directed jobs

## 1.0.0 (2011-08-20)

* 1.0 release.
