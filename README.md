# APID

Apid is a container for publishing APIs that provides core services to its plugins including configuration, 
API publishing, data access, and a local pub/sub event system.

# Configuration

Configuration can be done via yaml file or environment variables. Keys are case-insensitive. 

#### YAML File

By default, apid will look for a file called apid_config.yaml in the current working directory. However, you may set 
an env var `apid_config` to point to a config file location.

#### Environment variables

Config will pick up env vars automatically. Use "apid_" as a prefix for settings. For example, for apid's "log_level" 
configuration setting, set env var "apid_log_level". 

### Defaults

```
api_port: 9000
api_expvar_path: nil  # not exposed
events_buffer_size: 5
log_level: debug    # valid values: Debug, Info, Warning, Error, Fatal, Panic
```
 
# Services

apid provides the following services:

* apid.API()
* apid.Config()
* apid.Data()
* apid.Events()
* apid.Log()
 
### Initialization of services and plugins

A driver process must initialize apid and its plugins like this:

```
apid.Initialize(factory.DefaultServicesFactory()) // when done, all services are available
apid.InitializePlugins() // when done, all plugins are running
api := apid.API() // access the API service
err := api.Listen() // start the listener
```

Once apid.Initialize() has been called, all services are accessible via the apid package functions as details above. 

# Plugins

The only requirement of an apid plugin is to register itself upon init(). However, generally plugins will access
the Log service and some kind of driver (via API or Events), so it's common practice to see something like this:
 
```
var log apid.LogService
 
func init() {
	apid.RegisterPlugin(initPlugin)
}

func initPlugin(services apid.Services) error {

  log = services.Log().ForModule("myPluginName") // note: could also access via `apid.Log().ForModule()`
  
  services.API().HandleFunc("/verifyAPIKey", handleRequest)
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
  // respond to request
}
```
