
$url = "http://cireson.blob.core.windows.net/demo/daemon.json"
$output = "c:\programdata\docker\config\daemon.json"

Invoke-WebRequest -Uri $url -OutFile $output


