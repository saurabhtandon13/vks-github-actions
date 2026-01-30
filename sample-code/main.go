package main

import (
	"fmt"
	"time"

	"github.com/fatih/color"
)

func main() {
	color.Cyan("Welcome to the Go demo!")

	messages := []string{
		"Initializing system...",
		"Fetching configuration...",
		"Starting background jobs...",
		"System ready!",
	}

	for i, msg := range messages {
		color.Green("[%d/%d] %s", i+1, len(messages), msg)
		time.Sleep(700 * time.Millisecond)
	}

	color.Yellow("\nAll systems operational!")
	fmt.Println("Enjoy your day 🚀")
}
