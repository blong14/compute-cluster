package main

import (
	"flag"
	"k8s.io/klog/v2"

	"cluster/cmd"
)

func main() {
	klog.InitFlags(nil)
	flag.Parse()
	cmd.Execute()
}
