# Elastic Beats
This project is created and maintained by the Elastic Beats team. All credit for the service goes to their talented team.

_Beats is the platform for single-purpose data shippers. They install as lightweight agents and send data from hundreds or thousands of machines to Logstash or Elasticsearch._

## Heartbeat
Heartbeat monitors services for their availability with active probing. Given a list of URLs, Heartbeat asks the simple question: Are you alive? Heartbeat ships this information and response time to the rest of the Elastic Stack for further analysis.

We use Heartbeat to ensure that the various CAPES services are all up and running.

## Metricbeat
Metricbeat collects metrics from your systems and services. From CPU to memory, Redis to NGINX, and much more, Metricbeat is a lightweight way to send system and service statistics.

We use Metricbeat to ensure that CAPES is given the appropriate resources for the use case.

## Documentation / Installation
See the [Build, Operate, Maintain page](build_operate_maintain.md) for detailed instructions.  

## Project Link
https://www.elastic.co/products/beats
