package main

import (
	"fmt"
	"net/url"
	"os"
	"syscall"
)

func required(name string) string {
	value := os.Getenv(name)
	if value == "" {
		fmt.Fprintf(os.Stderr, "missing required environment variable: %s\n", name)
		os.Exit(1)
	}
	return value
}

func main() {
	dbHost := required("DB_HOST")
	dbName := required("DB_NAME")
	dbUsername := required("DB_USERNAME")
	dbPassword := required("DB_PASSWORD")

	databaseURL := &url.URL{
		Scheme: "postgres",
		User:   url.UserPassword(dbUsername, dbPassword),
		Host:   dbHost + ":5432",
		Path:   dbName,
	}

	dbSSLMode := os.Getenv("DB_SSLMODE")
	if dbSSLMode == "" {
			dbSSLMode = "require"
	}

	query := databaseURL.Query()
	query.Set("sslmode", dbSSLMode)
	databaseURL.RawQuery = query.Encode()

	if err := os.Setenv("DATABASE_URL", databaseURL.String()); err != nil {
		fmt.Fprintf(os.Stderr, "failed to set DATABASE_URL: %v\n", err)
		os.Exit(1)
	}

	args := append([]string{"/app/fider"}, os.Args[1:]...)

	if err := syscall.Exec("/app/fider", args, os.Environ()); err != nil {
			fmt.Fprintf(os.Stderr, "failed to start Fider: %v\n", err)
			os.Exit(1)
	}
}
